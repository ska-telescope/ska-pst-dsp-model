function reshaped = reshape_dada_data(data, n_dim, n_pol, n_chan, verbose_)
  % Research DADA data, given one-dimensional data from a DADA file
  %
  % Args:
  %   data: The DADA file's file id as generated by `fopen`
  %   verbose_ (bool): Optional. Verbosity flag. Defaults to false.
  % Returns:
  %   cell: cell array containing the data and header.

  verbose = 0;
  if exist('verbose_', 'var')
    verbose = verbose_;
  end

  % fprintf ('reshape_dada_data nchan=%d npol=%d ndim=%d\n', n_chan, n_pol, n_dim);

  % size(data)
  data = reshape(data, 1, []);
  % size(data)

  if n_dim == 2
      % fprintf('reshape_dada_data converting to complex\n')
      data = data(1:2:end) + 1j*data(2:2:end);
  end

  reshaped = reshape(data, n_pol, n_chan, []);
  % size(reshaped)
end

