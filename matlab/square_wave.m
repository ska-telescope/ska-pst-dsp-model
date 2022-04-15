function square_wave(tele_)

tele = "";
if exist('tele_', 'var')
  tele = tele_;
end

sqwv = SquareWave;

file = DADAFile;

file.filename = 'square_wave.dada';

header_template = '../config/square_wave_header.json';
json_str = fileread(header_template);
header = struct2map(jsondecode(json_str));

calfreq = str2num(header('CALFREQ'));  % in Hz
tsamp = str2num(header('TSAMP'));      % in microseconds

sqwv.period = 1e6 / (calfreq * tsamp); % in samples

fprintf ('square_wave: frequency=%f Hz\n', calfreq);
fprintf ('square_wave: sampling interval=%f microseconds\n', tsamp);
fprintf ('square_wave: period=%d samples\n', sqwv.period);

n_chan = 1;

if (tele ~= "")
  
    fprintf ('square_wave: loading "%s" analysis filter bank\n', tele);
    config = default_config(tele);

    pfb_analysis = str2func(sprintf('@%s', config.analysis_function));
    filt_coeff = read_fir_filter_coeff(config.fir_filter_path);

    n_chan = config.channels;
    os_factor = config.os_factor;

    header('TSAMP') = num2str(normalize(os_factor, tsamp) * n_chan);
    header('PFB_DC_CHAN') = '1';
    header('NCHAN_PFB_0') = num2str(n_chan);
    header('OS_FACTOR') = sprintf('%d/%d', os_factor.nu, os_factor.de);

end

file.header = header;

blocksz = 1024 * 1024;  % Mega sample in RAM
blocks = 1024;          % Giga sample to disk

for i = 1:blocks
    
    fprintf ('block:%d/%d\n', i, blocks);
    [sqwv, x] = generate(sqwv, blocksz);
    
    if (n_chan > 1)
      x = pfb_analysis (x(1,1,:), filt_coeff, n_chan, os_factor);
    end
    
    file = write (file, x);
end

file = close (file);
