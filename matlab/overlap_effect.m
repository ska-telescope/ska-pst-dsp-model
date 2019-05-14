function overlap_effect()
  % Quantify the effect introducing overlap save has on processing blocks of data.
  config = default_config()
  config.n_chan = 8;
  config.fir_filter_path = './../config/Prototype_FIR.4-3.8.80.mat';

  config.input_fft_length = 1024;

  filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
  filt_offset = round((length(filt_coeff) - 1)/2);

  n_blocks = 5;
  block_size = normalize(config.os_factor, config.input_fft_length)*config.n_chan;  % this is also the output_fft_length
  n_bins = n_blocks*block_size;

  frequencies = [round(1*n_blocks)];
  phases = [pi/4];
  bin_offset = 0.1;
  total_freq = frequencies(1) + bin_offset;

  offsets = [block_size];
  widths = [1];

  meta_struct = struct();

  deripple = struct('apply_deripple', 1);
  sample_offset = 1;

  function overlap_handler = overlap_factory (d)
    function overlap = calc_overlap (input_fft_length)
      if d == 0
        overlap = 0;
      else
        % overlap = round(input_fft_length / d)
        overlap = d
      end
    end
    overlap_handler = @calc_overlap;
  end
  factors = [32];
  win = PFBWindow;
  % window_function = win.hann_factory(config.input_fft_length);
  window_function = win.tukey_factory(config.input_fft_length, factors(1));
  % window_function = @win.top_hat_window;
  % window_function = @win.baseball_hat_window;
  % window_function = win.fedora_factory(2);
  % window_function = @win.no_window;

  % factors = 32;
  % factors = [0, 256, 128, 64, 32, 16, 8];
  % factors = 0:2:48;
  % factors = [config.input_fft_length / 8];
  % factors = round(config.input_fft_length / 8);
  overlaps = [];
  temporal = [];
  spectral = [];
  inversion_blocks = [];

  perf = DomainPerformance;
  names = {'Max', 'Total', 'Mean'};
  domain = 'time';
  % domain = 'freq';

  for d = factors
    calc_overlap_handler = overlap_factory(d);
    forward_overlap = calc_overlap_handler(config.input_fft_length);
    backward_overlap = normalize(config.os_factor, forward_overlap)*config.n_chan;

    jump = block_size - 2*backward_overlap;
    % offsets(1) = filt_offset + 100;
    % offsets(1) = block_size + filt_offset + backward_overlap/2;
    % offsets(1) = 29261;
    offsets(1) = jump + backward_overlap + filt_offset;
    % offsets(1) = (n_blocks-1)*block_size + filt_offset  + 12000;
    % offsets(1) = jump + filt_offset;
    % offsets(1) = block_size + backward_overlap + filt_offset;
    % offsets(1) = block_size - backward_overlap + filt_offset;
    % offsets(1) = block_size - 2*backward_overlap + filt_offset;
    % offsets(1) = block_size + filt_offset;
    % offsets(1) = 23351;
    % offsets(1) = round(1.5*block_size) + filt_offset;
    % offsets(1) = filt_offset;
    % offsets(1)
    % pause
    if strcmp(domain, 'freq')
      res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                               config.input_fft_length, n_bins,...
                               @complex_sinusoid,...
                               {frequencies, phases, bin_offset}, @polyphase_analysis, {1},...
                               @polyphase_synthesis, ...
                               {deripple, sample_offset, calc_overlap_handler, window_function},...
                               config.data_dir);      % suptitle(sprintf('%d offset impulse, input fft length: %d, overlap: %d', offsets(1), config.input_fft_length, forward_overlap));

      single_plot_title = sprintf('%.2f Hz signal, input fft length: %d, overlap: %d', total_freq, config.input_fft_length, forward_overlap);
    else
      res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                              config.input_fft_length, n_bins,...
                              @time_domain_impulse,...
                              {offsets, widths}, @polyphase_analysis, {1},...
                              @polyphase_synthesis, ...
                              {deripple, sample_offset, calc_overlap_handler, window_function},...
                              config.data_dir);
      single_plot_title = sprintf('%d offset impulse, input fft length: %d, overlap: %d', offsets(1), config.input_fft_length, forward_overlap);
    end

    % channelized = res{2}{2};
    % plot_channelized_time_series(channelized, 8);
    % pause;

    fft_length = 2*block_size;
    chopped = chop(res, backward_overlap);
    sim = chopped{1};
    inv = chopped{2};

    diff = inv - sim;
    if length(factors) == 1
      fig = plot_performance(sim, inv, fft_length, domain);
      if strcmp(domain, 'freq')
        p = perf.spectral_performance(inv, fft_length)
        p = [p, perf.temporal_difference(sim, inv)]
        names = {'Max Spurious', 'Total Spurious', 'Mean spurious', 'Max Difference', 'Total Difference', 'Mean Difference'};
        for idx=1:length(p)
          % fprintf('%f\n', 10*log10(p(idx) + 1e-13);
          fprintf('%s power = %f\n', names{idx}, 10*log10(p(idx) + 1e-13));
        end
      else
        p = perf.temporal_performance(inv)
        for idx=1:length(p)
          fprintf('%s spurious power = %f\n', names{idx}, 10*log10(p(idx) + 1e-13));
        end
      end
      suptitle(single_plot_title);
      saveas(fig, sprintf('./../products/overlap_save.%d.%s.png', forward_overlap, domain));
    end

    overlaps = [overlaps forward_overlap];
    spectral = [spectral; perf.spectral_performance(inv, fft_length)];
    temporal = [temporal; perf.temporal_performance(inv)];

    % calculate the number of computational blocks used in PFB inversion
    size_chan_squeezed = size(res{2}{2});
    n_dat_chan = size_chan_squeezed(2);
    input_keep = config.input_fft_length - 2*forward_overlap;
    n_block_pfb_inversion = floor((n_dat_chan - 2*forward_overlap) / input_keep);
    inversion_blocks = [inversion_blocks; n_block_pfb_inversion];

  end
  powan = PowerAnalysis;
  if length(factors) > 1
    fig = figure('Position', [10, 10, 1400, 1600]);
    prod_subplots = 4;

    for idx=1:length(names)
      ax = subplot(prod_subplots, 1, idx);
      plot(overlaps, powan.dB(squeeze(temporal(:, idx)))./2, '-o', 'MarkerFaceColor', 'b');
      % set(ax, 'YScale', 'log');
      title(sprintf('%s Spurious Power of Inverted Time Series', names{idx}));
      ylabel('Signal level');
      grid(ax, 'on');
    end

    ax = subplot(prod_subplots, 1, prod_subplots);
    plot(overlaps, inversion_blocks, '-o', 'MarkerFaceColor', 'b');
    title('Number of Computational Blocks');

    xlabel('Forward Overlap Length');
    ylabel('# of Blocks');
    grid(ax, 'on');


    suptitle(sprintf('Temporal performance, block edge impulse', offsets(1)));
    saveas(fig, sprintf('./../products/overlap_effect.temporal.%d.png', offsets(1)));

    % suptitle(sprintf('Temporal performance, %.2f Hz signal', total_freq));
    % saveas(fig, sprintf('./../products/overlap_effect.temporal.%.2f.png', total_freq));
    fig = figure('Position', [10, 10, 1400, 1600]);
    for idx=1:length(names)
      ax = subplot(prod_subplots, 1, idx);
      plot(overlaps, squeeze(spectral(:, idx)), '-o', 'MarkerFaceColor', 'b');
      set(ax, 'YScale', 'log');
      title(sprintf('%s Spurious Power of Inverted Spectrum', names{idx}));
      ylabel('Signal level');
      grid(ax, 'on');
    end

    ax = subplot(prod_subplots, 1, prod_subplots);
    plot(overlaps, inversion_blocks, '-o', 'MarkerFaceColor', 'b');
    title('Number of Computational Blocks');
    ylabel('# of Blocks');
    grid(ax, 'on');

    xlabel('Forward Overlap Length');

    suptitle(sprintf('Spectral performance, block edge impulse', offsets(1)));
    saveas(fig, sprintf('./../products/overlap_effect.spectral.%d.png', offsets(1)));

    % suptitle(sprintf('Spectral performance, %.2f Hz signal', total_freq));
    % saveas(fig, sprintf('./../products/overlap_effect.spectral.%.2f.png', total_freq));
  end
end

function plot_block_boundaries(ax, n_blocks, block_size)
  for block_bound=1:n_blocks-1
    x = block_bound*block_size;
    l = line([x, x], get(ax,'YLim'), 'Color', [0 0 0 0.3], 'LineWidth', 1.5);
  end
end

function fig = plot_performance(input, inv, fft_length, domain_)
  domain = 'time';
  if exist('domain_', 'var')
    domain = domain_
  end
  err = ErrorAnalysis;
  powan = PowerAnalysis;
  n_subplot_rows = 3;
  n_subplot_cols = 2;
  fig = figure('Position', [10, 10, 800*n_subplot_cols, 400*n_subplot_rows], 'Resize', 'off');
  names = {'Input', 'Inverted'};
  dat = {input, inv};
  for idx = 1:length(names);
    ax = subplot(n_subplot_rows, n_subplot_cols, n_subplot_cols*(idx-1) + 1);
    if strcmp(domain, 'time')
      l1 = plot(powan.dB(dat{idx}));
      % [g, argmax] = max(dat{idx})
      % argmax
      % l1 = plot(abs(dat{idx}));
      ylabel('Signal Level (dB)');
    else
      hold on;
      l1 = plot(real(dat{idx}));
      l2 = plot(imag(dat{idx}));
      hold off;
      legend([l1; l2], 'Real', 'Imaginary');
      ylim([-1, 1]);
      ylabel('Signal Level');
    end
    grid(ax, 'on');
    title(sprintf('%s Time Series', names{idx}));
  end

  diff = input - inv;
  % ax = subplot(n_subplot_rows, n_subplot_cols, 3);
  % % plot(powan.dB(diff));
  % plot(powan.dB(diff));
  % grid(ax, 'on');
  % xlabel('Time')
  % ylabel('Signal Level (dB)')
  % title('Difference of Input and Inverted Time Series')

  ax = subplot(n_subplot_rows, n_subplot_cols, 5);
  plot(20*log10(abs(diff) + 1e-13));
  grid(ax, 'on');
  xlabel('Time')
  ylabel('Signal Level (dB)')
  title({'Power Difference between Input', 'and Inverted Time Series'})

  inv_fft = fftshift(fft(inv, fft_length)./fft_length);
  input_fft = fftshift(fft(input, fft_length)./fft_length);

  ax = subplot(n_subplot_rows, n_subplot_cols, 2);
  plot(powan.dB(input_fft));
  % plot(abs(input_fft));
  grid(ax, 'on');
  ylabel('Power (dB)')
  title('Input Power Spectrum')

  ax = subplot(n_subplot_rows, n_subplot_cols, 4);
  plot(powan.dB(inv_fft));
  % plot(abs(inv_fft));
  grid(ax, 'on');
  ylabel('Power (dB)')
  title('Inverted Power Spectrum')

  ax = subplot(n_subplot_rows, n_subplot_cols, 6);
  plot(powan.dB(abs(input_fft).^2 - abs(inv_fft).^2));
  grid(ax, 'on');
  ylabel('Power (dB)')
  title({'Difference between Input', 'and Inverted Power Spectrum'})
  xlabel('Frequency bin')

end


function fig = plot_channelized_time_series (channelized, ichan_)

  size_channelized = size(channelized);
  nchan = size_channelized(2);
  fig = figure;
  if exist('ichan_', 'var')
    ax = subplot(1, 1, 1);
    % plot(20.0*log10(abs(squeeze(channelized(1, ichan_, :)) + 1e-13)));
    plot(abs(squeeze(channelized(1, ichan_, :))));
    xlim([0 100]);
  else
    for ichan=1:nchan;
      ax = subplot(nchan, 1, ichan);
      plot(abs(squeeze(channelized(1, ichan, :))));
    end
  end
end
