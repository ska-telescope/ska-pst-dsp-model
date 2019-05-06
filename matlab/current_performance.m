function current_performance ()
  perf = DomainPerformance;
  config = default_config();

  config.input_fft_length = 128;

  filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
  filt_offset = round((length(filt_coeff) - 1)/2);


  n_blocks = 8;
  block_size = normalize(config.os_factor, config.input_fft_length)*config.n_chan;
  block_size % 24576
  n_bins = n_blocks*block_size;
  function overlap = calc_overlap (input_fft_length)
    overlap = round(input_fft_length / 8);
    % overlap = 0;
  end

  output_offset = calc_overlap(block_size);
  input_offset = calc_overlap(config.input_fft_length);
  fft_length = 3*block_size;  % can't be n_bins
  sample_offset = 1;
  deripple = struct('apply_deripple', 1);

  npoints = 100;
  % npoints = 1;

  temporal_perf = []
  % n_bins_offset = n_bins - output_offset;
  % quarter_window = round(block_size / 4);
  % offsets = filt_offset:block_size:n_bins;
  % offsets = [offsets, (block_size:block_size:n_bins) - quarter_window + filt_offset];
  % offsets = [offsets, (block_size:block_size:n_bins-block_size) + quarter_window + filt_offset];
  % offsets = [offsets, (block_size:block_size:n_bins) - 2*quarter_window + filt_offset];
  jump = block_size - 2*output_offset;
  % offsets = filt_offset:block_size:n_bins;
  offsets = [];
  spaced = filt_offset:jump:n_bins;
  offsets = [offsets, spaced];
  offsets = [offsets, spaced(2:end) - output_offset];
  offsets = [offsets, spaced(1:end-1) + output_offset];
  % offsets = [offsets, (block_size:jump:n_bins-filt_offset) - output_offset + filt_offset];
  % offsets = [offsets, (block_size:jump:n_bins-block_size-filt_offset) + output_offset + filt_offset];
  % offsets = [offsets, (block_size:jump:n_bins) - 2*output_offset + filt_offset];

  % offsets = [offsets, 1:round(n_bins/npoints):n_bins];
  offsets = sort(offsets);

  % offsets = (block_size - 3*filt_offset):100:(block_size + 3*filt_offset);
  % offsets
  % pause

  % offsets = [50349]


  spectral_perf = [];
  frequencies = (1:round(block_size/npoints):block_size).*n_blocks;
  bin_offset = 0.1;
  names = {'Max', 'Total', 'Mean'};

  % for offset=offsets
  %   res = test_data_pipeline(config, config.n_chan, config.os_factor,...
  %                            config.input_fft_length, n_bins,...
  %                            @time_domain_impulse,...
  %                            {[offset], [1]}, @polyphase_analysis, {1},...
  %                            @polyphase_synthesis_alt, ...
  %                            {deripple, sample_offset, @calc_overlap},...
  %                            config.data_dir);
  %
  %   chopped = chop(res, output_offset);
  %   if length(offsets) == 1
  %     plot_temporal_performance(chopped{:});
  %   end
  %   p = perf.temporal_performance(chopped{2});
  %   temporal_perf = [temporal_perf; p];
  % end

  for freq=frequencies
    res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                             config.input_fft_length, n_bins,...
                             @complex_sinusoid,...
                             {[freq], [pi/4], bin_offset}, @polyphase_analysis, {1},...
                             @polyphase_synthesis_alt, ...
                             {deripple, sample_offset, @calc_overlap},...
                             config.data_dir);

    chopped = chop(res, output_offset);
    if length(frequencies) == 1
      plot_spectral_performance(chopped{:}, fft_length);
    end
    spectral_perf = [spectral_perf; perf.spectral_performance(chopped{2}, fft_length)];
  end

  if npoints > 1
    fig = plot_performance_measures(offsets, temporal_perf, names);
    xlabel('Impulse position');
    suptitle('Temporal performance');
    saveas(fig, sprintf('./../products/performance.temporal.%d_offset.png', input_offset));

    % fig = plot_performance_measures(frequencies, spectral_perf, names);
    % xlabel('Frequency of complex sinusoid (Hz)');
    % suptitle('Spectral performance');
    % saveas(fig, sprintf('./../products/performance.spectral.%d_offset.%.2f_bin_offset.png', input_offset, bin_offset));
  end
end

function argmax = argmax(a)
  [maxval, argmax] = max(a);
end

function dB = dB(a)
  dB = 20.0*log10(abs(a) + 1e-13);
end

function fig = plot_performance_measures(x, perf, names)
  fig = figure('Position', [10 10 1200 1200]);
  n_subplots = 3;
  for i=1:n_subplots
    ax = subplot(n_subplots, 1, i); grid(ax, 'on');
      plot(x, 10.0*log10(abs(squeeze(perf(:, i))) + 1e-13), '-o');
      ylabel('Signal Level (dB)');
      grid(ax, 'on');
      % set(ax, 'YScale', 'log');
      title(sprintf('%s spurious power of inverted signal', names{i}));
  end
end

function fig = plot_spectral_performance (in, inv, fft_length)
  fig = figure('Position', [10, 10, 1200, 1200]);
  perf = DomainPerformance;

  arr = {in, inv};
  names = {'Input', 'PFB inversion'};

  n_subplots = length(arr);

  for idx=1:n_subplots
    a = fftshift(fft(arr{idx}, fft_length)./fft_length);
    a = a ./max(a);
    name = names{idx};
    fprintf('max of %s: %f\n', name, max(abs(a)));

    res = perf.spectral_performance(arr{idx}, fft_length);
    res

    ax = subplot(n_subplots, 1, idx);
      l1 = plot(dB(a));
      ylabel('Power Level (dB)');
      title(name);
      grid(ax, 'on');
  end
  xlabel('Frequency bin');
end

function fig = plot_temporal_performance (in, inv)
  fig = figure('Position', [10, 10, 1200, 1200]);
  perf = DomainPerformance;

  arr = {in, inv};
  names = {'Input', 'PFB inversion'};

  n_subplots = length(arr);

  for idx=1:n_subplots
    a = arr{idx};
    a = a ./max(abs(a));
    name = names{idx};
    fprintf('max of %s: %f\n', name, max(abs(a)));

    res = perf.temporal_performance(arr{idx});

    ax = subplot(n_subplots, 1, idx);
      l1 = plot(abs(a));
      ylabel('Signal Level');
      title(name);
      grid(ax, 'on');
  end
  xlabel('Time');
end
