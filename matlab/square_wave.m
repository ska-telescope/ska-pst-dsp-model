function square_wave(cfg_)

file = DADAFile;
file.filename = "square_wave.dada";

cfg = "";
if exist('cfg_', 'var')
  cfg = cfg_;
  file.filename = "square_wave_" + cfg + ".dada";
end

sqwv = SquareWave;

header_template = "../config/square_wave_header.json";
json_str = fileread(header_template);
header = struct2map(jsondecode(json_str));

calfreq = str2num(header('CALFREQ'));  % in Hz
tsamp = str2num(header('TSAMP'));      % in microseconds

sqwv.period = 1e6 / (calfreq * tsamp); % in samples

fprintf ('square_wave: frequency=%f Hz\n', calfreq);
fprintf ('square_wave: sampling interval=%f microseconds\n', tsamp);
fprintf ('square_wave: period=%d samples\n', sqwv.period);

n_chan = 1;

if (cfg ~= "")
  
    fprintf ('square_wave: loading "%s" analysis filter bank\n', cfg);
    config = default_config(cfg);

    pfb_analysis = str2func(sprintf('@%s', config.analysis_function));
    filt_coeff = read_fir_filter_coeff(config.fir_filter_path);

    n_chan = config.channels;
    os_factor = config.os_factor;

    header('TSAMP') = num2str(normalize(os_factor, tsamp) * n_chan);
    header('PFB_DC_CHAN') = '1';
    header('NCHAN_PFB_0') = num2str(n_chan);
    header('OS_FACTOR') = sprintf('%d/%d', os_factor.nu, os_factor.de);

    header = add_fir_filter_to_header (header, {filt_coeff}, {os_factor});

end

file.header = header;

blocksz = 4 * 1024 * 1024;  % 4 Mega sample in RAM
blocks = 8;                 % 32 Mega sample to disk

for i = 1:blocks
    
    fprintf ('block:%d/%d\n', i, blocks);
    [sqwv, x] = generate(sqwv, blocksz);
    
    if (n_chan > 1)
      x = pfb_analysis (x, filt_coeff, n_chan, os_factor);
      xsize = size(x);
      input_ndat = xsize(3) * n_chan * os_factor.de / os_factor.nu;
      lost = blocksz - input_ndat;
      sqwv.current = sqwv.current - lost;
    end
    
    file = write (file, single(x));
end

file = close (file);
