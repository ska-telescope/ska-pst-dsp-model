function save_file(file_path, handler, args)
  % open up a file, perform some action on it (via handler), and then close it up.
  %
  % Example:
  %
  % .. code-block::
  %
  %   >> save_file('path/to/dada.dump', @write_dada_file, {1}); % {1} is for verbose
  %
  % Args:
  %   file_path (string): Path to file
  %   handler (handle): Some some function handle that operates on file id's.
  %   args (cell): cell array containing any additional arguments to pass to
  %     handler

  file_id = fopen(file_path, 'w');
  handler(file_id, args{:});
  fclose(file_id);
end
