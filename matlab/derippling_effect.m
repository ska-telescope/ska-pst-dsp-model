function derippling_effect ()
  % Attempt to quantify the effect derippling has on PFB inversion performance.
  % Generate a plot of the difference between input time domain impulse and
  % the result of PFB inversion, with and without derippling enabled, for a
  % range of FIR filter sizes.
  config_struct = struct();
  config_struct.dtype = 'single';
  config_struct.header_file_path = './../config/default_header.json';

  n_blocks = 2;
  os_factor = struct('nu', 8, 'de', 7);
  n_chan = 8;
  input_fft_length = 1024;
  block_size = normalize(os_factor, input_fft_length)*n_chan;
  n_bins = n_blocks*block_size;

  test_vector_dir = './../data';
  if ~exist(test_vector_dir, 'dir')
    mkdir(test_vector_dir)
  end


  pos = 0.25;

  offsets = [floor(pos*n_bins)];
  widths = [1];

  meta_struct = struct();
  meta_struct.impulse_position = num2str(pos);
  meta_struct.impulse_width = num2str(widths(1));

  deripple = struct('apply_deripple', 1);

  function overlap = calc_overlap (input_fft_length)
    % overlap = 32;
    % overlap = 0;
    overlap = round(input_fft_length / 8);
  end
  n_filters = 19;
  deripple_residual = zeros(n_filters, 1)
  noderipple_residual = zeros(n_filters, 1)
  ntaps = zeros(n_filters, 1)
  sample_offset = 1;

  for taps_per_chan=1:n_filters
    t = 2*n_chan*(taps_per_chan+1);
    ntaps(taps_per_chan) = t;
    config_struct.fir_filter_path = sprintf('./../config/Prototype_FIR.%d.mat', t);


    res = test_data_pipeline(config_struct, n_chan, os_factor,...
                      input_fft_length, n_bins,...
                      @time_domain_impulse,...
                      {offsets, widths}, @polyphase_analysis, {1},...
                      @polyphase_synthesis_alt, ...
                      {deripple, sample_offset, @calc_overlap},...
                      test_vector_dir);
    data = res{2};
    deripple_residual(taps_per_chan) = calc_diff(data{1}, data{3});
    deripple.apply_deripple = 0;
    res = test_data_pipeline(config_struct, n_chan, os_factor,...
                      input_fft_length, n_bins,...
                      @time_domain_impulse,...
                      {offsets, widths}, @polyphase_analysis, {1},...
                      @polyphase_synthesis_alt, ...
                      {deripple, sample_offset, @calc_overlap},...
                      test_vector_dir);
    data = res{2};
    noderipple_residual(taps_per_chan) = calc_diff(data{1}, data{3});
    deripple.apply_deripple = 1;
  end

  fig = figure;
  ax = subplot(2, 1, 1); grid(ax, 'on');
  title('Effect of derippling correction');
  hold on;
  l1 = plot(ntaps, deripple_residual, 'LineWidth', 1.5);
  l2 = plot(ntaps, noderipple_residual, 'LineWidth', 1.5);
  legend([l1; l2], 'Derippling enabled', 'Derippling disabled');
  hold off;

  ax = subplot(2, 1, 2);
  diff_residual = noderipple_residual - deripple_residual;
  plot(ntaps, diff_residual, 'LineWidth', 1.5);
  ylim([-0.01, max(diff_residual)*1.2]);
  grid(ax, 'on');

  saveas(fig, './../products/derippling_effect.png');
end

function sum_diff = calc_diff(input_data, inverted_data)
  size_inv = size(inverted_data);
  ndat_inv = size_inv(3);

  sim_squeezed = squeeze(input_data(1, 1, :));
  inv_squeezed = squeeze(inverted_data(1, 1, :));
  % [valmax_sim, argmax_sim] = max(sim_squeezed);
  % [valmax_inv, argmax_inv] = max(inv_squeezed);
  % fprintf("argmax sim=%d, max sim=%f\n", argmax_sim, valmax_sim);
  % fprintf("argmax inv=%d, max inv=%f\n", argmax_inv, valmax_inv);

  output_shift = 0;
  % output_shift = os_factor.de * (sample_offset - 1);

  sim_squeezed = sim_squeezed(output_shift+1:end);
  sim_squeezed = sim_squeezed(1:ndat_inv);
  inv_squeezed = inv_squeezed(1:ndat_inv);
  sum_sim = sum(abs(sim_squeezed));
  sum_inv = sum(abs(inv_squeezed));
  % fprintf('sum of sim=%f\n', sum_sim);
  % fprintf('sum of inv=%f\n', sum_inv);
  sum_diff = abs(sum_sim - sum_inv);
end
