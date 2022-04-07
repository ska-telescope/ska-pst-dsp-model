pl=2;  %to enable plottint pl=1
%c=fircls1(191,1/15.115,.001,.0015);  %-3dB bandedge stopband edge 0.666
%c=fircls1(191,1/15.96,.001,.0002);   %-6dB bandedge stopband edge 0.666
c=fircls1(191,1/12.2, .002,.0002);    %flat to bandedge stopband at 0.8333
fvtool(c);

% 192 = 16 * 12

if (pl==1)

    figure(3)
    fcl=fft([c c*0 c*0 c*0]);
    
    plot((0:47)/48,db(fcl(1:48)))
    hold on
    xline(.5); 
    xline(0.6666);
    xline(.8333); 
   
    ylabel ('Magnitude (dB)','FontSize',14)
    title ('Frequency response','FontSize',14)
    hold off

end

cl=interpft(c,12*256);

if (pl==2)
    
  cl = cl / sum(cl);  % normalize
  
  n_taps_per_chan = 12;
  n_chan = 256;
  n_taps = n_chan * n_taps_per_chan;

  factor = (191+1)/n_taps_per_chan;
  
  wo = 1/12.2;   % passband cutoff
  os = 8/7;      % hypothetical oversampling
  wt = os * wo;  % hypothetical stopband edge

  ds = .0002;
  dBs = 20*log10(ds);

  [H0,W] = freqz (cl, 1, n_taps);

  %Rescaling the frequency axis
  W = W/pi;

  Fp=wo*factor/n_chan;
  Fs=wt*factor/n_chan;
  
    % Filter Transfer Function specs
    Ap = ds;
    As = dBs;
  
    fprintf('design_PFB: cut-off frequency: %f\n', Fp);
    fprintf('design_PFB: stop-band frequency: %f\n', Fs);

    fig = figure;
    subplot(3,1,1)
    plot (W, abs(H0), 'LineWidth', 1.5);
    axis ([0 3.5*Fp -0.15 1.15]);
    title(sprintf('Transfer Function of the Prototype Filter with %d taps', n_taps));
    grid on; box on;

    subplot(3,1,2)
    hold on;
    plot (W, 20*log10(abs(H0)));
    log_Ap_min = 20*log10(1-Ap);
    log_Ap_max = 20*log10(1+Ap);
    plot([0 Fp], [log_Ap_min log_Ap_min],'k-.','LineWidth',1);
    plot([0 Fp], [log_Ap_max log_Ap_max],'k-.','LineWidth',1);
    hold off;
    
    log_Ap_min = 20*log10(1-5*Ap);
    log_Ap_max = 20*log10(1+5*Ap);

    % axis ([0 1.5*Fp -1000*Ap 1000*Ap]);
    xlim([0 0.5*(Fp+Fs)]);
    title ('Passband')
    grid on; box on;
    %
    subplot (3,1,3);
    hold on;
    plot (W, 20*log10(abs(H0)));
    plot([Fs 1], [As As],'r-','LineWidth',1);
    hold off;
    axis ([0.5*Fs 4*Fp (As-10) 3]);
    title ('Stopband')
    grid on; box on;


end
