function generate_test_vector(varargin)
  % This function is meant to be used as a stand alone executable.
  % It creates a DADA dump file
  %
  % Uses ``inputParser``
  %
  % Example:
  %
  % .. code-block::
  %
  %   ./generate_test_vector complex_sinusoid 1000 1,0.25,0.1 single 1 ./ complex_sinusoid.dump 1
  %
  %   generate_test_vector('complex_sinusoid', '1000', '0.5,0.25,0.1', 'single', '1', '../config/default_header.json', 'complex_sinusoid.dump', verbose='1')
  %
  %
  % varargin:
  %   - handler_name: name of handler to use to create function
  %   - params: comma separate list of inputs
  %   - n_bins: number of bins per polarization
  %   - dtype: type of data to generate
  %   - n_pol: number of polarizations to generate
  %   - output_dir: The directory where the synthesized output
  %     dada file will be saved.
  %   - output_file_name: The name of the output dada file.
  %   - verbose:  Optional verbosity flag.
  %
  % Args:
  %   varargin (cell): Inputs to parsed.


  handler_map = containers.Map();
  handler_map('complex_sinusoid') = @complex_sinusoid;
  handler_map('time_domain_impulse') = @time_domain_impulse;


  p = inputParser;
  addRequired(p, 'handler_name', @ischar);
  addRequired(p, 'n_bins', @ischar);
  addRequired(p, 'params', @ischar);
  addRequired(p, 'dtype', @ischar);
  addRequired(p, 'n_pol', @ischar);
  addRequired(p, 'header_template', @ischar);
  addRequired(p, 'output_file_name', @ischar);
  addOptional(p, 'output_dir', './', @ischar);
  addOptional(p, 'verbose', '0', @ischar);

  parse(p, varargin{:});

  handler_name = p.Results.handler_name;
  fprintf('generate_test_vector: %s\n', handler_name);
  n_bins = str2num(p.Results.n_bins);
  params = p.Results.params;
  dtype = p.Results.dtype;
  n_pol = str2num(p.Results.n_pol);
  
  header_template = p.Results.header_template;
  output_dir = p.Results.output_dir;
  output_file_name = p.Results.output_file_name;
  verbose = str2num(p.Results.verbose);

  if verbose
     fprintf('generate_test_vector: handler_name=%s\n', handler_name);
     fprintf('generate_test_vector: n_bins=%d\n', n_bins);
     fprintf('generate_test_vector: params=%s\n', params);
     fprintf('generate_test_vector: dtype=%s\n', dtype);
     fprintf('generate_test_vector: n_pol=%d\n', n_pol);
     fprintf('generate_test_vector: header_template=%s\n', header_template);
     fprintf('generate_test_vector: output_dir=%s\n', output_dir);
     fprintf('generate_test_vector: output_file_name=%s\n', output_file_name);
     fprintf('generate_test_vector: verbose=%d\n', verbose);
  end

  params_split = strsplit(params, ',');
  params = {};
  for i=1:length(params_split)
    params{i} = str2num(params_split{i});
  end
  params{1} = [n_bins*params{1}];
  params{2} = [params{2}];


  json_str = fileread(header_template);
  default_header = struct2map(jsondecode(json_str));

  output_data = complex(zeros(n_pol, 1, n_bins, dtype));
  handler = handler_map(handler_name);
  test_vector = handler(n_bins, params{:}, dtype);
  for i_pol=1:n_pol
    output_data(i_pol, 1, :) = test_vector;
  end

  if verbose
    fprintf('generate_test_vector: saving data\n')
  end

  % fullfile behaves the same as Python's os.path.join
  output_file_path = fullfile(output_dir, output_file_name);
  file_id = fopen(output_file_path, 'w');
  write_dada_file(file_id, output_data, default_header);
  fclose(file_id);

  if verbose
    fprintf('generate_test_vector: saving data complete\n')
  end
end
