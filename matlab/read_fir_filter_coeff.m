function filt_coeff = read_fir_filter_coeff(file_path)
  filter_struct = load(file_path);
  if isfield(filter_struct, 'hQ')
    filt_coeff = transpose(filter_struct.hQ);
  else
    filt_coeff = transpose(filter_struct.h);
  end
end
