function design_PFB_FIR_filter(n_chan, os_factor, n_taps, display_)
  % Design a FIR appropriate for polyphase filterbank.
  % @method design_PFB
  % @param {single/double} n_chan - number of PFB output channels
  % @param {struct} os_factor - oversampling factor struct
  % @param {single} n_taps - Number of filter taps

  display = 0;
  if exist('display_', 'var')
    display = display_;
  end

  % Oversampling Factor
  OS = os_factor.nu/os_factor.de;

  % normalized number of channel
  n_chanNorm = (n_chan / os_factor.nu)*os_factor.de;
  % Filter specs for the prototype filter
  % Cut-off frequency

  Fp = 1./n_chan;
  % Fp = 1./n_chanNorm;
  % Stop-band frequency
  if OS == 1
    OS = OS + 0.1;
  end
  % Fs = 1.1*Fp;
  Fs = 1.*(2*OS-1)/n_chan;
  % Fs = (2*OS-1)/n_chan;

  fprintf('design_PFB: cut-off frequency: %f\n', Fp);
  fprintf('design_PFB: stop-band frequency: %f\n', Fs);

  % Filter Transfer Function specs
  Ap = 0.01;
  As = 60;

  % Design filter
  Hf = fdesign.lowpass('N,Fp,Fst',n_taps,Fp,Fs);
  H_Obj_0 = design(Hf,'firls','Wstop',15,'systemobject',true);
  h = H_Obj_0.Numerator;

  % Save impulse response h, and other parameters
  save(sprintf('./../config/Prototype_FIR.%d-%d.%d.%d.mat', os_factor.nu, os_factor.de, n_chan, n_taps), 'h', 'n_chan', 'Fp', 'Fs', 'Ap', 'As');

  % Save a sampled version of the Transfer Function for later equalisation
  % - length should be n_chan times the half-channel width (where width is FFTlength/OS_factor)
  % e.g. 64 channels, ffft_len = 1024: 28,672 is 448*64, which gives 448 points per half-channel, 896 per channel
%     [H0,W] = freqz (h, 1, ffft_len*os_factor.de*n_chan/(2*os_factor.nu));
%     save('./../config/TF_points.mat', 'H0', 'W');
%
%     % Optionally display design
  if (display==1)
    [H0,W] = freqz (h, 1, n_taps*n_chan);

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
