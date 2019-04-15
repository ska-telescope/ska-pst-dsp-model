function ret = load_file (file_path, handler, args)
  if ~exist('args', 'var')
    args = {};
  end
  file_id = fopen(file_path);
  ret = handler(file_id, args{:});
  fclose(file_id);
end
