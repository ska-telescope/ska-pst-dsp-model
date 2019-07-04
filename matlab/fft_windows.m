function fft_windows()
  % deprecated
  fig = figure('Position', [10, 10, 1000, 1000]);
  ax = subplot(1, 1, 1);
  npoints = 1024;
  discard = 256;
  win = PFBWindow();
  indat = ones(npoints, 1);
  hold on;
  l1 = plot(win.tukey_factory(npoints, discard)(indat));
  l2 = plot(win.fedora_factory(npoints, discard, 2.0)(indat));
  l3 = plot(win.top_hat_factory(npoints, discard)(indat));
  l4 = plot(win.hann_factory(npoints)(indat));
  legend([l1; l2; l3; l4], 'Tukey', 'Fedora', 'Top Hat', 'Hann');
  hold off;
  xlabel('Samples')
  grid on;
  title('FFT Window functions')
  saveas(fig, './../products/fft_windows.png')
end
