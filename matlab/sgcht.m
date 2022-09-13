function result = sgcht(varargin)

% Signal Generator, Channelizer, and Tester (s g ch & t)  
%
% This function creates a DADA file containing a generated signal 
% and can optionally perform fidelity tests.
%
% Example:
%
%   sgcht(signal='complex_sinusoid', cfg='low')
%
% Args:
%
%   cfg (string):    analysis filter bank configuration (default: '')
%
%   signal (string): signal generated (default: 'square_wave')
%                    'square_wave' - amplitude-modulated noise
%                    'frequency_comb' - harmonics with amplitude slope
%                    'complex_sinusoid' - pure tone
%                    'temporal_impulse' - delta function
%   
    
p = inputParser;

% name of the analysis filter bank configuration (default: none)
addOptional(p, 'cfg',       '',            @ischar);

% name of the signal generator (default: square wave)
addOptional(p, 'signal',    'square_wave', @ischar);

% peform two stages of analysis filterbank
addOptional(p, 'two_stage', false,         @islogical);

% invert the (second stage) analysis filterbank
addOptional(p, 'invert',    false,         @islogical);

% number of coarse channels to be combined when inverting second stage
addOptional(p, 'combine',    1,            @isnumeric);

% retain only the critically sampled fraction of (first stage)
addOptional(p, 'critical',  false,         @islogical);

% output only the first coarse channel
addOptional(p, 'single',  false,           @islogical);

% produce a frequency comb that spans a single coarse or find channel
addOptional(p, 'comb', '', @ischar);

% test the fidelity of 'complex_sinusoid' or 'temporal_impulse'
addOptional(p, 'test',  false,             @islogical);

parse(p, varargin{:});

signal = p.Results.signal;
cfg = p.Results.cfg;

file = DADAFile;
file.filename = "../products/" + signal;

comb  = p.Results.comb;
if ( comb == "coarse" || comb == "fine")
  if ( cfg == "" )
     error ('Cannot have specify comb spacing without analysis filterbank cfg');
  end
  if ( signal ~= "frequency_comb" )
     error ('Cannot specify comb spacing when signal is not a frequency comb');
  end
  file.filename = file.filename + "_" + comb;
end

if ( cfg ~= "" )
  file.filename = file.filename + "_" + cfg;
end

two_stage  = p.Results.two_stage;
if ( two_stage )
  if ( cfg == "" )
     error ('Cannot have two stages without analysis filterbank cfg');
  end
  file.filename = file.filename + "_two_stage";
end

critical  = p.Results.critical;
if (critical == 1)
  if (two_stage == 0)
     error ('Critically-sampled output implemented only for two-stage\n');
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

combine = p.Results.combine;
if ( combine > 1 )
  if ( ~two_stage )
     error ('Cannot combine coarse channels without two-stage analysis');
  end
  if ( ~invert )
     error ('Cannot combine coarse channels without inverting the second stage');
  end
  file.filename = file.filename + "_" + string(combine);
end

single_chan = p.Results.single;
if ( single_chan )
  if (two_stage == 0)
     error ('Single-channel output implemented only for two-stage\n');
  end
  file.filename = file.filename + "_single";
end

testing = p.Results.test;
if ( testing )
  if ( signal ~= "complex_sinusoid" && signal ~= "temporal_impulse" )
    error ('Testing implemented for only complex_sinusoid and temporal_impulse');
  end

  fprintf ('When testing, no file is output.\n')
end

file.filename = file.filename + ".dada";

header_template = "../config/" + signal + "_header.json";
json_str = fileread(header_template);
header = struct2map(jsondecode(json_str));
tsamp = str2num(header('TSAMP'));    % in microseconds

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
        filterbank.single = single_chan;
        level = 2;
    else
        filterbank = FilterBank (config);
        level = 1;
    end
    
    if (invert)
        if (two_stage)
            inverse = TwoStageInverseFilterBank (config);
            inverse.single = single_chan;
            inverse.combine = combine;
        else
            inverse = InverseFilterBank (config);
        end
        
        level = level - 1;
    end
    
    if (level)
        
        new_tsamp = tsamp;
        for l = 1:level
            if (critical && level == 1)
                new_tsamp = new_tsamp * n_chan;
            else
                new_tsamp = normalize(os_factor, new_tsamp) * n_chan;
            end
        end
    
        new_tsamp = new_tsamp / combine;
        
        header('TSAMP') = num2str(new_tsamp);
        header('HDR_SIZE') = '65536';
        header('PFB_DC_CHAN') = '1';
        header('NCHAN_PFB_0') = num2str(n_chan);
        header('OS_FACTOR') = sprintf('%d/%d', os_factor.nu, os_factor.de);
        header = add_fir_filter_to_header (header, {filt_coeff}, {os_factor});
    
    end

end

if (signal == "square_wave")
    
    gen = SquareWave;
    
    calfreq = str2num(header('CALFREQ')); % in Hz
    gen.period = 1e6 / (calfreq * tsamp); % in samples

    fprintf ('square_wave: frequency=%f Hz\n', calfreq);
    fprintf ('square_wave: sampling interval=%f microseconds\n', tsamp);
    fprintf ('square_wave: period=%f samples\n', gen.period);

elseif (signal == "frequency_comb")
    
    nfft = 1024;
    nharmonic = 32;
    amplitudes = transpose(linspace (1.0,sqrt(2.0),nharmonic));
    fmin = -0.5;  % cycles per sample
    fmax = fmin + (nharmonic - 1.0) / nharmonic;

    if (comb == "coarse")
        fmin = fmin / n_chan;
        fmax = fmax / n_chan;
    elseif (comb == "fine")
        fmin = fmin / n_chan^2;
        fmax = fmax / n_chan^2;
    end

    frequencies = transpose(linspace (fmin, fmax, nharmonic));    
    gen = FrequencyComb (amplitudes, frequencies);

elseif (signal == "complex_sinusoid")
    
    gen = PureTone;
    calfreq = str2num(header('TONEFREQ')); % in kHz
    gen.frequency = (calfreq * tsamp) / 1e6; % in samples
    
    fprintf ('complex_sinusoid: frequency=%f kHz\n', calfreq);
    fprintf ('complex_sinusoid: sampling interval=%f microseconds\n', tsamp);
    fprintf ('complex_sinusoid: period=%d samples\n', 1./gen.frequency);

    if (testing)
      tester = TestPureTone;
      tester.frequency = gen.frequency;
    end

elseif (signal == "temporal_impulse")

    gen = Impulse;
    gen.offset = 20000; % in samples
    fprintf ('temporal_impulse: offset=%d samples\n', gen.offset);

    if (testing)
      output_overlap = normalize(config.os_factor,config.input_overlap)*config.channels;
      % calculate the offset between input and inverted data due to the FIR filter
      fir_offset = config.fir_offset_direction * floor(length(filt_coeff) / 2);
      filter_offset = output_overlap - 1 + config.kludge_offset;
      fprintf ('TestImpulse offset=%d \n',filter_offset)
      tester = TestImpulse;
      tester.offset = gen.offset + fir_offset - filter_offset;
    end
else
    error ('Unrecognized signal: ' + signal);
end

file.header = header;

if ( two_stage )
    blocksz = 64 * 1024 * 1024; % 64 M-sample blocks in RAM
    blocks = 2;                 % blocks written to disk
else
    blocksz = 64 * 1024;        % 64 k-sample blocks in RAM
    blocks = 2 * 1024;          % more blocks

    if (signal == "frequency_comb")
        blocks = 128;
    end
end

if ( cfg == "mid" )
    blocksz = blocksz * 2;  % 'mid' needs more data
end

tstart = tic;

for i = 1:blocks
    
    if ( two_stage || mod(i,100) == 0)
        fprintf ('block:%d/%d\n', i, blocks);
    end
    
    [gen, x] = generate(gen, blocksz);
        
    if (n_chan > 1)
        [filterbank, x] = execute (filterbank, x);
    end
        
    if (invert)
        [inverse, x] = execute (inverse, x);
    end
    
    if (testing)
      [tester, result] = test (tester, x);

      if (result ~= 0)
          fprintf('sgcht test failed\n')
          result = -1;
          return;
      end

    else
      file = write (file, single(x));
    end

end

tdelta = toc(tstart);
fprintf('sgcht took %f seconds\n', tdelta);

if (~testing)
    fprintf ('closing %s\n',file.filename)
    file = close (file);
end

result = 0;
