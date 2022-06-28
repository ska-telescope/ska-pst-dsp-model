function sgcht(varargin)

% Signal Generator, Channelizer, and Tester (s g ch & t)  
% This function is meant to be used as a stand alone executable.
% It creates a DADA file containing the generated signal and can
% optionally perform fidelity tests.
%
% Uses ``inputParser`` and a bunch of other classes
%
% Example:
%
% .. code-block::
%
%   sgcht(signal='complex_sinusoid', cfg='low')
%
% Args:
%   varargin (cell): Inputs to parsed.
    
p = inputParser;

% name of the analysis filter bank configuration (default: none)
addOptional(p, 'cfg',       '',            @ischar);
% name of the signal generator (default: square wave)
addOptional(p, 'signal',    'square_wave', @ischar);
% when true, peform two stages of analysis filterbank
addOptional(p, 'two_stage', false,         @islogical);
% when true, invert the (second stage) analysis filterbank
addOptional(p, 'invert',    false,         @islogical);
% when true, retain only the critically sampled fraction of (first stage)
addOptional(p, 'critical',  false,         @islogical);

parse(p, varargin{:});

signal = p.Results.signal;

file = DADAFile;
file.filename = "../products/" + signal;

cfg = p.Results.cfg;
if ( cfg ~= "" )
  file.filename = file.filename + "_" + cfg;
end

two_stage  = p.Results.two_stage;
if ( two_stage )
  file.filename = file.filename + "_two_stage";
end

critical  = p.Results.critical;
if (critical == 1)
  if (two_stage == 0)
     error ('Critically-sampled output makes sense only for two-stage\n');
  end
  file.filename = file.filename + "_critical";
end

invert = p.Results.invert;
if ( invert )
  if ( cfg == "" )
     error ('Cannot invert without analysis filterbank cfg');
  end
  file.filename = file.filename + "_inverted";
end

file.filename = file.filename + ".dada";

header_template = "../config/" + signal + "_header.json";
json_str = fileread(header_template);
header = struct2map(jsondecode(json_str));
tsamp = str2num(header('TSAMP'));    % in microseconds

if (signal == "square_wave")
    
    gen = SquareWave;
    
    calfreq = str2num(header('CALFREQ')); % in Hz
    gen.period = 1e6 / (calfreq * tsamp); % in samples
    
    fprintf ('square_wave: frequency=%f Hz\n', calfreq);
    fprintf ('square_wave: sampling interval=%f microseconds\n', tsamp);
    fprintf ('square_wave: period=%d samples\n', gen.period);
    
elseif (signal == "complex_sinusoid")
    
    gen = PureTone;
    calfreq = str2num(header('TONEFREQ')); % in kHz
    gen.period = 1e3 / (calfreq * tsamp); % in samples
    fprintf ('complex_sinusoid: frequency=%f kHz\n', calfreq);
    fprintf ('complex_sinusoid: sampling interval=%f microseconds\n', tsamp);
    fprintf ('complex_sinusoid: period=%f samples\n', gen.period);

elseif (signal == "temporal_impulse")

    gen = Impulse;
    gen.offset = 20000; % in samples
    fprintf ('temporal_impulse: offset=%d samples\n', gen.offset);

else
    error ('Unrecognized signal: ' + signal);
end

n_chan = 1;

if (cfg ~= "")
  
    fprintf ('loading "%s" analysis filter bank\n', cfg);
    config = default_config(cfg);
    
    filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
    n_chan = config.channels;
    os_factor = config.os_factor;
        
    if (two_stage)
        filterbank = TwoStageFilterBank (config);
        filterbank.critical = critical;
        level = 2;
    else
        filterbank = FilterBank (config);
        level = 1;
    end
    
    if (invert)
        if (two_stage)
            inverse = TwoStageInverseFilterBank (config);
        else
            inverse = InverseFilterBank (config);
        end
        
        level = level - 1;
    end
    
    if (level)
        
        new_tsamp = tsamp;
        for l = 1:level
            new_tsamp = normalize(os_factor, new_tsamp) * n_chan;
        end
    
        header('TSAMP') = num2str(new_tsamp);

        header('HDR_SIZE') = '65536';
        header('TSAMP') = num2str(new_tsamp);
        header('PFB_DC_CHAN') = '1';
        header('NCHAN_PFB_0') = num2str(n_chan);
        header('OS_FACTOR') = sprintf('%d/%d', os_factor.nu, os_factor.de);
        header = add_fir_filter_to_header (header, {filt_coeff}, {os_factor});
    
    end

end

file.header = header;

blocksz = 64 * 1024 * 1024; % 64 M-sample blocks in RAM
blocks = 2;                 % blocks written to disk

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
