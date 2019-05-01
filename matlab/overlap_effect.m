function overlap_effect()
  % Quantify the effect introducing overlap save has on processing blocks of data.
  config = default_config()

  n_blocks = 4;
  block_size = normalize(config.os_factor, config.input_fft_length)*config.n_chan;  % this is also the output_fft_length
  n_bins = n_blocks*block_size;

  % frequencies = [round(1*n_blocks)];
  frequencies = [1*n_blocks];
  phases = [pi/4];
  bin_offset = 0.1;

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
  % for d = 8
  % factors = [0, 256, 128, 64, 32, 16, 8];
  factors = 0:2:48;
  % 0.0010    0.0304    0.0000
  % 0.0350    0.1600    0.0000
  % factors = [0, 2, 48];
  % factors = [0, 4, 16, 32]
  % factors = 32;
  % factors = 0:4:16;
  overlaps = [];
  temporal = [];
  spectral = [];

  for d = factors
    calc_overlap_handler = overlap_factory(d);
    forward_overlap = calc_overlap_handler(config.input_fft_length);
    backward_overlap = normalize(config.os_factor, forward_overlap)*config.n_chan;
    % backward_overlap = calc_overlap_handler(block_size);
    res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                             config.input_fft_length, n_bins,...
                             @complex_sinusoid,...
                             {frequencies, phases, bin_offset}, @polyphase_analysis, {1},...
                             @polyphase_synthesis_alt, ...
                             {deripple, sample_offset, calc_overlap_handler},...
                             config.data_dir);

    data = res{2};
    meta = res{3};

    size_inv = size(data{3});
    ndat_inv = size_inv(3);
    fprintf('ndat_inv=%d\n', ndat_inv);

    sim_squeezed = squeeze(data{1}(1, 1, :));
    inv_squeezed = squeeze(data{3}(1, 1, :));
    % fir_offset = 0;
    % fft_length = floor(ndat_inv / block_size) * block_size;
    fft_length = block_size;
    sim_squeezed = sim_squeezed(backward_overlap+meta.fir_offset+1:end);
    sim = sim_squeezed(1:ndat_inv);
    inv = inv_squeezed(1:ndat_inv);
    diff = inv - sim;
    if length(factors) == 1
      fig = plot_performance(sim, inv, fft_length);
      suptitle(sprintf('input fft length: %d, overlap: %d', config.input_fft_length, forward_overlap));
      saveas(fig, sprintf('./../products/overlap_save.%d.png', forward_overlap));
    end

    spectral_performance(inv, fft_length)
    overlaps = [overlaps forward_overlap];
    spectral = [spectral; spectral_performance(inv, fft_length)];
    temporal = [temporal; temporal_performance(sim, inv)];

  end

  if length(factors) > 1
    fig = figure('Position', [10, 10, 1200, 1500]);
    prod_subplots = 3;
    ax = subplot(prod_subplots, 1, 1);
    plot(overlaps, squeeze(temporal(:, 1)), '-o', 'MarkerFaceColor', 'b');
    title('Mean difference');
    xlabel('Forward Overlap Length');
    ylabel('Signal level');
    grid(ax, 'on');

    ax = subplot(prod_subplots, 1, 2);
    plot(overlaps, squeeze(temporal(:, 2)), '-o', 'MarkerFaceColor', 'b');
    % set(ax, 'YScale', 'log')
    title('Max difference');
    xlabel('Forward Overlap Length');
    ylabel('Signal level');
    grid(ax, 'on');

    ax = subplot(prod_subplots, 1, 3);
    plot(overlaps, squeeze(temporal(:, 3)), '-o', 'MarkerFaceColor', 'b');
    title('Sum of difference');
    xlabel('Forward Overlap Length');
    ylabel('Signal level');
    grid(ax, 'on');
    suptitle(sprintf('Temporal performance, %f Hz signal', frequencies(1) + bin_offset));
    saveas(fig, './../products/overlap_effect.temporal.png');

    fig = figure('Position', [10, 10, 1200, 1500]);
    ax = subplot(prod_subplots, 1, 1);
    plot(overlaps, squeeze(spectral(:, 1)), '-o', 'MarkerFaceColor', 'b');
    title('Max spurious power');
    xlabel('Forward Overlap Length');
    ylabel('Power');
    grid(ax, 'on');

    ax = subplot(prod_subplots, 1, 2);
    plot(overlaps, squeeze(spectral(:, 2)), '-o', 'MarkerFaceColor', 'b');
    % set(ax, 'YScale', 'log')
    title('Total spurious power');
    xlabel('Forward Overlap Length');
    ylabel('Power');
    grid(ax, 'on');

    ax = subplot(prod_subplots, 1, 3);
    plot(overlaps, squeeze(spectral(:, 3)), '-o', 'MarkerFaceColor', 'b');
    title('Mean spurious power');
    xlabel('Forward Overlap Length');
    ylabel('Power');
    grid(ax, 'on');
    suptitle(sprintf('Spectral performance, %f Hz signal', frequencies(1) + bin_offset));
    saveas(fig, './../products/overlap_effect.spectral.png');
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
  n_subplots = 4;
  fig = figure('Position', [10, 10, 1200, 1500]);
  ax = subplot(n_subplots, 2, 1);
  hold on;
  l1 = plot(real(input));
  l2 = plot(imag(input));
  grid(ax, 'on');
  hold off;
  legend([l1; l2], 'Real', 'Imaginary');
  ylim([-1  1]);
  xlabel('Time')
  ylabel('Signal Level')
  title('Input Time Series')

  ax = subplot(n_subplots, 2, 2);
  hold on;
  l1 = plot(real(inv));
  l2 = plot(imag(inv));
  grid(ax, 'on');
  % plot_block_boundaries(ax, n_blocks, block_size-2*backward_overlap);
  hold off
  legend([l1; l2], 'Real', 'Imaginary');
  ylim([-1  1]);
  xlabel('Time')
  ylabel('Signal Level')
  title('Inverted Time Series')

  diff = input - inv;
  ax = subplot(n_subplots, 2, [3 4]);
  plot(abs(diff))
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
  plot(20*log10(abs(input_fft) + 1e-13));
  % plot(abs(input_fft));
  grid(ax, 'on');
  xlabel('Frequency bin')
  ylabel('Power (dB)')
  title('Input Power Spectrum')

  ax = subplot(n_subplots, 2, 6);
  plot(20*log10(abs(inv_fft) + 1e-13));
  % plot(abs(inv_fft));
  grid(ax, 'on');
  xlabel('Frequency bin')
  ylabel('Power (dB)')
  title('Inverted Power Spectrum')

  ax = subplot(n_subplots, 2, [7 8]);
  plot(10*log10(abs(abs(input_fft).^2 - abs(inv_fft).^2) + 1e-13));
  grid(ax, 'on');
  xlabel('Frequency bin')
  ylabel('Power (dB)')
  title('Difference between Input and Inverted Power Spectrum')

end

function res = temporal_performance(a, b)
  diff = a - b;
  mean_diff = mean(abs(diff));
  max_diff = max(abs(diff));
  sum_diff = sum(abs(diff));
  res = [mean_diff, max_diff, sum_diff];
end


function res = spectral_performance(a, fft_length)
  err = ErrorAnalysis;
  a_fft = abs(fft(a, fft_length)./fft_length).^2;
  res = [err.max_spurious_power(a_fft),...
         err.total_spurious_power(a_fft),...
         err.mean_spurious_power(a_fft)];
end
