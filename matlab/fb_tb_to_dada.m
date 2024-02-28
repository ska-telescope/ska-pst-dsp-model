function result = fb_tb_to_dada(varargin)

p = inputParser;

% load signal from file
addOptional(p, 'input', '', @ischar);

% load header from file
addOptional(p, 'header', '', @ischar);

% write DADA to file
addOptional(p, 'output', '', @ischar);

parse(p, varargin{:});

input_file = p.Results.input;
header_file = p.Results.header;
output_file = p.Results.output;

if ( input_file == "" )
  error ('Missing input=name of filterbank output file saved by the VHDL testbench');
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
x(1,:,:) = fb_data(:,:,1,1);

stddev = sqrt(var(x,0,"all"));
fprintf ("input rms=%e \n", stddev);

data = complex(cast(x,"single"));

fileID = fopen (output_file, 'w');
write_dada_header (fileID, data, header);
write_dada_data (fileID, data);
fclose(fileID);

result = 0;
