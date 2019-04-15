function filt_coeff = read_fir_filter_coeff (file_path)
  filter_struct = load(file_path);
  filt_coeff = transpose(filter_struct.h);
end
