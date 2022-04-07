function fir_filter_path = design_PFB_FIR_filter_alt(n_chan, os_factor, n_taps_per_chan, display_)
  % Design a FIR appropriate for polyphase filterbank.
  %
  % Example:
  %
  % .. code-block::
  %
  %   >> design_PFB_FIR_filter(256, {'nu': 4, 'de': 3}, 256*10, 0);
  %
  % Args:
  %   n_chan (numeric): number of PFB output channels
  %   os_factor (struct): oversampling factor struct
  %   n_taps_per_chan (single): Number of filter taps per channel
  %   display (bool): Optional. Whether or not to generate plots to Defaults to false.
  % Returns:
  %   string: Path to newly created ``.mat`` file contaning FIR filter coefficents.

  display = 0;
  if exist('display_', 'var')
    display = display_;
  end

  % Oversampling Factor
  OS = os_factor.nu/os_factor.de;

  % normalized number of channel
  n_chanNorm = (n_chan / os_factor.nu)*os_factor.de;
  
  wo = 1./n_chan;       % Cut-off frequency  
  dp = 0.001;   % Maximum passband deviation from 1 (passband ripple)
  
  dBs = -70;
  ds = 10^(dBs/20);    % Maximum stopband deviation from 0 (stopband ripple)

  intermediate_nchan=16;

  % Filter specs for the prototype filter
  method = 1;
  if (method == 1) % currently, only overlap-save is implemented
      
    fprintf ('design_PFB_FIR_filter_alt: optimizing for overlap-save\n');
    % John Bunton recommends this configuration for spectral overlap-save
    % flat to bandedge stopband at 0.8333
    n  = intermediate_nchan*n_taps_per_chan - 1;
    wo = 1/n_taps_per_chan;  % Cut-off frequency
    dp = 0.002;   % Maximum passband deviation from 1 (passband ripple)
    %ds = 0.0002;  % Maximum stopband deviation from 0 (stopband ripple)
    n_taps = n_taps_per_chan * n_chan;
    
  end
  
  if (method == 2) % spectral overlap-add is not implemented
      
    fprintf ('design_PFB_FIR_filter_alt: optimizing for overlap-add\n');
    % John Bunton recommends this configuration for spectral overlap-add
    % -6dB bandedge stopband edge 0.666
    n  = 191;
    wo = 1/15.96; % Cut-off frequency
    dp = 0.01;   % Maximum passband deviation from 1 (passband ripple)
    %ds = 0.0002;  % Maximum stopband deviation from 0 (stopband ripple)
    n_taps = 12 * n_chan;

  end
  
  wt = (2*OS-1)*wo;  % Stop-band frequency

  fprintf ('running fircls1 (n=%d, wo=%f, dp=%f, ds=%f wt=%f)\n',...
            n,wo,dp,ds,wt);
  c=fircls1(n,wo,dp,ds,wt);

  if (display==1)
    fvtool(c)
  end

  if (n < n_taps)
    h=interpft(c,n_taps+1);
  else
    h=c;
  end
  
  h=h/sum(h); % normalize
  
  % Save impulse response h, and other parameters
  fir_filter_path = sprintf('./../config/Prototype_FIR.alt.%d-%d.%d.%d.mat', os_factor.nu, os_factor.de, n_chan, n_taps);
  save(fir_filter_path, 'h', 'n_taps', 'n_chan', 'wo', 'dp', 'ds', 'wt');

  fprintf('filter coefficients saved in %s\n', fir_filter_path);
  
  % Save a sampled version of the Transfer Function for later equalisation
  % - length should be n_chan times the half-channel width (where width is FFTlength/OS_factor)
  % e.g. 64 channels, ffft_len = 1024: 28,672 is 448*64, which gives 448 points per half-channel, 896 per channel
%     [H0,W] = freqz (h, 1, ffft_len*os_factor.de*n_chan/(2*os_factor.nu));
%     save('./../config/TF_points.mat', 'H0', 'W');
%
%     % Optionally display design
  if (method > 0 && display==2)
      
    fprintf ('plotting response\n');
      
    [H0,W] = freqz (h, 1, n_taps);

    %Rescaling the frequency axis
    W = W/pi;

    Fp=wo*intermediate_nchan/n_chan;
    Fs=OS*Fp;
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

    saveas(fig, sprintf('./../products/FIR_filter_response.%d.png', n_taps));

  end;

%     close all;
%
% return
end
