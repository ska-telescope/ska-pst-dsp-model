%
% This function generates a DADA file containing a single-channel, 
% complex-valued test vector composed of a series of delta functions.
%
% The design of the test vector is described at
%
% https://confluence.skatelescope.org/display/SE/Polyphase+Filter+Bank+Inversion%3A+Requirements+Verification
%
function result = test_vector_temporal(varargin)

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
addOptional(p, 'header', '../config/test_vector_header.json', @ischar);

% write DADA to file
addOptional(p, 'output', '../products/test_vector_temporal.dada', @ischar);

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

if ( cbf == "low" )
    Nchan = 256;   % channels output by PFB
    Ntap = 12;     % filter taps per channel
    Rnum = 4;      % numerator of oversampling ratio
    Rden = 3;      % denominator of oversampling ratio
    Nfft = 1024;   % forward FFT length used during PFB inversion
    Tover= 128;    % samples by which forward FFTs overlap
elseif ( cbf == "mid" )
    Nchan = 4096;  % channels output by PFB
    Ntap = 24.5;   % filter taps per channel
    Rnum = 8;      % numerator of oversampling ratio
    Rden = 7;      % denominator of oversampling ratio
    Nfft = 2048;   % forward FFT length used during PFB inversion
    Tover= 224;    % samples by which forward FFTs overlap
else
    error ('Unknown CBF %s', cbf);
end

if ( p.Results.Nfft > 0 )
    Nfft = p.Results.Nfft;
    fprintf('Setting Nfft to %i',Nfft)
end

fileID = fopen (header_file, 'r');
header = read_header(fileID);
fclose(fileID);

fprintf('header parsed from JSON string');

ndat = Nfft - Tover;
data = complex(cast(zeros(ndat),"single"));

fileID = fopen (output_file, 'w');
write_dada_header (fileID, data, header);

fprintf('header written to DADA file')

fprintf('writing %i blocks of %i samples',Nstate, ndat)
for istate = 1:Nstate

    data = complex(cast(zeros(ndat),"single"));
    write_dada_data (fileID, data);

end

fclose(fileID);

result = 0;
