function channelize(varargin)
  % This function is meant to be used as a stand alone executable.
  % It takes as input a DADA dump file, channelizes it, and then saves it
  % as another data dump file.
  %
  % Uses ``inputParser`` to parse command line parameters
  %
  % varargin:
  %
  % - input_file_path: The path to the input data.
  % - channels: The number of channels to create
  % - os_factor_str: A string representing the oversampling
  %   factor. This should be represented as a fraction, eg `'8/7'`.
  %   To channelize with a criticall sampled PFB, use `'1/1'`.
  % - output_file_name: The name of the output dada file.
  % - output_dir: The directory where the channelized output
  %   dada file will be saved.
  % - verbose\_: Optional verbosity flag, converted to bool.
  %
  % Example:
  %
  % .. code-block::
  %
  %   ./channelize file_to_channelize.dump 8 8/7 channelized.dump ./ 1
  %
  % Args:
  %   varargin (cell): Cell array containing inputs.

  tstart = tic;
  p = inputParser;
  validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
  addRequired(p,'input_file_path', @ischar);
  addRequired(p,'channels', @ischar);
  addRequired(p,'os_factor_str', @ischar);
  addRequired(p,'fir_filter_path', @ischar);
  addRequired(p,'output_file_name', @ischar);
  addOptional(p,'output_dir', './', @ischar);
  addOptional(p,'verbose', '0', @ischar);
  addOptional(p,'use_padded', '0', @ischar);

  parse(p, varargin{:});

  input_file_path = p.Results.input_file_path;
  channels = str2num(p.Results.channels);
  os_factor_str = p.Results.os_factor_str;
  fir_filter_path = p.Results.fir_filter_path;
  output_dir = p.Results.output_dir;
  output_file_name = p.Results.output_file_name;
  verbose = str2num(p.Results.verbose);
  use_padded = str2num(p.Results.use_padded);

  % get the oversampling factor, and load into os_factor struct
  os_factor_split = split(os_factor_str, '/');
  os_factor = struct('nu', str2num(os_factor_split{1}),...
                     'de', str2num(os_factor_split{2}));

  % load in input data
  if verbose
    fprintf('channelize: input_file_path=%s\n', input_file_path);
  end
  file_id = fopen(input_file_path);
  data_header = read_dada_file(file_id);
  fclose(file_id);
  input_data = data_header{1};
  input_header = data_header{2};
  if verbose
    fprintf('channelize: loading input data complete\n');
  end

  fir_filter_coeff = read_fir_filter_coeff(fir_filter_path);
  if verbose
    fprintf('channelize: loading in FIR filter coefficients complete\n');
  end

  if verbose
    fprintf('channelize: channelizing input data\n')
  end

  channelized_header = input_header;
  input_tsamp = str2num(input_header('TSAMP'));
  channelized_header('TSAMP') = num2str(normalize(os_factor, input_tsamp) * channels);
  channelized_header('PFB_DC_CHAN') = '1';
  channelized_header('NCHAN_PFB_0') = num2str(channels);
  channelized_header('OS_FACTOR') = sprintf('%d/%d', os_factor.nu, os_factor.de);
  add_fir_filter_to_header(channelized_header, fir_filter_coeff, os_factor);

  if use_padded
    if verbose
      fprintf('channelize: using polyphase_analysis_padded\n')
    end
    channelized = polyphase_analysis_padded(input_data, fir_filter_coeff, channels, os_factor, verbose);
  else
    if verbose
      fprintf('channelize: using polyphase_analysis\n')
    end
    channelized = polyphase_analysis(input_data, fir_filter_coeff, channels, os_factor, verbose);
  end

  if verbose
    fprintf('channelize: channelization complete\n')
  end

  % fullfile behaves the same as Python's os.path.join
  if verbose
    fprintf('channelize: saving channelized data\n')
  end

  output_file_path = fullfile(output_dir, output_file_name);
  file_id = fopen(output_file_path, 'w');
  write_dada_file(file_id, channelized, channelized_header, verbose);
  fclose(file_id);

  if verbose
    fprintf('channelize: saving channelized data complete\n');
    tdelta = toc(tstart);
    fprintf('channelize: Elapsed time is %f seconds\n', tdelta);
  end
end
