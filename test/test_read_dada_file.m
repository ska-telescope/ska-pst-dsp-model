function test_read_dada_file ()
  % test the read_dada_file function on a DADA file

  fprintf('test_read_dada_file\n');

  % the following is a single channel DADA file
  % data_file_path = 'data/simulated_pulsar.noise_0.0.nseries_10.ndim_2.dump';
  % the following data file is a multichannel DADA file
  data_file_path = 'data/py_channelized.simulated_pulsar.noise_0.0.nseries_10.ndim_2.os.dump';

  file_id = fopen(data_file_path);
  data_header = read_dada_file(file_id);
  fclose(file_id);

  data = data_header{1};
  header = data_header{2};
  % to_plot = squeeze(real(data(1, 1, :)));
  % plot(to_plot);
  % xlim([-1000, length(to_plot)])

  % assert(header('HDR_SIZE') == "8192");

end
