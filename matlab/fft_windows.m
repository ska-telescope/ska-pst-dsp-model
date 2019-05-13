function fft_windows ()
  fig = figure('Position', [10, 10, 1000, 1000]);
  ax = subplot(1, 1, 1);
  npoints = 1024;
  discard = 256;
  win = PFBWindow();
  hold on;
  l1 = plot(tukey(npoints, discard));
  l2 = plot(fedora(npoints, discard, 2.0));
  l3 = plot(top_hat(npoints, discard));
  l4 = plot(hann(npoints));
  legend([l1; l2; l3; l4], 'Tukey', 'Fedora', 'Top Hat', 'Hann');
  hold off;
  xlabel('Samples')
  grid on;
  title('FFT Window functions')
  saveas(fig, './../products/fft_windows.png')
end

function window = tukey (fft_length, discard)
  window = ones(1, fft_length);
  h = transpose(hann(2*discard));
  window(1:discard) = h(1:discard);
  window(fft_length - discard+1:end) = h(discard+1:end);
end

function window = top_hat (fft_length, discard)
  window = ones(1, fft_length);
  window(:, 1:discard) = 0.0;
  window(:, fft_length-discard+1:end) = 0.0;
end


function window = fedora (fft_length, discard, fraction)
  discard = round(discard / fraction) ;
  window = ones(1, fft_length);
  window(:, 1:discard) = 0.0;
  window(:, fft_length-discard+1:end) = 0.0;
end
