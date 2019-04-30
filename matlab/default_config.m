function config_struct = default_config ()
  file_path = mfilename('fullpath');
  [file_dir, name, ext] = fileparts(file_path);
  [base_dir, name, ext] = fileparts(file_dir);

  config_dir = fullfile(base_dir, 'config');

  config_struct = struct();
  config_struct.config_dir = config_dir;
  config_struct.dtype = 'single';
  config_struct.header_file_path = fullfile(config_dir, 'default_header.json');
  config_struct.fir_filter_path = fullfile(config_dir, 'PST_2561_LowFilterCoefficients.mat'); % 10 taps per channel
  config_struct.os_factor = struct('nu', 4, 'de', 3);
  config_struct.n_chan = 256;
  config_struct.input_fft_length = 128;

  data_dir = fullfile(base_dir, 'data');
  if ~exist(data_dir, 'dir')
    mkdir(data_dir);
  end
  config_struct.data_dir = data_dir;
end
