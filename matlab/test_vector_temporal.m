%
% This function generates a DADA file containing a single-channel, 
% complex-valued test vector composed of a series of delta functions.
%
% The design of the test vector is described at
%
% https://confluence.skatelescope.org/display/SE/Polyphase+Filter+Bank+Inversion%3A+Requirements+Verification
%
function test_vector_temporal(varargin)

p = inputParser;

% the correlator beam former for which the test vector is designed
addOptional(p, 'cbf', 'low', @ischar);

% number of test states
addOptional(p, 'Nstate', 2, @isnumeric);

% forward FFT length used during PFB inversion
addOptional(p, 'Nfft', 0, @isnumeric);

% samples by which forward FFTs overlap
addOptional(p, 'Tover', 0, @isnumeric);

% load header from file
addOptional(p, 'header', '../config/test_vector_dada.hdr', @ischar);

% write DADA to file
addOptional(p, 'output', '../products/test_vector_temporal.dada', @ischar);

% number of bits per sample in output data file
addOptional(p, 'nbit', 32, @isnumeric);

parse(p, varargin{:});

header_file = p.Results.header;
if ( header_file == "" )
  error ('Missing header = name of JSON-formatted DADA header');
end

output_file = p.Results.output;
if ( output_file == "" )
  error ('Missing output = name of DADA-format output file');
end

Nstate = p.Results.Nstate;

if ( Nstate < 1 )
  error ('Invalid Nstate=%i',Nstate)
end
cbf = p.Results.cbf;

dada_header = 4096;

if ( cbf == "low" )
    Nchan = 256;   % channels output by PFB
    Ntap = 12;     % filter taps per channel
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
    Ntap = 28;     % filter taps per channel
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

Ncritical = Nchan * Qden / Qnum;
Nkeep = Nfft * Rden / Rnum;
Nifft = Ncritical * Nkeep;
Nstep = Nchan * Rden / Rnum;

fprintf('Ncritical=%d Nkeep=%d Nifft=%d Nstep=%d \n',Ncritical,Nkeep,Nifft,Nstep);

Nin = Nchan * Ntap;
Tskip = Tover * Nstep;

% During PFB, the first Nlost points are lost
Tlost_pfb = Nlost;

% During PFB inversion, the first Tskip points are lost
Tlost_inv = Tskip;

Tlost = Tlost_inv + Tlost_pfb;

fprintf('Nin=%d Tskip=%d Tlost_inv=%d Tlost_pfb=%d \n',Nin,Tskip,Tlost_inv,Tlost_pfb);

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
ndat = Nifft - Tskip;

fprintf('writing %i blocks of %i samples \n', Nstate, ndat)

for istate = 1:Nstate

    offset = Tskip + Nstep + (istate-1) * Nstep / Nstate;
    file_offset = (istate-1) * ndat;

    Ki = (file_offset+offset-Tlost) * Qden / Qnum;

    fprintf('state %d: impulse offset=%d file offset=%d -> Ki=%d \n',istate,offset,file_offset,Ki);

    byte_offset = dada_header + ((file_offset + offset) * 2 + 1) * nbit/8;
    fprintf('byte_offset=%d \n',byte_offset);

    data = complex(cast(zeros(npol, nchan, ndat),"single"));
    data(1,1,1+offset) = 0 + 1j;

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

Ntrail = Tskip + Nin;
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

fprintf('test vector written to %s \n',output_file);
fclose(fileID);
