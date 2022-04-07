function fir_filter_path = design_PFB_FIR_filter_alt(n_chan, os_factor, n_taps, display_)
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
  %   n_taps (single): Number of filter taps
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
  
  % Filter specs for the prototype filter
  % currently, only overlap-save is implemented
  overlap_save = 1;
  if (overlap_save == 1)
      
    % John Bunton recommends this configuration for spectral overlap-save
    % flat to bandedge stopband at 0.8333
    n = 256;      % n+1 is the intermediate filter length
    wo = 1/12.2;  % Cut-off frequency
    dp = 0.002;   % Maximum passband deviation from 1 (passband ripple)
    ds = 0.0002;  % Maximum stopband deviation from 0 (stopband ripple)

  else % spectral overlap-add is not implemented
      
    % John Bunton recommends this configuration for spectral overlap-add
    % -6dB bandedge stopband edge 0.666
    n = 256;      % n+1 is the intermediate filter length
    wo = 1/15.96; % Cut-off frequency
    dp = 0.001;   % Maximum passband deviation from 1 (passband ripple)
    ds = 0.0002;  % Maximum stopband deviation from 0 (stopband ripple)

  end
  
  fprintf ('running fircls1 (n=%d, wo=%f, dp=%f, ds=%f)\n',n,wo,dp,ds);
  c=fircls1(n,wo,dp,ds);

  h=interpft(c,n_taps+1);
  h=h/sum(h); % normalize
  
  % Save impulse response h, and other parameters
  fir_filter_path = sprintf('./../config/Prototype_FIR.alt.%d.%d.mat', n_chan, n_taps);
  save(fir_filter_path, 'h', 'n_taps', 'c', 'n', 'wo', 'dp', 'ds');

  % Save a sampled version of the Transfer Function for later equalisation
  % - length should be n_chan times the half-channel width (where width is FFTlength/OS_factor)
  % e.g. 64 channels, ffft_len = 1024: 28,672 is 448*64, which gives 448 points per half-channel, 896 per channel
%     [H0,W] = freqz (h, 1, ffft_len*os_factor.de*n_chan/(2*os_factor.nu));
%     save('./../config/TF_points.mat', 'H0', 'W');
%
%     % Optionally display design
  if (display==1)
    [H0,W] = freqz (h, 1, n_taps);

    %Rescaling the frequency axis
    W = W/pi;

    fig = figure;
    subplot(1,1,1)
    plot (W, abs(H0), 'LineWidth', 1.5);
    axis ([0 3.5*Fp -0.15 1.15]);
    title(sprintf('Transfer Function of the Prototype Filter with %d taps', n_taps));
    grid on; box on;

    % subplot(3,1,2)
    % hold on;
    % plot (W, 20*log10(abs(H0)));
    % % plot([0 Fp], [-0.5*Ap -0.5*Ap],'k-.','LineWidth',1);
    % % plot([0 Fp], [ 0.5*Ap  0.5*Ap],'k-.','LineWidth',1);
    % hold off;
    % axis ([0 1.5*Fp -1000*Ap 1000*Ap]);
    % title ('Passband')
    % grid on; box on;
    %
    % subplot (3,1,3);
    % hold on;
    % plot (W, 20*log10(abs(H0)));
    % plot([Fs 1], [-As -As],'r-','LineWidth',1);
    % hold off;
    % axis ([0 1 -(As+10) 3]);
    % title ('Stopband')
    % grid on; box on;

    saveas(fig, sprintf('./../products/FIR_filter_response.%d.png', n_taps));

  end;

%     close all;
%
% return
end
