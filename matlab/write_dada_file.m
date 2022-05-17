function write_dada_file(file_id, data, header, verbose_)
  % Write a DADA file
  % 
  % Args:
  %   file_id (double): The DADA file's file id as generated by `fopen`
  %   data ([numeric]): The data to be written to the DADA file
  %   header (containers.Map): The DADA header written to the DADA file

  verbose = 0;
  if exist('verbose_', 'var')
    verbose = verbose_;
  end

  write_dada_header (file_id, data, header, verbose);
  write_dada_data (file_id, data, verbose);
end

