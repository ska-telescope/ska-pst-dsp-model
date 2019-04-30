function spectral_analysis ()
  err = ErrorAnalysis;

  config_struct = struct();
  config_struct.dtype = 'single';
  config_struct.header_file_path = './../config/default_header.json';
  % config_struct.fir_filter_path = './../config/Prototype_FIR.8.80.mat'; % 10 taps per channel
  % config_struct.fir_filter_path = './../config/Prototype_FIR.16.160.mat'; % 10 taps per channel
  config_struct.fir_filter_path = './../config/Prototype_FIR.256.2560.mat'; % 10 taps per channel

  n_blocks = 4;
  % os_factor = struct('nu', 1, 'de', 1);
  os_factor = struct('nu', 8, 'de', 7);
  % os_factor = struct('nu', 4, 'de', 3);
  n_chan = 256;
  input_fft_length = 128;
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

  deripple = struct('apply_deripple', 1);

  function overlap = calc_overlap (input_fft_length)
    overlap = round(input_fft_length / 8);
    % overlap = 0;
  end

  sample_offset = 1
  % polyphase_analysis_alt is Ian Morrison's code
  % polyphase_analysis is John Bunton's code
  res = test_data_pipeline(config_struct, n_chan, os_factor,...
                    input_fft_length, n_bins,...
                    @time_domain_impulse,...
                    {offsets, widths}, @polyphase_analysis, {1},...
                    @polyphase_synthesis_alt, ...
                    {deripple, sample_offset, @calc_overlap}, ...
                    test_vector_dir);

  data = res{2};
  meta = res{3};

  size_inv = size(data{3});
  ndat_inv = size_inv(3);

  total_overlap = normalize(os_factor, calc_overlap(input_fft_length))*n_chan;
  total_overlap = total_overlap + meta.fir_offset;

  sim_squeezed = squeeze(data{1}(1, 1, :));
  inv_squeezed = squeeze(data{3}(1, 1, :));
  sim_squeezed = sim_squeezed(total_overlap+1:end);
  sim = sim_squeezed(1:ndat_inv);
  inv = inv_squeezed(1:ndat_inv);

  xcorr = fft(sim) .* conj(fft(inv));
  lag = ifft(xcorr);
  [valmax, argmax] = max(lag);
  fprintf('Lag: %d\n', argmax);

  fig = plot_temporal_analysis(sim, inv, xcorr);
  %
  % meta.fir_offset
  %
  % sim_squeezed = sim_squeezed(meta.fir_offset+1:end);
  % sim = sim_squeezed(1:ndat_inv);
  % inv = inv_squeezed(1:ndat_inv);
  %
  % sim_fft = fft(sim);
  % inv_fft = fft(inv);
  %
  % fig = plot_spectral_analysis(sim, sim_fft, inv, inv_fft);
  %
  % argmax_inv = err.argmax(abs(inv_fft));
  % argmax_sim = err.argmax(abs(sim_fft));
  % max_spur_inv = err.max_spurious_power(abs(inv_fft));
  % max_spur_sim = err.max_spurious_power(abs(sim_fft));
  % total_spur_inv = err.total_spurious_power(abs(inv_fft));
  % total_spur_sim = err.total_spurious_power(abs(sim_fft));
  %
  % fprintf('Argmax of inverted data : %f\n', argmax_inv);
  % fprintf('Argmax of input data : %f\n', argmax_sim);
  % fprintf('Max spurious power of inverted data : %f\n', max_spur_inv);
  % fprintf('Max spurious power of input data : %f\n', max_spur_sim);
  % fprintf('Total spurious power of inverted data : %f\n', total_spur_inv);
  % fprintf('Total spurious power of input data : %f\n', total_spur_sim);
end


function fig = plot_temporal_analysis(sim, inv, xcorr)
  fig = figure('Position', [10, 10, 1200, 800]);
  n_subplots = 3;
  sim_idx = 1;

  ax = subplot(n_subplots, 1, sim_idx);
  hold on;
  l1 = plot(real(sim));
  l2 = plot(imag(sim));
  hold off;
  legend([l1; l2], 'Real', 'Imaginary')
  grid(ax, 'on');
  xlabel('Time');
  ylabel('Signal level (arbitrary units)');
  title('Input data');

  inv_idx = 2;

  ax = subplot(n_subplots, 1, inv_idx);
  hold on;
  l1 = plot(real(inv));
  l2 = plot(imag(inv));
  hold off;
  ylim([0, 1]);
  legend([l1; l2], 'Real', 'Imaginary')
  grid(ax, 'on');
  xlabel('Time');
  ylabel('Signal level (arbitrary units)');
  title('Inverted data');

  diff_idx = 3;
  ax = subplot(n_subplots, 1, diff_idx);
  plot(angle(xcorr));
  grid(ax, 'on');
  xlabel('Frequency bin');
  ylabel('Radians');
  title('Phase of input and inverted cross correlation');

end
