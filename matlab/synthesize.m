function synthesize (varargin)
  % This function is meant to be used as a stand alone executable.
  % It takes as input a DADA dump file, and synthesizes it.
  % @method synthesize
  % @param {string} input_file_path - The path to the input data.
  % @param {number} input_fft_length - The path to the input data.
  % @param {string} output_dir - The directory where the synthesized output
  %   dada file will be saved.
  % @param {string} output_file_name - The name of the output dada file.
  % @param {string} verbose -  Optional verbosity flag.

  p = inputParser;
  addRequired(p,'input_file_path', @ischar);
  addRequired(p,'input_fft_length', @ischar);
  addRequired(p,'output_file_name', @ischar);
  addOptional(p,'output_dir', './', @ischar);
  addOptional(p,'verbose', '0', @ischar);

  parse(p, varargin{:});

  input_file_path = p.Results.input_file_path;
  input_fft_length = str2num(p.Results.input_fft_length);
  output_dir = p.Results.output_dir;
  output_file_name = p.Results.output_file_name;
  verbose = str2num(p.Results.verbose);

  % load in input data
  if verbose
    fprintf('synthesize: loading input data\n');
  end
  file_id = fopen(input_file_path);
  data_header = read_dada_file(file_id);
  fclose(file_id);
  input_data = data_header{1};
  input_header = data_header{2};
  if verbose
    fprintf('synthesize: loading input data complete\n');
  end

  channels = str2num(input_header('NCHAN'));

  os_factor_str = input_header('OS_FACTOR');
  os_factor_split = split(os_factor_str, '/');
  os_factor = struct('nu', str2num(os_factor_split{1}),...
                     'de', str2num(os_factor_split{2}));


  if verbose
    fprintf('synthesize: synthesizing input data\n')
  end

  synthesized_header = input_header;
  input_tsamp = str2num(input_header('TSAMP'));
  synthesized_header('TSAMP') = num2str(input_tsamp / normalize(os_factor, 1) / channels);
  synthesized = polyphase_synthesis_alt(input_data, input_fft_length, os_factor);

  if verbose
    fprintf('synthesize: synthesis complete\n')
  end

  if verbose
    fprintf('synthesize: saving synthesized data\n')
  end

  % fullfile behaves the same as Python's os.path.join
  output_file_path = fullfile(output_dir, output_file_name);
  file_id = fopen(output_file_path, 'w');
  write_dada_file(file_id, synthesized, synthesized_header);
  fclose(file_id);

  if verbose
    fprintf('synthesize: saving synthesized data complete\n')
  end
end
