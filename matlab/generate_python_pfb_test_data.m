function generate_python_pfb_test_data ()
  % Quantify the effect introducing overlap save has on processing blocks of data.
  config = default_config()
  config.n_chan = 8;
  % config.fir_filter_path = fullfile(config.config_dir, 'Prototype_FIR.4-3.8.80.mat');
  config.fir_filter_path = fullfile(config.config_dir, 'Prototype_FIR.4-3.8.32.mat');
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

  deripple = struct('apply_deripple', 1);
  sample_offset = 1;

  function overlap = calc_overlap (fft_length)
    overlap = 32;
  end

  forward_overlap = calc_overlap(config.input_fft_length);
  backward_overlap = normalize(config.os_factor, forward_overlap)*config.n_chan;

  win = PFBWindow;
  window_function = win.tukey_factory(config.input_fft_length, forward_overlap);
  % window_function = @win.no_window;

  jump = block_size - 2*backward_overlap;
  offsets(1) = jump + backward_overlap + filt_offset;

  output_file_name = sprintf('%%s.deripple_%d.overlap_%d.window_%s.dump', deripple.apply_deripple, forward_overlap, get_function_name(window_function));

  res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                           config.input_fft_length, n_bins,...
                           @complex_sinusoid,...
                           {frequencies, phases, bin_offset}, @polyphase_analysis, {1},...
                           @polyphase_synthesis,...
                           {deripple, sample_offset, @calc_overlap, window_function},...
                           config.data_dir, 1, sprintf(output_file_name, 'complex_sinusoid'));

  res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                          config.input_fft_length, n_bins,...
                          @time_domain_impulse,...
                          {offsets, widths}, @polyphase_analysis, {1},...
                          @polyphase_synthesis, ...
                          {deripple, sample_offset, @calc_overlap, window_function},...
                          config.data_dir, 1, sprintf(output_file_name, 'time_domain_impulse'));
end
