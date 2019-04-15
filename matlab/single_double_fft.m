function single_double_fft ()
  % Determine whether Matlab's FFT implementation computes a true single precision
  % FFT, or if it returns a double precision array even when computing the FFT
  % of a single precision array.

  size = 1024;

  x_single = rand(size, 1, 'single');
  x_double = cast(x_single, 'double');
  x_diff = abs(cast(x_single, 'double') - x_double);

  ax1 = subplot(211);
  plot(ax1, x_diff);
  grid(ax1, 'on'); xlim([0, size]); title('Difference between input')

  f_single = fft(x_single);
  f_double = fft(x_double);

  fprintf('Data type after applying FFT to single precision array: %s\n', class(f_single));
  fprintf('Data type after applying FFT to double precision array: %s\n', class(f_double));

  f_diff = abs(cast(f_single, 'double') - f_double);

  ax2 = subplot(212);
  plot(ax2, f_diff);
  grid(ax2, 'on'); xlim([0, size]); title('Difference between FFT output')

  saveas(gcf, './../products/single_double_fft.png');

end
