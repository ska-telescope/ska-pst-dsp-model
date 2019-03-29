function pipeline ()

  default_header_file_path = 'config/default_header.json';
  fir_filter_path = 'config/OS_Prototype_FIR_8.mat';

  % load in FIR filter coefficients
  fir_filter_coeff = read_fir_filter_coeff(fir_filter_path);

  % load the default header into a struct, and then a containers.Map object.
  json_str = fileread(default_header_file_path);
  default_header = struct2map(jsondecode(json_str));

  os_factor = struct('nu', 8, 'de', 7);
  n_chan = 8;
  input_fft_length = 16384;
  n_bins = 10*normalize(os_factor, input_fft_length)*n_chan;

  % generate some impulse, either in the time or spectral domain
  pos = 0.1;
  frequencies = [floor(pos*n_bins)];
  phases = [pi/4];
  sinusoid = complex_sinusoid(n_bins, frequencies, phases, 0.1);
  input_data = complex(zeros(2, 1, n_bins, 'single'));
  input_data(1, 1, :) = sinusoid;
  input_data(2, 1, :) = sinusoid;
  input_header = default_header;
  input_header('FREQ_LOC') = num2str(pos);

  % save data
  input_data_file_name = sprintf('complex_sinusoid.%s.dump', num2str(pos));
  input_data_file_path = fullfile('data', input_data_file_name);
  save_file(input_data_file_path, @write_dada_file, {input_data, input_header});

  % channelize data
  channelized = polyphase_analysis_alt(input_data, fir_filter_coeff, n_chan, os_factor);
  channelized_header = default_header;
  input_tsamp = str2num(channelized_header('TSAMP'));
  channelized_header('TSAMP') = num2str(n_chan*normalize(os_factor, input_tsamp));
  channelized_header('PFB_DC_CHAN') = '1';

  % save channelized data
  channelized_data_file_name = sprintf('%s.%s', 'channelized', input_data_file_name);
  channelized_data_file_path = fullfile('data', channelized_data_file_name);
  save_file(channelized_data_file_path, @write_dada_file, {channelized, channelized_header})

  % synthesize channelized data
  synthesized = polyphase_synthesis_alt(channelized, input_fft_length, os_factor);
  synthesized_header = default_header;

  % save synthesized data
  synthesized_data_file_name = sprintf('%s.%s', 'synthesized', input_data_file_name);
  synthesized_data_file_path = fullfile('data', synthesized_data_file_name);
  save_file(synthesized_data_file_path, @write_dada_file, {synthesized, synthesized_header})

end
