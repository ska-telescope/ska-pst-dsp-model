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

  dp = 1e-3;          % Maximum passband deviation from 1 (passband ripple)  
  dBs = -80;
  ds = 10^(dBs/20);   % Maximum stopband deviation from 0 (stopband ripple)

  fscale=1;
  
  if (n_taps_per_chan > os_factor.de)
    oversampled_ntaps_per_chan = n_taps_per_chan * os_factor.nu / os_factor.de;
  else
    fscale = n_taps_per_chan;
    oversampled_ntaps_per_chan = os_factor.nu;
    n_taps_per_chan = n_taps_per_chan * os_factor.de;
  end
  
  fprintf ('os_ntap=%d ntap=%d (per channel)',...
           oversampled_ntaps_per_chan, n_taps_per_chan);
       

  fprintf ('design_PFB_FIR_filter_alt: optimizing for overlap-save\n');

  n  = oversampled_ntaps_per_chan*n_taps_per_chan - 1;
  n_taps = n_taps_per_chan * n_chan;

  fudge_pass = 1;
  wo = fudge_pass * fscale/n_taps_per_chan;          % Cut-off frequency
  fudge_stop = 1.3;
  wt = fudge_stop * (2*OS-1)*fscale/n_taps_per_chan; % Stop-band frequency

  fprintf ('running fircls1 (n=%d, wo=%f, dp=%f, ds=%f wt=%f)\n',...
            n,wo,dp,ds,wt);
  c=fircls1(n,wo,dp,ds,wt);

  h=interpft(c,n_taps+1);
  h=h/sum(h); % normalize
  
  % Save impulse response h, and other parameters
  fir_filter_path = sprintf('./../config/Prototype_FIR.alt.%d-%d.%d.%d.mat', os_factor.nu, os_factor.de, n_chan, n_taps);
  save(fir_filter_path, 'h', 'n_taps', 'n_chan', 'wo', 'dp', 'ds', 'wt');

  fprintf('filter coefficients saved in %s\n', fir_filter_path);
  
  % Optionally display design
  if (display==1)
      
    fprintf ('plotting response\n');
      
    fig = plot_FIR_filter (n_chan, OS, h);

    saveas(fig, sprintf('./../products/FIR_filter_response.%d.png', n_taps));

  end;


end
