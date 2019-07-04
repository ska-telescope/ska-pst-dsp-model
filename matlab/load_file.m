function ret = load_file(file_path, handler, args)
  % Open up a file path, apply a handler to the file id, and then close the file.
  %
  % Example:
  %
  % .. code-block::
  %
  %   >> load_file('path/to/dada.dump', @read_dada_file, {1}); % {1} is for verbose
  %
  % Args:
  %   file_path (string): Path to file
  %   handler (handle): Some some function handle that operates on file id's.
  %   args (cell): cell array containing any additional arguments to pass to
  %     handler
  % Returns:
  %   result of call to ``handler``

  if ~exist('args', 'var')
    args = {};
  end
  file_id = fopen(file_path);
  ret = handler(file_id, args{:});
  fclose(file_id);
end
