function file_info = test_data_pipeline(...
    config_struct,...
    n_chan, os_factor,...
    input_fft_length, n_bins,...
    test_vector_handler,...
    test_vector_handler_args,...
    analysis_handler,...
    analysis_handler_args,...
    synthesis_handler,...
    synthesis_handler_args,...
    output_dir...
)
  dtype = config_struct.dtype;

  % load in FIR filter coefficients
  fir_filter_coeff = read_fir_filter_coeff(config_struct.fir_filter_path);

  % load the default header into a struct, and then a containers.Map object.
  json_str = fileread(config_struct.header_file_path);
  default_header = struct2map(jsondecode(json_str));

  os_factor_str = sprintf('%d/%d', os_factor.nu, os_factor.de);

  % generate some impulse, either in the time or spectral domain

  impulse_data = test_vector_handler(n_bins, test_vector_handler_args{:}, dtype);
  input_data = complex(zeros(2, 1, n_bins, 'single'));
  input_data(1, 1, :) = impulse_data(:);
  input_data(2, 1, :) = impulse_data(:);

  % input_data_flattened = reshape(input_data, 1, numel(input_data));
  % k = find(input_data_flattened)

  % plot(real(reshape(impulse_data, numel(impulse_data), 1)))
  % ax = subplot(311); plot(real(squeeze(input_data(1, 1, :)))); grid(ax, 'on');
  % ax = subplot(312); plot(real(squeeze(input_data(2, 1, :)))); grid(ax, 'on');
  % ax = subplot(313); plot(abs(input_data_flattened)); grid(ax, 'off');
  input_header = default_header;

  % save data
  input_data_file_name = sprintf('%s.dump', func2str(test_vector_handler));
  input_data_file_path = fullfile(output_dir, input_data_file_name);
  save_file(input_data_file_path, @write_dada_file, {input_data, input_header});

  % channelize data
  channelized = analysis_handler(input_data, fir_filter_coeff, n_chan, os_factor, analysis_handler_args{:});
  channelized_header = default_header;
  input_tsamp = str2num(channelized_header('TSAMP'));
  channelized_header('TSAMP') = num2str(n_chan*normalize(os_factor, input_tsamp));
  channelized_header('OS_FACTOR') = os_factor_str;
  channelized_header('PFB_DC_CHAN') = '1';
  channelized_header('NCHAN_PFB_0') = num2str(n_chan);

  % save channelized data
  channelized_data_file_name = sprintf('%s.%s', func2str(analysis_handler), input_data_file_name);
  channelized_data_file_path = fullfile(output_dir, channelized_data_file_name);
  add_fir_filter_to_header(channelized_header, fir_filter_coeff, os_factor);
  save_file(channelized_data_file_path, @write_dada_file, {channelized, channelized_header})

  % synthesize channelized data
  synthesized = synthesis_handler(channelized, input_fft_length, os_factor, synthesis_handler_args{:});
  synthesized_header = default_header;

  % save synthesized data
  synthesized_data_file_name = sprintf('%s.%s', func2str(synthesis_handler), input_data_file_name);
  synthesized_data_file_path = fullfile(output_dir, synthesized_data_file_name);
  save_file(synthesized_data_file_path, @write_dada_file, {synthesized, synthesized_header});

  file_info = {input_data_file_name, channelized_data_file_name, synthesized_data_file_name};

end
