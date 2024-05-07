%
% This function generates a DADA file containing a single-channel, 
% complex-valued test vector composed of a series of either
% delta functions or pure tones.
%
% The design of both temporal and spectral test vectors is described at
%
% https://confluence.skatelescope.org/display/SE/Polyphase+Filter+Bank+Inversion%3A+Requirements+Verification
%
function test_vector(varargin)

p = inputParser;

% the correlator beam former for which the test vector is designed
addOptional(p, 'cbf', 'low', @ischar);

% the dimension (temporal or spectral) tested
addOptional(p, 'domain', 'temporal', @ischar);

% number of test states
addOptional(p, 'Nstate', 0, @isnumeric);

% forward FFT length used during PFB inversion
addOptional(p, 'Nfft', 0, @isnumeric);

% samples by which forward FFTs overlap
addOptional(p, 'Tover', 0, @isnumeric);

% load header from file
addOptional(p, 'header', '../config/test_vector_dada.hdr', @ischar);

% write DADA to file
addOptional(p, 'output', '', @ischar);

% number of bits per sample in output data file
addOptional(p, 'nbit', 32, @isnumeric);

parse(p, varargin{:});

header_file = p.Results.header;
if ( header_file == "" )
  error ('Missing header = name of JSON-formatted DADA header');
end

domain = p.Results.domain;

output_file = p.Results.output;
if ( output_file == "" )
    output_file = "../products/test_vector_" + domain + ".dada";
end

Nstate = p.Results.Nstate;

if (Nstate == 0)
    if (domain == "temporal")
        Nstate = 2;
    else
        Nstate = 3;
    end
end

cbf = p.Results.cbf;

dada_header = 4096;

if ( cbf == "low" )
    Nchan = 256;   % channels output by PFB
    Ttap = 12;     % filter taps per channel
    Qnum = 32;     % numerator of oversampling ratio of 1st stage PFB
    Qden = 27;     % denominator of oversampling ratio of 1st stage PFB
    Rnum = 4;      % numerator of oversampling ratio of 2nd stage PFB
    Rden = 3;      % denominator of oversampling ratio of 2nd stage PFB
    Nfft = 1024;   % forward FFT length used during PFB inversion
    Tover= 128;    % samples by which forward FFTs overlap

    % number of input samples lost by PFB 
    Nlost = 0;
elseif ( cbf == "mid" )
    Nchan = 4096;  % channels output by PFB
    Ttap = 28;     % filter taps per channel
    Qnum = 4;      % numerator of oversampling ratio of 1st stage PFB
    Qden = 3;      % denominator of oversampling ratio of 1st stage PFB
    Rnum = 8;      % numerator of oversampling ratio of 2nd stage PFB
    Rden = 7;      % denominator of oversampling ratio of 2nd stage PFB
    Nfft = 2048;   % forward FFT length used during PFB inversion
    Tover= 252;    % samples by which forward FFTs overlap

    % number of input samples lost by PFB 
    Nlost = 0;
else
    error ('Unknown CBF %s', cbf);
end

% Number of fine channels that span critically-sampled part of coarse channel
Ncritical = Nchan * Qden / Qnum;

% Number of frequency bins kept from each FFT performed on each fine channel
Tkeep = Nfft * Rden / Rnum;

% Number of coarse-channel time samples for each backward FFT performed during PFB inversion
Tifft = Nchan * Tkeep;

% Stride between blocks of coarse-channel time samples for 
% each fine-channel time sample output by second-stage PFB
Tstep = Nchan * Rden / Rnum;

fprintf('Ncritical=%d Tkeep=%d Tifft=%d Tstep=%d \n',Ncritical,Tkeep,Tifft,Tstep);

% Number of input coarse-channel time samples 
% for each fine-channel time sample output by second-stage PFB
Tin = Nchan * Ttap;

% Stride between blocks of input coarse-channel time samples included in
% each FFT performed on fine-channel time samples output by second-stage PFB
Tskip = Tover * Tstep;

% Number of input coarse-channel time samples included in
% each FFT performed on fine-channel time samples output by second-stage PFB
Tfft = Nfft * Tstep;

if (Tfft ~= Tifft)
    fprintf('forward Tfft = %d does not equal inverse Tifft = %d', Tfft, Tifft)
    error("Aborting");
end

% During PFB, the first Nlost points are lost
Tlost_pfb = Nlost;

% During PFB inversion, the first Tskip points are lost
Tlost_inv = Tskip;

Tlost = Tlost_inv + Tlost_pfb;

fprintf('Tin=%d Tskip=%d Tlost_inv=%d Tlost_pfb=%d \n',Tin,Tskip,Tlost_inv,Tlost_pfb);

if ( p.Results.Nfft > 0 )
    Nfft = p.Results.Nfft;
    fprintf('Setting Nfft to %i \n',Nfft)
end

fileID = fopen (header_file, 'r');
header = read_header(fileID);
fclose(fileID);

fprintf('DADA header parsed \n');

nbit = p.Results.nbit;

if ( nbit ~= 32 )
  fprintf ('Quantizing output to %d bits\n', nbit)
  header('NBIT') = num2str(nbit);
end

fileID = fopen (output_file, 'w');

npol = 1;
nchan = 1;

ndat = Tifft - Tskip;
if (domain == "spectral")
    Nvirtual = Nchan * Tkeep;
    delta_freq = (Nvirtual - Tifft) / 2;
    ndat = 2*ndat;
    Fstep = round((Tifft + Tkeep) / (Nstate - 1));
end

fprintf('writing %i blocks of %i samples \n', Nstate, ndat)

for istate = 1:Nstate

    file_offset = (istate-1) * ndat;

    if (domain == "temporal")
        offset = Tskip + Tstep + (istate+1) * Tstep / Nstate;
        Ki = (file_offset+offset-Tlost) * Qden / Qnum;
        fprintf('state %d: impulse offset=%d file offset=%d -> Ki=%d \n',istate,offset,file_offset,Ki);
        byte_offset = dada_header + ((file_offset + offset) * 2 + 1) * nbit/8;
        fprintf('byte_offset=%d \n',byte_offset);
        data = complex(cast(zeros(npol, nchan, ndat),"single"));
        data(1,1,1+offset) = 0 + 1j;
    else
        freq = (istate - 1) * Fstep
        fprintf('state %d: tone freq=%d file offset=%d \n',istate,freq,file_offset);
        virtual_freq = (freq+delta_freq)/Nvirtual;
        data = complex(cast(zeros(npol, nchan, ndat),"single"));
        t = 0:nifft-1;
        data(1,1,0:nifft-1) = exp(j*(2*pi*virtual_freq*t));
    end

    if (nbit == 32)
        to_write = complex(cast(data,"single"));
    elseif (nbit == 16)
        to_write = complex(cast(2^14*data,"int16"));
    elseif (nbit == 8)
        to_write = complex(cast(2^6*data,"int8"));
    end
  
    if isreal(to_write)
        error('to_write is unexpectedly real-valued')
    end

    if (istate == 1)
        write_dada_header (fileID, to_write, header);
        fprintf('header written to outut DADA file \n')
    end

    write_dada_data (fileID, to_write);

end

Ntrail = Tskip + Tin;
fprintf('writing %i samples of trailing zeros \n', Ntrail)
data = complex(cast(zeros(npol, nchan, Ntrail),"single"));

if (nbit == 32)
    to_write = complex(cast(data,"single"));
elseif (nbit == 16)
    to_write = complex(cast(2^14*data,"int16"));
elseif (nbit == 8)
    to_write = complex(cast(2^6*data,"int8"));
end

write_dada_data (fileID, to_write);

Ttotal = Nstate*ndat+Ntrail;
Tsecond = (Ttotal-Tin)/Tstep;
fprintf('test vector of %d samples written to %s \n',Ttotal,output_file);
fprintf('expect %d samples in output of second-stage PFB \n', Tsecond);

% Size of backward FFT performed to synthesize fine channels during PFB inversion
tifft = Ncritical * Tkeep;
tskip = Ncritical * Tover;
fprintf('expect %d samples after PFB inversion\n', Nstate*(tifft-tskip));
fclose(fileID);
