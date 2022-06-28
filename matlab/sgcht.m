function sgcht(cfg_,invert_,two_stage_,critical_)

signal = "square_wave";

file = DADAFile;
file.filename = "../products/" + signal;

cfg = "";
if exist('cfg_', 'var')
  cfg = cfg_;
  file.filename = file.filename + "_" + cfg;
end

invert = 0;
if exist('invert_', 'var')
  invert = invert_;
  file.filename = file.filename + "_" + cfg + "_inverted";
end

two_stage  = 0;
if exist('two_stage_', 'var')
  two_stage  = two_stage_;      
  if (two_stage * invert ~= 0)
     error ('Cannot invert two-stage filter bank\n');
  end
  file.filename = file.filename + "_" + cfg + "_two_stage";
end

critical  = 0;
if exist('critical_', 'var')
  critical  = critical_;      
  if (critical == 1 && two_stage == 0)
     error ('Critically-sampled output makes sense only for two-stage\n');
  end
  file.filename = file.filename + "_" + cfg + "_critical";
end

file.filename = file.filename + ".dada";

header_template = "../config/square_wave_header.json";
json_str = fileread(header_template);
header = struct2map(jsondecode(json_str));

calfreq = str2num(header('CALFREQ'));  % in Hz
tsamp = str2num(header('TSAMP'));      % in microseconds

if (signal == "square_wave")
    gen = SquareWave;
    gen.period = 1e6 / (calfreq * tsamp); % in samples
    
    fprintf ('square_wave: frequency=%f Hz\n', calfreq);
    fprintf ('square_wave: sampling interval=%f microseconds\n', tsamp);
    fprintf ('square_wave: period=%d samples\n', gen.period);
end

n_chan = 1;

if (cfg ~= "")
  
    fprintf ('square_wave: loading "%s" analysis filter bank\n', cfg);
    config = default_config(cfg);
    
    filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
    n_chan = config.channels;
    os_factor = config.os_factor;

    new_tsamp = normalize(os_factor, tsamp) * n_chan;
    
    if (two_stage == 0)
        filterbank = FilterBank (config);
    else
        filterbank = TwoStageFilterBank (config, critical);
        new_tsamp = normalize(os_factor, new_tsamp) * n_chan;
    end
    
    if (invert == 0)
        header('TSAMP') = num2str(new_tsamp);
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
blocks = 64;               % 128 Mega sample to disk

for i = 1:blocks
    
    fprintf ('block:%d/%d\n', i, blocks);
    [gen, x] = generate(gen, blocksz);
        
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
