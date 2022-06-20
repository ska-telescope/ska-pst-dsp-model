function square_wave(cfg_,invert_)

file = DADAFile;
file.filename = "../products/square_wave.dada";

cfg = "";
if exist('cfg_', 'var')
  cfg = cfg_;
  file.filename = "../products/square_wave_" + cfg + ".dada";
end

invert = 0;
if exist('invert_', 'var')
  invert = invert_;
  file.filename = "../products/square_wave_" + cfg + "_inverted.dada";
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

    filterbank = FilterBank (config);
    
    filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
    n_chan = config.channels;
    os_factor = config.os_factor;

    if (invert == 0)
        header('TSAMP') = num2str(normalize(os_factor, tsamp) * n_chan);
        header('PFB_DC_CHAN') = '1';
        header('NCHAN_PFB_0') = num2str(n_chan);
        header('OS_FACTOR') = sprintf('%d/%d', os_factor.nu, os_factor.de);
        header = add_fir_filter_to_header (header, {filt_coeff}, {os_factor});
    else
        inverse = InverseFilterBank;
        inverse = configure (inverse, config);
    end
end

file.header = header;

blocksz = 1 * 1024 * 1024;  % 1 Mega sample in RAM
blocks = 3;                 % 3 Mega sample to disk

for i = 1:blocks
    
    fprintf ('block:%d/%d\n', i, blocks);
    [sqwv, x] = generate(sqwv, blocksz);
        
    if (n_chan > 1)
        [filterbank, x] = execute (filterbank, x);
    end
    
    if (invert == 1)
        [inverse, x] = execute (inverse, x);
    end
    
    file = write (file, single(x));
end

fprintf ('closing %s\n',file.filename)
file = close (file);
