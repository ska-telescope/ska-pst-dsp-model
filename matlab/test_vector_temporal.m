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

% forward FFT length used during PFB inversion
addOptional(p, 'Nfft', 0, @isnumeric);

% amples by which forward FFTs overlap
addOptional(p, 'Tover', 0, @isnumeric);

parse(p, varargin{:});

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
    print('Setting Nfft to %i',Nfft)
end

if ( header_file == "" )
  error ('Missing header=name of JSON formatted DADA header');
end

if ( output_file == "" )
  error ('Missing output=name of DADA format output file');
end

fileID = fopen (header_file, 'r');
header = read_header(fileID);
fclose(fileID);

[fb_data] = load_fb_tb_data(input_file, 4, 3);

fb_size = size(fb_data)
% (20,:,1,1) = fine frequency 20, all time samples, first polarisation, 
% first virtual channel (which is configured to have a delay of 0 in the simulation)

n_pol=1
n_chan=fb_size(1);
n_samp=fb_size(2);

x = complex(zeros(n_pol, n_chan, n_samp));
x(1,:,:) = fb_data(:,:,1,virtual_channel);

stddev = sqrt(var(x,0,"all"));
fprintf ("input rms=%e \n", stddev);

data = complex(cast(x,"single"));

fileID = fopen (output_file, 'w');
write_dada_header (fileID, data, header);
write_dada_data (fileID, data);
fclose(fileID);

result = 0;
