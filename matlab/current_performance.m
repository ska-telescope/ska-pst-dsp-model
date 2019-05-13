function current_performance ()
  perf = DomainPerformance;
  win = PFBWindow;
  config = default_config();
  config.n_chan = 16;
  config.fir_filter_path = './../config/Prototype_FIR.4-3.16.160.mat';

  config.input_fft_length = 4096;

  filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
  filt_offset = round((length(filt_coeff) - 1)/2);

  n_blocks = 4;
  block_size = normalize(config.os_factor, config.input_fft_length)*config.n_chan;
  n_bins = n_blocks*block_size;
  function overlap = calc_overlap (input_fft_length)
    % overlap = round(input_fft_length / 8);
    % overlap = 32;
    % overlap = 0;
    overlap = 64;
  end

  input_offset = calc_overlap(config.input_fft_length);
  output_offset = normalize(config.os_factor, input_offset)*config.n_chan;
  fft_length = 2*block_size;  % can't be n_bins
  sample_offset = 1;
  deripple = struct('apply_deripple', 1);

  npoints = 200;
  % npoints = 1;

  temporal_perf = []

  jump = block_size - 2*output_offset;
  offsets = [];
  spaced = filt_offset:jump:n_bins;
  offsets = [offsets, spaced];
  offsets = [offsets, spaced(2:end) - output_offset];
  offsets = [offsets, spaced(1:end-1) + output_offset];
  offsets = [offsets, filt_offset:block_size:n_bins];
  offsets = [offsets, 1:round(n_bins/npoints):n_bins];
  offsets = sort(offsets);

  % window_function = win.blackman_factory(config.input_fft_length);
  % window_function = win.hann_factory(config.input_fft_length);
  % window_function = @win.no_window;
  % window_function = @win.top_hat_window;
  % window_function = win.fedora_factory(2);
  window_function = win.tukey_factory(config.input_fft_length, input_offset);

  spectral_perf = [];
  frequencies = (1:round(block_size/npoints):block_size).*n_blocks;
  bin_offset = 0.0;
  names = {'Max', 'Total', 'Mean'};

  for offset=offsets
    res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                             config.input_fft_length, n_bins,...
                             @time_domain_impulse,...
                             {[offset], [1]}, @polyphase_analysis, {1},...
                             @polyphase_synthesis_alt, ...
                             {deripple, sample_offset, @calc_overlap, window_function},...
                             config.data_dir);

    chopped = chop(res, output_offset);
    if length(offsets) == 1
      plot_temporal_performance(chopped{:});
    end
    p = perf.temporal_performance(chopped{2});
    temporal_perf = [temporal_perf; p];
  end

  % for freq=frequencies
  %   res = test_data_pipeline(config, config.n_chan, config.os_factor,...
  %                            config.input_fft_length, n_bins,...
  %                            @complex_sinusoid,...
  %                            {[freq], [pi/4], bin_offset}, @polyphase_analysis, {1},...
  %                            @polyphase_synthesis_alt, ...
  %                            {deripple, sample_offset, @calc_overlap, window_function},...
  %                            config.data_dir);
  %
  %   chopped = chop(res, output_offset);
  %   if length(frequencies) == 1
  %     plot_spectral_performance(chopped{:}, fft_length);
  %   end
      p = perf.spectral_performance(chopped{2}, fft_length);

  %   spectral_perf = [spectral_perf; perf.spectral_performance(chopped{2}, fft_length)];
  % end

  if npoints > 1
    window_name = get_function_name(window_function);
    title_template = sprintf('%%s performance, %s window function, %d channels, %d forward FFT, %d overlap', window_name, config.n_chan, config.input_fft_length, input_offset);
    file_name_template = sprintf('./../products/performance.%%s.%s.%d_chan.%d_fft.%d_offset.png', window_name, config.n_chan, config.input_fft_length, input_offset);


    fig = plot_performance_measures(offsets, temporal_perf, names);
    plot_vlines(fig, spaced, [0, 0.8, 0.5, 0.2]);
    plot_vlines(fig, spaced(2:end) - output_offset, [0, 0.8, 0.5, 0.2]);
    plot_vlines(fig, spaced(1:end-1) + output_offset, [0, 0.8, 0.5, 0.2]);
    plot_vlines(fig, filt_offset:block_size:n_bins, [1, 0, 0, 0.2]);
    xlabel('Impulse position');

    h = suptitle(sprintf(title_template, 'Temporal'));
    h.Interpreter = 'none';
    saveas(fig, sprintf(file_name_template, 'temporal'));

    % fig = plot_performance_measures(frequencies, spectral_perf, names);
    % xlabel('Frequency of complex sinusoid (Hz)');
    % h = suptitle(sprintf(title_template, 'Spectral'));
    % h.Interpreter = 'none';
    % saveas(fig, sprintf(file_name_template, 'spectral'));
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


function fig = plot_vlines (fig, points, color_)
  color = [0 0 0 0.5];
  if exist('color_', 'var')
    color = color_;
  end
  allAxesInFigure = findall(fig, 'type', 'axes');
  for idx=1:length(allAxesInFigure)
    ax = allAxesInFigure(idx);
    ylim = get(ax, 'YLim');
    for p=points
      l = line(ax, [p, p], ylim, 'Color', color, 'LineWidth', 1.5);
    end
  end
end
