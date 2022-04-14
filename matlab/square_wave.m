
sqwv = SquareWave;

file = DADAFile;

file.filename = 'square_wave.dada';
file.header_template = '../config/square_wave_header.json';

json_str = fileread(file.header_template);
header = struct2map(jsondecode(json_str));

calfreq = str2num(header('CALFREQ'));  % in Hz
tsamp = str2num(header('TSAMP'));      % in microseconds

sqwv.period = 1e6 / (calfreq * tsamp); % in samples

fprintf ('square_wave: frequency=%f Hz\n', calfreq);
fprintf ('square_wave: sampling interval=%f microseconds\n', tsamp);
fprintf ('square_wave: period=%d samples\n', sqwv.period);

blocksz = 1024 * 1024;  % Mega sample in RAM
blocks = 1024;          % Giga sample to disk

for i = 1:blocks
    fprintf ('block:%d/%d\n', i, blocks);
    [sqwv, x] = generate(sqwv, blocksz);
    file = write (file, x);
end

file = close (file);
