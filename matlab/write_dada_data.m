function write_dada_data (file_id, data, verbose_)
  % Write data to a DADA file
  % 
  % Args:
  %   file_id (double): The DADA file's file id as generated by `fopen`
  %   data ([numeric]): The data to be written to the DADA file

  % make sure that the data characterisitcs in the header are correct
  verbose = 0;
  if exist('verbose_', 'var')
    verbose = verbose_;
  end

  size_data = size(data);
  dtype = class(data);

  if verbose
    fprintf('write_dada_data: dtype=%s\n', class(data));
  end

  if ~isreal(data)
    n_pol = size_data(1);
    n_chan = size_data(2);
    n_dat = size_data(3);
    temp = zeros(2*n_pol, n_chan, n_dat, dtype);
    for i_pol=1:n_pol
      temp(2*(i_pol-1) + 1, :, :) = real(data(i_pol, :, :));
      temp(2*(i_pol-1) + 2, :, :) = imag(data(i_pol, :, :));
    end
    data = temp;
  end

  fwrite(file_id, reshape(data, numel(data), 1), dtype);

end
