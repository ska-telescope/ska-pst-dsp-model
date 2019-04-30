function overlap_effect()
  % Quantify the effect introducing overlap save has on processing blocks of data.
  config_struct = struct();
  config_struct.dtype = 'single';
  config_struct.header_file_path = './../config/default_header.json';
  config_struct.fir_filter_path = './../config/Prototype_FIR.144.mat'; % 1

  n_blocks = 5;
  os_factor = struct('nu', 8, 'de', 7);
  n_chan = 256;
  input_fft_length = 128;
  block_size = normalize(os_factor, input_fft_length)*n_chan;  % this is also the output_fft_length
  n_bins = n_blocks*block_size;

  test_vector_dir = './../data';
  if ~exist(test_vector_dir, 'dir')
    mkdir(test_vector_dir)
  end

  pos = 0.0001;
  frequencies = [floor(pos*n_bins)];
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
  % factors = 0:2:128;
  factors = 128;
  % factors = 0:4:16;
  overlaps = [];
  mean_diff = [];
  max_diff = [];
  sum_diff = [];
  for d = factors
    calc_overlap_handler = overlap_factory(d);
    forward_overlap = calc_overlap_handler(input_fft_length);
    backward_overlap = normalize(os_factor, forward_overlap)*n_chan;
    % backward_overlap = calc_overlap_handler(block_size);
    res = test_data_pipeline(config_struct, n_chan, os_factor,...
                      input_fft_length, n_bins,...
                      @complex_sinusoid,...
                      {frequencies, phases, bin_offset}, @polyphase_analysis, {1},...
                      @polyphase_synthesis_alt, ...
                      {deripple, sample_offset, calc_overlap_handler},...
                      test_vector_dir);

    data = res{2};

    size_inv = size(data{3});
    ndat_inv = size_inv(3);

    sim_squeezed = squeeze(data{1}(1, 1, :));
    inv_squeezed = squeeze(data{3}(1, 1, :));

    fir_offset = 72;
    % fir_offset = 0;

    sim_squeezed = sim_squeezed(backward_overlap+fir_offset+1:end);
    sim_squeezed = sim_squeezed(1:ndat_inv);
    inv_squeezed = inv_squeezed(1:ndat_inv);
    diff_squeezed = inv_squeezed - sim_squeezed;

    % xcorr = fft(sim_squeezed) .* conj(fft(inv_squeezed));
    n_subplots = 4;
    fig = figure;
    ax = subplot(n_subplots, 1, 1);
    hold on;
    l1 = plot(real(sim_squeezed));
    l2 = plot(imag(sim_squeezed));
    grid(ax, 'on');
    % plot_block_boundaries(ax, n_blocks, block_size);
    % plot_block_boundaries(ax, n_blocks, block_size-2*backward_overlap);
    hold off;
    legend([l1; l2], "Real", "Imaginary");
    ylim([-1  1]);

    title(sprintf("%d blocks, forward overlap: %d", n_blocks, forward_overlap));
    ax = subplot(n_subplots, 1, 2);
    hold on;
    l1 = plot(real(inv_squeezed));
    l2 = plot(imag(inv_squeezed));
    grid(ax, 'on');
    plot_block_boundaries(ax, n_blocks, block_size-2*backward_overlap);
    hold off
    legend([l1; l2], "Real", "Imaginary");
    ylim([-1  1]);

    ax = subplot(n_subplots, 1, 3);
    plot(abs(diff_squeezed))
    grid(ax, 'on');


    ax = subplot(n_subplots, 1, 4);
    plot(abs(diff_squeezed));
    grid(ax, 'on');
    set(ax, 'YScale', 'log');
    %
    % fprintf('mean of sim=%f\n', mean(abs(sim_squeezed)));
    % fprintf('mean of inv=%f\n', mean(abs(inv_squeezed)));
    % fprintf('mean of difference=%f\n', mean(abs(diff_squeezed)));
    % fprintf('sum of difference=%f\n', sum(abs(diff_squeezed)));
    overlaps = [overlaps forward_overlap];
    mean_diff = [mean_diff mean(abs(diff_squeezed))];
    max_diff = [max_diff max(abs(diff_squeezed))];
    sum_diff = [sum_diff sum(abs(diff_squeezed))];
    saveas(fig, sprintf('./../products/overlap_save.%d.png', forward_overlap));
  end
  fig = figure;
  prod_subplots = 3;
  ax = subplot(prod_subplots, 1, 1);
  scatter(overlaps, mean_diff, 'o', 'MarkerFaceColor', 'b');
  title('Mean difference vs overlap length');
  grid(ax, 'on');

  ax = subplot(prod_subplots, 1, 2);
  scatter(overlaps, max_diff, 'o', 'MarkerFaceColor', 'b');
  set(ax, 'YScale', 'log')
  title('Max difference vs overlap length');
  grid(ax, 'on');

  ax = subplot(prod_subplots, 1, 3);
  scatter(overlaps, sum_diff./n_blocks, 'o', 'MarkerFaceColor', 'b');
  title('Sum (per block) of difference vs overlap length');
  grid(ax, 'on');
  saveas(fig, './../products/overlap_effect.png');
end

function plot_block_boundaries(ax, n_blocks, block_size)
  for block_bound=1:n_blocks-1
    x = block_bound*block_size;
    l = line([x, x], get(ax,'YLim'), "Color", [0 0 0 0.3], 'LineWidth', 1.5);
  end
end
