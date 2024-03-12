function bit_histogram (filename)
  [file_id,errmsg] = fopen(filename, 'r');
  if file_id == -1
      fprintf('Could not open %s: %s\n', filename, errmsg);
      return;
  end
  hdr_size=256*256; % 64k
  fseek(file_id, hdr_size, 'bof');
  data = fread(file_id,'int16');
  fclose(file_id);
  histogram(data,'BinMethod','integers')
end
