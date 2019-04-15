function save_file (file_path, handler, args)
  file_id = fopen(file_path, 'w');
  handler(file_id, args{:});
  fclose(file_id);
end
