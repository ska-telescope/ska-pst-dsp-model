function spectral_analysis ()
  err = ErrorAnalysis;
  config = default_config()

  n_blocks = 2;
  block_size = normalize(config.os_factor, config.input_fft_length)*config.n_chan;
  n_bins = n_blocks*block_size;

  pos = 0.0001;
  frequencies = [floor(pos*n_bins)];
  frequencies = [19]
  phases = [pi/4];
  bin_offset = 0.0;

  meta_struct = struct();

  deripple = struct('apply_deripple', 1);

  function overlap = calc_overlap (config.input_fft_length)
    overlap = round(config.input_fft_length / 4);
  end

  sample_offset = 1
  % polyphase_analysis_alt is Ian Morrison's code
  % polyphase_analysis is John Bunton's code
  % res = test_data_pipeline(config, config.n_chan, config.os_factor,...
  %                   config.input_fft_length, n_bins,...
  %                   @complex_sinusoid,...
  %                   {frequencies, phases, bin_offset}, @polyphase_analysis, {1},...
  %                   @polyphase_synthesis_alt, ...
  %                   {deripple, sample_offset, @calc_overlap}, ...
  %                   config.data_dir);

  res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                    config.input_fft_length, n_bins,...
                    @complex_sinusoid_fft,...
                    {frequencies(1), phases(1)}, @polyphase_analysis, {1},...
                    @polyphase_synthesis_alt, ...
                    {deripple, sample_offset, @calc_overlap}, ...
                    config.data_dir);


  data = res{2};
  meta = res{3};

  size_inv = size(data{3});
  ndat_inv = size_inv(3);

  sim_squeezed = squeeze(data{1}(1, 1, :));
  inv_squeezed = squeeze(data{3}(1, 1, :));

  total_overlap = normalize(config.os_factor, calc_overlap(config.input_fft_length))*config.n_chan;
  total_overlap = total_overlap + meta.fir_offset;

  sim_squeezed = sim_squeezed(total_overlap+1:end);
  sim = sim_squeezed(1:ndat_inv);
  inv = inv_squeezed(1:ndat_inv);

  sim_fft = fft(sim) ./ length(sim);  % normalize the fft
  inv_fft = fft(inv) ./ length(inv);  % normalize the fft

  fig = plot_spectral_analysis(sim, sim_fft, inv, inv_fft);

  max_inv = max(abs(inv_fft));
  max_sim = max(abs(sim_fft));
  argmax_inv = err.argmax(abs(inv_fft));
  argmax_sim = err.argmax(abs(sim_fft));
  max_spur_inv = err.max_spurious_power(abs(inv_fft));
  max_spur_sim = err.max_spurious_power(abs(sim_fft));
  total_spur_inv = err.total_spurious_power(abs(inv_fft));
  total_spur_sim = err.total_spurious_power(abs(sim_fft));

  fprintf('Max of inverted data : %f\n', max_inv);
  fprintf('Max of input data : %f\n', max_sim);
  fprintf('Argmax of inverted data : %f\n', argmax_inv);
  fprintf('Argmax of input data : %f\n', argmax_sim);
  fprintf('Max spurious power of inverted data : %f\n', max_spur_inv);
  fprintf('Max spurious power of input data : %f\n', max_spur_sim);
  fprintf('Total spurious power of inverted data : %f\n', total_spur_inv);
  fprintf('Total spurious power of input data : %f\n', total_spur_sim);
end

function db = db(a)
  db = 20*log10(a);
end


function fig = plot_spectral_analysis(sim, sim_fft, inv, inv_fft)
  fig = figure('Position', [10, 10, 1200, 800]);
  n_subplots = 4;
  sim_idx = 1;


  ax = subplot(n_subplots, 2, sim_idx);
  hold on;
  l1 = plot(real(sim));
  l2 = plot(imag(sim));
  hold off;
  ylim([-1 1]);
  legend([l1; l2], 'Real', 'Imaginary')
  grid(ax, 'on');
  xlabel('Time');
  ylabel('Signal level (arbitrary units)');
  title('Input data');

  ax = subplot(n_subplots, 2, sim_idx+1);
  plot(db(abs(fftshift(sim_fft)) + 1e-13));
  grid(ax, 'on');
  xlabel('Frequency bin')
  ylabel('Power (dB)');
  title('Power of input data');

  inv_idx = 3;

  ax = subplot(n_subplots, 2, inv_idx);
  hold on;
  l1 = plot(real(inv));
  l2 = plot(imag(inv));
  hold off;
  ylim([-1 1]);
  legend([l1; l2], 'Real', 'Imaginary')
  grid(ax, 'on');
  xlabel('Time');
  ylabel('Signal level (arbitrary units)');
  title('Inverted data');

  ax = subplot(n_subplots, 2, inv_idx + 1);
  plot(db(abs(fftshift(inv_fft)) + 1e-13));
  grid(ax, 'on');
  xlabel('Frequency bin');
  ylabel('Power (dB)');
  title('Power of inverted data');

  diff_idx = 5;
  diff = sim - inv;
  ax = subplot(n_subplots, 2, diff_idx);
  plot(real(diff));
  xlabel('Time');
  ylabel('Signal level (arbitrary units)');
  title(sprintf('Real Difference of input and inverted time series\nmean=%f', mean(real(diff))));

  ax = subplot(n_subplots, 2, diff_idx + 1);
  plot(imag(diff));
  xlabel('Time');
  ylabel('Signal level (arbitrary units)');
  title(sprintf('Imaginary Difference of input and inverted time series\nmean=%f', mean(imag(diff))));



  diff_idx = 7;
  diff_fft = abs(sim_fft) - abs(inv_fft);
  ax = subplot(n_subplots, 2, [diff_idx diff_idx+1]);
  plot(db(abs(fftshift(diff_fft)) + 1e-13));
  grid(ax, 'on');
  xlabel('Frequency bin');
  ylabel('Power (dB)');
  title('Power of difference of input and inverted FFTs');

  % ax = subplot(n_subplots, 2, diff_idx + 1);
  % plot(angle(sim_fft .* conj(inv_fft)));
  % grid(ax, 'on');
  % xlabel('Frequency bin');
  % ylabel('Radians');
  % title('Phase of input and inverted cross correlation');

end
