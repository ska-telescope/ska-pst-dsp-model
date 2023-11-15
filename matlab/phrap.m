function result = phrap(varargin)

% Phase Resolve Average Profile (ph r a p)  
%
% This function "folds" a periodic signal and plots the phase-resolved
% average profile
%
% Example:
%
%   phrap(input='sgcht_out.dat')
%
 
p = inputParser;

% name of the signal generator (default: square wave)
addOptional(p, 'signal', 'square_wave', @ischar);

% alternatively, load signal from file
addOptional(p, 'input', '', @ischar);

parse(p, varargin{:});

signal = p.Results.signal;
input_file = p.Results.input;

if ( input_file ~= "" )
   fprintf ('loading signal from %s \n',input_file);  
  gen = DADARead;
  gen = open(gen, input_file);
  header = gen.header;
else
  header_template = "../config/" + signal + "_header.json";
  json_str = fileread(header_template);
  header = struct2map(jsondecode(json_str));
end

tsamp = str2num(header('TSAMP'));     % in microseconds
calfreq = str2num(header('CALFREQ')); % in Hz
    % 
if (input_file == "" && signal == "square_wave")
    
  gen = SquareWave;
  gen.period = round(1e6 / (calfreq * tsamp)); % in samples

  fprintf ('square_wave: frequency=%f Hz\n', calfreq);
  fprintf ('square_wave: sampling interval=%f microseconds\n', tsamp);
  fprintf ('square_wave: period=%f samples\n', gen.period);

end

blocksz = 64 * 1024;        % 64 k-sample blocks in RAM
blocks = 4 * 1024;          % more blocks

tstart = tic;

for i = 1:blocks
    
    [gen, x] = generate(gen, blocksz);
        
    xdim = size(x);
    ndat = xdim(end);
    % fprintf ('ndat=%d\n', ndat);

    if ndat == 0
        break;
    end

    if ( mod(i,100) == 0)
        fprintf ('block:%d/%d\n', i, blocks);
    end

end

tdelta = toc(tstart);
fprintf('phrap took %f seconds\n', tdelta);

result = 0;
