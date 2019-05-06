function overlap_effect()
  % Quantify the effect introducing overlap save has on processing blocks of data.
  config = default_config()
  config.input_fft_length = 128;

  filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
  filt_offset = round((length(filt_coeff) - 1)/2);

  n_blocks = 5;
  block_size = normalize(config.os_factor, config.input_fft_length)*config.n_chan;  % this is also the output_fft_length
  n_bins = n_blocks*block_size;

  % frequencies = [round(1*n_blocks)];
  frequencies = [1*n_blocks];
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
  % factors = 32;
  % factors = [0, 256, 128, 64, 32, 16, 8];
  factors = 0:2:48;
  % factors = round(config.input_fft_length / 8);
  overlaps = [];
  temporal = [];
  spectral = [];
  inversion_blocks = [];

  perf = DomainPerformance;
  names = {'Max', 'Total', 'Mean'};

  for d = factors
    calc_overlap_handler = overlap_factory(d);
    forward_overlap = calc_overlap_handler(config.input_fft_length);
    backward_overlap = normalize(config.os_factor, forward_overlap)*config.n_chan;
    % offsets(1) = block_size - 2*backward_overlap + filt_offset;
    offsets(1) = block_size - backward_overlap + filt_offset
    % offsets(1) = 23351;
    % offsets(1) = round(1.5*block_size) + filt_offset;
    % offsets(1) = filt_offset;
    % offsets(1)
    % pause
    % res = test_data_pipeline(config, config.n_chan, config.os_factor,...
    %                          config.input_fft_length, n_bins,...
    %                          @complex_sinusoid,...
    %                          {frequencies, phases, bin_offset}, @polyphase_analysis, {1},...
    %                          @polyphase_synthesis_alt, ...
    %                          {deripple, sample_offset, calc_overlap_handler},...
    %                          config.data_dir);

    res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                            config.input_fft_length, n_bins,...
                            @time_domain_impulse,...
                            {offsets, widths}, @polyphase_analysis, {1},...
                            @polyphase_synthesis_alt, ...
                            {deripple, sample_offset, calc_overlap_handler},...
                            config.data_dir);
    fft_length = 2*block_size;
    chopped = chop(res, backward_overlap);
    sim = chopped{1};
    inv = chopped{2};

    diff = inv - sim;
    if length(factors) == 1
      fig = plot_performance(sim, inv, fft_length);
      p = perf.temporal_performance(inv)
      for idx=1:length(p)
        fprintf('%s spurious power = %f\n', names{idx}, 10*log10(p(idx) + 1e-13));
      end
      % suptitle(sprintf('%.2f Hz signal, input fft length: %d, overlap: %d', total_freq, config.input_fft_length, forward_overlap));
      suptitle(sprintf('%d offset impulse, input fft length: %d, overlap: %d', offsets(1), config.input_fft_length, forward_overlap));
      saveas(fig, sprintf('./../products/overlap_save.%d.png', forward_overlap));
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

function fig = plot_performance(input, inv, fft_length)
  err = ErrorAnalysis;
  powan = PowerAnalysis;
  n_subplots = 4;
  fig = figure('Position', [10, 10, 1200, 1500]);
  names = {'Input', 'Inverted'};
  dat = {input, inv};
  for idx = 1:length(names);
    ax = subplot(n_subplots, 2, idx);
    % plot(powan.dB(dat{idx}));
    plot(abs(dat{idx}));
    grid(ax, 'on');
    xlabel('Time');
    ylabel('Signal Level');
    title(sprintf('%s Time Series', names{idx}));
  end

  diff = input - inv;
  ax = subplot(n_subplots, 2, [3 4]);
  % plot(powan.dB(diff));
  plot(abs(diff));
  grid(ax, 'on');
  xlabel('Time')
  ylabel('Signal Level')
  title('Difference of Input and Inverted Time Series')

  % ax = subplot(n_subplots, 2, 4);
  % plot(20*log10(abs(diff) + 1e-13));
  % grid(ax, 'on');
  % xlabel('Time')
  % ylabel('Signal Level (dB)')
  % title('Power Difference between Input and Inverted Time Series')

  inv_fft = fftshift(fft(inv, fft_length)./fft_length);
  input_fft = fftshift(fft(input, fft_length)./fft_length);

  ax = subplot(n_subplots, 2, 5);
  plot(powan.dB(input_fft));
  % plot(abs(input_fft));
  grid(ax, 'on');
  xlabel('Frequency bin')
  ylabel('Power (dB)')
  title('Input Power Spectrum')

  ax = subplot(n_subplots, 2, 6);
  plot(powan.dB(inv_fft));
  % plot(abs(inv_fft));
  grid(ax, 'on');
  xlabel('Frequency bin')
  ylabel('Power (dB)')
  title('Inverted Power Spectrum')

  ax = subplot(n_subplots, 2, [7 8]);
  plot(powan.dB(abs(input_fft).^2 - abs(inv_fft).^2));
  grid(ax, 'on');
  xlabel('Frequency bin')
  ylabel('Power (dB)')
  title('Difference between Input and Inverted Power Spectrum')

end
