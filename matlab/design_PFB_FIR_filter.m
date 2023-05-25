function fir_filter_path = design_PFB_FIR_filter(n_chan, os_factor, n_taps_per_chan, display_)
  % Design a FIR appropriate for polyphase filterbank.
  %
  % Example:
  %
  % .. code-block::
  %
  %   >> design_PFB_FIR_filter(256, {'nu': 4, 'de': 3}, 12, 0);
  %
  % Args:
  %   n_chan (numeric): number of PFB output channels
  %   os_factor (struct): oversampling factor struct
  %   n_taps_per_chan (numeric): Number of filter taps per output channel
  %   display (bool): Optional. Whether or not to generate plots to Defaults to false.
  % Returns:
  %   string: Path to newly created ``.mat`` file contaning FIR filter coefficents.

  display = 0;
  if exist('display_', 'var')
    display = display_;
  end

  % Oversampling Factor
  OS = os_factor.nu/os_factor.de;
  if OS == 1
    OS = OS + 0.1;
  end

  % normalized number of channels
  n_chanNorm = (n_chan*os_factor.de) / os_factor.nu;

  % Filter specs for the prototype filter
  % Cut-off frequency
  Fp = 1./n_chan;

  % Stop-band frequency
  Fs = 1.*(2*OS-1)/n_chan;

  fprintf('design_PFB: cut-off frequency: %f\n', Fp);
  fprintf('design_PFB: stop-band frequency: %f\n', Fs);

  % Design filter
  n_taps = n_chan * n_taps_per_chan;
  Hf = fdesign.lowpass('N,Fp,Fst',n_taps,Fp,Fs);
  H_Obj_0 = design(Hf,'firls','Wstop',15,'systemobject',true);
  % H_Obj_0 = design(Hf,'equiripple','Wstop',60,'StopbandShape','linear','StopbandDecay',30);

  h = H_Obj_0.Numerator;

  % Save impulse response h, and other parameters
  fir_filter_path = sprintf('./../config/Prototype_FIR.new.%d-%d.%d.%d.mat', os_factor.nu, os_factor.de, n_chan, n_taps);
  save(fir_filter_path, 'h', 'n_chan', 'Fp', 'Fs');

  % Save a sampled version of the Transfer Function for later equalisation
  % - length should be n_chan times the half-channel width (where width is FFTlength/OS_factor)
  % e.g. 64 channels, ffft_len = 1024: 28,672 is 448*64, which gives 448 points per half-channel, 896 per channel
%     [H0,W] = freqz (h, 1, ffft_len*os_factor.de*n_chan/(2*os_factor.nu));
%     save('./../config/TF_points.mat', 'H0', 'W');
%
%     % Optionally display design

  if (display==1)
    fprintf ('plotting response\n');
    fig = plot_FIR_filter (n_chan, OS, h);
    saveas(fig, sprintf('./../products/FIR_filter_response.%d.png', n_taps));
  end

%     close all;
%
% return
end
