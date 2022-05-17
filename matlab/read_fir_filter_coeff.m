function filt_coeff = read_fir_filter_coeff(file_path)
  % Read in some FIR filter coefficients from a Matlab ``.mat`` file.
  % The ``.mat`` file must have either a ``'h'`` or ``'hQ'`` field that contains
  % the filter coefficients.
  %
  % Args:
  %   file_path (string): Path to .mat file
  % Returns:
  %   [numeric]: filter coefficents

  filter_struct = load(file_path);
  if isfield(filter_struct, 'hQ')
    filt_coeff = transpose(filter_struct.hQ);
  else
    filt_coeff = transpose(filter_struct.h);
  end
end
