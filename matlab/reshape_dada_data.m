function reshaped = reshape_dada_data(data, n_dim, n_pol, n_chan, verbose_)
  % Reshape one-dimensional TFP-ordered data from a DADA file
  %
  % Args:
  %   data: one-dimensional array of data as returned by fread
  %   verbose_ (bool): Optional. Verbosity flag. Defaults to false.
  % Returns:
  %   reshaped: data(P,F,T)

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

  % input data are in TFP order; reshape returns data(P,F,T)
  reshaped = reshape(data, n_pol, n_chan, []);
  % size(reshaped)
end

