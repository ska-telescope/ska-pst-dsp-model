function config_struct = default_config (tele)
  file_path = mfilename('fullpath');
  [file_dir, name, ext] = fileparts(file_path);
  [base_dir, name, ext] = fileparts(file_dir);

  config_dir = fullfile(base_dir, 'config');
  test_config_file_path = fullfile(config_dir, 'test.config.json');

  config_struct = jsondecode(fileread(test_config_file_path));
  config_struct = config_struct.(tele);

  config_struct.config_dir = config_dir;
  config_struct.dtype = 'single';
  config_struct.header_file_path = fullfile(config_dir, config_struct.header_file_path);
  config_struct.fir_filter_path = fullfile(config_dir, config_struct.fir_filter_coeff_file_path);
  os_factor = strsplit(config_struct.os_factor, '/');
  config_struct.os_factor = struct('nu', str2num(os_factor{1}),...
                                   'de', str2num(os_factor{2}));
  config_struct.n_chan = config_struct.channels;

  data_dir = fullfile(base_dir, 'data');
  if ~exist(data_dir, 'dir')
    mkdir(data_dir);
  end
  config_struct.data_dir = data_dir;
end
