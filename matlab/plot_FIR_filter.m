function fig = plot_FIR_filter (n_chan, OS, h)

  sz = size(h);
  n_taps = sz(2);
  n_taps_per_chan = floor (n_taps / n_chan);
  
  h = h / sum(h);  % normalize
  
  [H0,W] = freqz (h, 1, n_taps);
  
  % Rescale the frequency axis to critically-sampled bandwidth
  W = W*n_chan/pi;
  
  % dB on the y-axis
  H0 = abs(H0);
  H0dB = 20*log10(H0);
  
  fig = figure;
  
  %
  % Linear view
  %
  subplot(3,1,1)
  plot (W, H0, 'LineWidth', 1.5);
  xlim ([0.5 2]);
  
  FontSize = 12;
  xline([1.0],'--b', 'LineWidth', 1.5);
  xline([OS],'--', 'LineWidth', 1.5);
  xline([2*OS-1],'--r', 'LineWidth', 1.5);
  title(sprintf('Transfer Function of the Prototype Filter with %d taps', n_taps));
  ylabel ('Magnitude','FontSize',FontSize)
  grid on; box on;

  %
  % Log passband
  %
  subplot(3,1,2)
  plot (W, H0dB);
  xlim([0 OS]);
  dBripple = 0.1;
  ylim([-dBripple dBripple]);
  
  xline([1.0],'--b', 'LineWidth', 1.5);
  title ('Passband')
  ylabel ('Magnitude (dB)','FontSize',FontSize)
  grid on; box on;
    
  %
  % Log stopband
  %
  subplot (3,1,3);
  plot (W, H0dB);
  xlim([1 2]);
  
  xline([OS],'--', 'LineWidth', 1.5);
  xline([2*OS-1],'--r', 'LineWidth', 1.5);
  title ('Stopband')
  ylabel ('Magnitude (dB)','FontSize',FontSize)
  xlabel ('Frequency / Nyq_{critical}','FontSize',FontSize)

  grid on; box on;
  