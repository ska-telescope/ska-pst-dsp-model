function test_pipeline ()

  input_file_path = './../data/simulated_pulsar.noise_0.0.nseries_10.ndim_2.dump';
  fir_filter_path = './../config/OS_Prototype_FIR_8.mat';

  file_id = fopen(input_file_path); data_header = read_dada_file (file_id); fclose(file_id);
  data = data_header{1};
  header = data_header{2};
  input_tsamp = str2num(header('TSAMP'));
  fir_filter_coeff = read_fir_filter_coeff(fir_filter_path);

  n_pol = str2num(header('NPOL'));

  n_chan = 8;
  os_factor = struct('nu', 8, 'de', 7);

  header('TSAMP') = num2str(normalize(os_factor, input_tsamp) * n_chan);
  header('PFB_DC_CHAN') = '1';
  header('OS_FACTOR') = sprintf('%d/%d', os_factor.nu, os_factor.de);
  add_fir_filter_to_header(header, fir_filter_coeff, os_factor);
  size_data = size(data);
  n_dat = size_data(3);
  n_dat_process = floor(0.2*n_dat);

  channelized = polyphase_analysis_alt(data(:, :, 1:n_dat_process), fir_filter_coeff, n_chan, os_factor);
  input_fft_length = 32768;
  inverted = polyphase_synthesis(channelized, input_fft_length, os_factor);

  ax = subplot(211);
  plot(abs(reshape(inverted, numel(inverted), 1)));
  grid(ax, 'on');

  ax = subplot(212);
  data_subset = data(:, :, 1:n_dat_process);
  plot(abs(reshape(data_subset, numel(data_subset), 1)));
  grid(ax, 'on');

  saveas(gcf, './../products/test_pipeline.png');

end
