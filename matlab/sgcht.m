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
addOptional(p, 'cfg', '', @ischar);

% name of the second-stage analysis filter bank configuration (default: none)
addOptional(p, 'cfg2', '', @ischar);

% skip the analysis filter bank step (default: none)
addOptional(p, 'skip', false, @islogical);

% name of the signal generator (default: square wave)
addOptional(p, 'signal', 'square_wave', @ischar);

% alternatively, load signal from file
addOptional(p, 'input', '', @ischar);

% peform two stages of analysis filterbank
addOptional(p, 'two_stage', false, @islogical);

% invert the (second stage) analysis filterbank
addOptional(p, 'invert', false, @islogical);

% number of coarse channels to be combined when inverting second stage
addOptional(p, 'combine', 1, @isnumeric);

% retain only the critically sampled fraction of (first stage)
addOptional(p, 'critical', false, @islogical);

% output only the first coarse channel
addOptional(p, 'single', false, @islogical);

% produce a frequency comb that spans a single coarse or find channel
addOptional(p, 'comb', '', @ischar);

% test the fidelity of 'complex_sinusoid' or 'temporal_impulse'
addOptional(p, 'test', false, @islogical);

% name of the spectral taper function
addOptional(p, 'f_taper', '', @ischar);

% number of bits per sample in output data file
addOptional(p, 'nbit', 32, @isnumeric);

% scale factor applied before casting
addOptional(p, 'scale', 1, @isnumeric);

parse(p, varargin{:});

signal = p.Results.signal;
input_file = p.Results.input;

if ( input_file ~= "" )
  signal = "from_file";
end

cfg = p.Results.cfg;
cfg2 = p.Results.cfg2;
skip_analysis = p.Results.skip;

file = DADAWrite;
file.filename = "../products/" + signal;

comb = p.Results.comb;
if ( comb == "coarse" || comb == "fine")
  if ( cfg == "" )
     error ('Cannot specify comb spacing without analysis filterbank cfg');
  end
  if ( signal ~= "frequency_comb" )
     error ('Cannot specify comb spacing when signal is not a frequency comb');
  end
  file.filename = file.filename + "_" + comb;
end

if ( cfg ~= "" )
  file.filename = file.filename + "_" + cfg;
end

two_stage = p.Results.two_stage;

if ( cfg2 ~= "" )
  file.filename = file.filename + "_" + cfg2;
  two_stage = true;
end

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

f_taper = p.Results.f_taper;
if ( f_taper ~= "" )
  if ( ~invert )
     error ('Cannot apply spectral taper without analysis filterbank inversion');
  end
  file.filename = file.filename + "_" + f_taper;
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

nbit = p.Results.nbit;
if ( nbit ~= 32 )
  fprintf ('Quantizing output to %d bits\n', nbit)
  file.filename = file.filename + "_" + string(nbit) + "bit";
  scale = p.Results.scale;
  fprintf ('Scale by %f before quantizing\n', scale)
end

testing = p.Results.test;
if ( testing )
  fprintf ('When testing, no file is output.\n')
end

file.filename = file.filename + ".dada";

pfb_nchan_from_file = 0;
nchan_from_file = 0;

if (signal == "from_file")
  gen = DADARead;
  gen = open(gen, input_file);
  header = gen.header;
  pfb_nchan_from_file = str2num(header('PFB_NCHAN'));
  nchan_from_file = str2num(header('NCHAN'));
else
  header_template = "../config/" + signal + "_header.json";
  json_str = fileread(header_template);
  header = struct2map(jsondecode(json_str));
end

tsamp = str2num(header('TSAMP'));    % in microseconds

n_chan = 1;

if (cfg ~= "")
  
    fprintf ('loading "%s" analysis filter bank\n', cfg);
    config = default_config(cfg);
    
    filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
    n_chan = config.channels;
    os_factor = config.os_factor;
    level = 0;

    if (~ skip_analysis)
        if (two_stage)
            filterbank = TwoStageFilterBank (config);
            if (cfg2 ~= "")
                fprintf ('loading "%s" second-stage analysis filter bank\n', cfg2);
                config2 = default_config(cfg);
                filterbank = set_stage2_config(filterbank, config2);
            end            
            filterbank.critical = critical;
            filterbank.single = single_chan;
            level = 2;
        else
            filterbank = FilterBank (config);
            level = 1;
        end
    end

    if pfb_nchan_from_file ~= 0
        pfb_nchan = pfb_nchan_from_file;
    else
        pfb_nchan = n_chan;
        if (critical && level == 2)
            pfb_nchan = normalize(os_factor, n_chan);
        end
    end

    if (invert)
        if (two_stage)
            inverse = TwoStageInverseFilterBank (config);
            inverse.single = single_chan;
            inverse.combine = combine;
            if (cfg2 ~= "")
                fprintf ('loading "%s" second-stage analysis filter bank\n', cfg2);
                config2 = default_config(cfg);
                inverse = set_stage2_config(inverse, config2);
            end
            inverse.nch2 = pfb_nchan;
        else
            inverse = InverseFilterBank (config);
        end
        
        if ( f_taper ~= "" )
            fprintf ('sgcht: spectral taper = %s\n', f_taper)
            inverse = inverse.frequency_taper (f_taper);
        end

        level = level - 1;
    end
    
    if (level ~= 0)

        new_tsamp = tsamp;

        if (level > 0)
            if (critical && level == 1)
                new_tsamp = new_tsamp * n_chan;
            else
                for l = 1:level
                    new_tsamp = normalize(os_factor, new_tsamp) * n_chan;
                end
            end
        else
            fprintf ('sgcht: only inverting\n')
            new_tsamp = multiply(os_factor, new_tsamp) / pfb_nchan;
        end
    
        new_tsamp = new_tsamp / combine;

        header('NBIT') = num2str(nbit);
        header('TSAMP') = num2str(new_tsamp);
        header('PFB_DC_CHAN') = '1';
        header('NSTAGE') = num2str(level);
        header('NCHAN_PFB_0') = num2str(n_chan);
        header('PFB_NCHAN') = num2str(pfb_nchan);
        header('OS_FACTOR') = sprintf('%d/%d', os_factor.nu, os_factor.de);
        header = add_fir_filter_to_header (header, {filt_coeff}, {os_factor});
    
    end

end % if a PFB configuration was specified

if (signal == "from_file")

    % ensure that output data file is interpreted correctly downstream
    header('INSTRUMENT') = 'dspsr';
    fprintf ('loading signal from %s \n',input_file);

elseif (signal == "square_wave")
    
    gen = SquareWave;
    
    calfreq = str2num(header('CALFREQ')); % in Hz
    gen.period = round(1e6 / (calfreq * tsamp)); % in samples

    fprintf ('square_wave: frequency=%f Hz\n', calfreq);
    fprintf ('square_wave: sampling interval=%f microseconds\n', tsamp);
    fprintf ('square_wave: period=%f samples\n', gen.period);

    if (testing)
        error ('Testing not implemented for square_wave')
    end

elseif (signal == "frequency_comb")
    
    nharmonic = 32;
    amplitudes = transpose(linspace (1.0,sqrt(2.0),nharmonic));

    % add 1/4 harmonic spacing to fmin because -0.5 is rounded 
    % down to -1 when computing channel and harmonic offsets

    fmin = -0.5 + 1.0 / (nharmonic * 4);  % cycles per sample
    fmax = fmin + (nharmonic - 1.0) / nharmonic;

    if (comb == "coarse")
        fprintf ('frequency_comb: coarse channels\n');
        fmin = fmin / n_chan;
        fmax = fmax / n_chan;
    elseif (comb == "fine")
        fprintf ('frequency_comb: fine channels\n');
        fmin = fmin / n_chan^2;
        fmax = fmax / n_chan^2;
    elseif (n_chan > 1)

        % the following logic pulls sparse harmonics out of the DC bins of 
        % coarse or fine channels, so that scaled offsets due to things
        % like the oversampling ratio can be tested

        nch = n_chan;
        if (two_stage)
            nch = n_chan^2;
        end
        if (invert)
            nch = nch / n_chan;
        end
        if (nch > 1)
            fprintf ('frequency_comb: add quarter-channel offset (nch=%d)\n', nch)
            fmin = fmin + 1.0/(nch*4);
            fmax = fmax + 1.0/(nch*4);
        end
    end

    frequencies = transpose(linspace (fmin, fmax, nharmonic));    
    gen = FrequencyComb (amplitudes, frequencies);

    if (testing)
      tester = TestFrequencyComb;
      tester.frequencies = frequencies;
      if (cfg ~= "")
        tester.invert = invert;
        tester.os_factor = os_factor;
        tester.two_stage = two_stage;
        tester.critical = critical;
      end
    end
    
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
        
    xdim = size(x);
    ndat = xdim(end);
    % fprintf ('ndat=%d\n', ndat);

    if ndat == 0
        break;
    end

    if (n_chan > 1 && ~skip_analysis)
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

      if (nbit == 32)
        to_write = single(x);
      elseif (nbit == 16)
        to_write = cast(scale*x,"int16");
      elseif (nbit == 8)
        to_write = cast(scale*x,"int8");
      end

      file = write (file, to_write);
    end

end

tdelta = toc(tstart);
fprintf('sgcht took %f seconds\n', tdelta);

if (~testing)
    fprintf ('closing %s\n',file.filename);
    file = close (file);
end

result = 0;
