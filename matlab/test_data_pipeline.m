function res = test_data_pipeline(...
    config_struct,...
    n_chan, os_factor,...
    input_fft_length,...
    n_bins,...
    fir_offset_direction,...
    test_vector_handler,...
    test_vector_handler_args,...
    analysis_handler,...
    analysis_handler_args,...
    synthesis_handler,...
    synthesis_handler_args,...
    output_dir,...
    n_pol_,...
    output_file_name_...
)
  % Generate single channel test vectors, channelize it, and then synthesize
  % fine channels. This function is a utility function used in :func:`current_performance`.
  %
  % Args:
  %   config_struct (struct): configuration struct, as returned from a function
  %     like :func:`default_config`
  %   n_chan (int): number of fine channels to create from single channel input
  %   os_factor (struct): rational number struct representing oversampling factor.
  %   input_fft_length (int): fft length to use on fine channels in synthesis
  %   n_bins (int): number of data points to generate
  %   test_vector_handler (handle): function handle for generating test vectors.
  %     Expects ``{n_bins}`` input parameters.
  %   test_vector_handler_args (cell): Any additional arguments for ``test_vector_handler``
  %   analysis_handler (handle): function handle for channelizing data/performing
  %     polyhase analysis. Expects ``{in, fir_filter_coeff, n_chan, os_factor}``
  %     input parameters.
  %   analysis_handler_args (cell): Any additional arguments for ``analysis_handler``
  %   synthesis_handler (handle): function handle for synthesizing channelized data.
  %     Expects ``{in, input_fft_length, os_factor}`` input parameters.
  %   synthesis_handler_args (cell): Any additional arguments for ``synthesis_handler``
  %   output_dir (string): directory in which to dump output data files
  %   n_pol_ (int): Optional. Number of polarization copies to generate. Defaults to 1
  %   output_file_name_ (string): Name of output file. Defaults to the name of the
  %     ``test_vector_handler`` function
  % Returns:
  %   cell:
  %     cell array containing the following elements:
  %
  %     - **file_info**: cell array of file names corresponding to files generated
  %       in this function
  %     - **data**: cell array of arrays containing input data, channelized data,
  %       and synthesized data.
  %     - **meta**: Any relevant meta data that may be useful for later stages of
  %       processing. This function populates the ``fir_offset`` field, which
  %       indicates the number of samples by which the inverted data has
  %       been shifted relative to input data due to the FIR filter.

  % test_vector_handler_args
  % analysis_handler_args
  % synthesis_handler_args
  n_pol = 1;
  if exist('n_pol_', 'var')
    n_pol = n_pol_;
  end
  output_file_name = get_function_name(test_vector_handler);
  if exist('output_file_name_', 'var')
    output_file_name = strrep(output_file_name_, '.dump', '');
  end


  dtype = config_struct.dtype;

  % load in FIR filter coefficients
  fir_filter_coeff = read_fir_filter_coeff(config_struct.fir_filter_path);
  ntaps = length(fir_filter_coeff);

  % load the default header into a struct, and then a containers.Map object.
  json_str = fileread(config_struct.header_file_path);
  default_header = struct2map(jsondecode(json_str));

  os_factor_str = sprintf('%d/%d', os_factor.nu, os_factor.de);

  % generate some impulse, either in the time or spectral domain

  impulse_data = test_vector_handler(n_bins, test_vector_handler_args{:}, dtype);
  input_data = complex(zeros(n_pol, 1, n_bins, dtype));
  for i_pol=1:n_pol
    input_data(i_pol, 1, :) = impulse_data(:);
  end
  % input_data = input_data(:, :, 43:end);
  % fprintf('test_data_pipeline: size(input_data)=');
  % size(input_data)
  % input_data_flattened = reshape(input_data, 1, numel(input_data));
  % k = find(input_data_flattened)

  % plot(real(reshape(impulse_data, numel(impulse_data), 1)))
  % ax = subplot(311); plot(real(squeeze(input_data(1, 1, :)))); grid(ax, 'on');
  % ax = subplot(312); plot(real(squeeze(input_data(2, 1, :)))); grid(ax, 'on');
  % ax = subplot(313); plot(abs(input_data_flattened)); grid(ax, 'off');
  input_header = default_header;

  % save data
  % fprintf('test_data_pipeline: output_dir=%s\n', output_dir);
  input_data_file_name = sprintf('%s.dump', output_file_name);
  % fprintf('test_data_pipeline: input_data_file_name=%s\n', input_data_file_name);

  input_data_file_path = fullfile(output_dir, input_data_file_name);
  save_file(input_data_file_path, @write_dada_file, {input_data, input_header});

  % fprintf('test_data_pipeline: analysis_handler_args=%s\n', analysis_handler_args{:});
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
  synthesis_handler_args{1}.filter_coeff = fir_filter_coeff;
  synthesized = synthesis_handler(channelized, input_fft_length, os_factor, synthesis_handler_args{:});
  synthesized_header = default_header;

  % calculate the offset between input and inverted data due to the FIR filter
  fir_offset = fir_offset_direction * floor(length(fir_filter_coeff) / 2);
  %
  % synthesized = synthesized(1, 1, fir_offset:end);

  % fir_offset = 0;
  % save synthesized data
  synthesized_data_file_name = sprintf('%s.%s', func2str(synthesis_handler), input_data_file_name);
  synthesized_data_file_path = fullfile(output_dir, synthesized_data_file_name);
  save_file(synthesized_data_file_path, @write_dada_file, {synthesized, synthesized_header});

  file_info = {input_data_file_name, channelized_data_file_name, synthesized_data_file_name};
  data = {input_data, channelized, synthesized};
  meta = struct('fir_offset', fir_offset);
  res = {file_info, data, meta};

end
