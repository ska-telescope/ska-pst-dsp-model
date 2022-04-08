function fir_filter_path = design_PFB_FIR_filter_two_stage(n_chan, os_factor, os_taps_per_chan_, zero_stuff_factor_, display_)
  % Design a FIR appropriate for oversampled polyphase filterbank using two stage design approach
  % Adapted from code originally developed by Thushara Gunaratne - RO/RCO - NSI-NRC CANADA
  %
  % Example:
  %
  % .. code-block::
  %
  %   >> design_PFB_FIR_filter_two_stage(4096, {'nu': 8, 'de': 7}, 28);
  %
  % Args:
  %   n_chan (numeric): number of PFB output channels
  %   os_factor (struct): oversampling factor struct
  %   os_taps_per_chan (single): Number of filter taps per channel
  %  
  % Returns:
  %   string: Path to newly created ``.mat`` file contaning FIR filter coefficents.

  os_factor_f = os_factor.nu/os_factor.de;
  os_taps_per_chan = 28;
  zero_stuff_factor = 32;
  display = 0;

  if exist('os_taps_per_chan_', 'var')
    os_taps_per_chan = os_taps_per_chan_;
    zero_stuff_factor = (os_taps_per_chan * os_factor.nu) / os_factor.de;
    % if mod((n_chan/os_factor_f), os_taps_per_chan) ~= 0
    %   ME = MException('MYFUN:BadIndex', ...
    %     'Can''t pass os_taps_per_chan that isn''t divisible by n_chan / os_factor');
    %   throw(ME);
    % end
  end

  if exist('zero_stuff_factor_', 'var')
    zero_stuff_factor = zero_stuff_factor_;
  end

  if exist('display_', 'var')
    display = display_;
  end

  n_taps = os_taps_per_chan*n_chan/os_factor_f;

  n_taps_stage1 = n_taps/zero_stuff_factor;

  %Filter Specs for the 1st Stage Prototype Filter
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %Note that for the 1st Stage Prototype Filter the cut-off frequencies are zero_stuff_factor
  %times higher than the required cut off frequencies

  %Cut-off Frequency
  Fp = 1/n_chan;

  %StopBand Frequency
  Fs = (2*os_factor_f-1)/n_chan;

  %Filter Transfer-function Specs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Passband ripple is  PRip dB
  Ap = 0.1;
  % Ap = 0.01;
  % Passband ripple is  SAtn dB
  As = 60;
  % As = 10*log10(1E6*n_chan);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %Tweaking the Stopband Edge Slightly
  Hf = fdesign.lowpass('N,Fp,Fst',n_taps_stage1,Fp*zero_stuff_factor,0.998*Fs*zero_stuff_factor);

  H_Obj_0 = design(Hf,'firls','Wstop',15,'systemobject',true);
  % H_Obj_0 = design(Hf,'equiripple','Wstop',60,'StopbandShape','linear','StopbandDecay',30);

  h0 = H_Obj_0.Numerator;

  % second stage of filter construction
  H1 = fft(ifftshift(h0));
  % Zero-Stuffing
  HZ = [H1(1,1:n_taps_stage1/2+1), zeros(1,n_taps_stage1*(zero_stuff_factor-1)-0), H1(1,n_taps_stage1/2+2:end)];
  h = 1*fftshift(ifft(HZ));

  % ensure that the filter is symmetric.
  % figure; plot(h-fliplr(h));

  fir_filter_path = sprintf('./../config/Prototype_FIR.2_stage.%d-%d.%d.%d.mat', os_factor.nu, os_factor.de, n_chan, n_taps);
  save(fir_filter_path, 'h', 'n_chan', 'Fp', 'Fs', 'Ap', 'As');

  if display
    figure;
    plot(h0);
    title('The Impulse Response')

    %Displaying the Properties
    [H0,W] = freqz (h0, 1, n_taps_stage1*8);
    %Rescaling the frequency axis
    W = W/pi;

    figure;
    subplot(3,1,1)
    plot (W, abs(H0));
    axis ([0 3.5*Fp*zero_stuff_factor -0.15 1.15]);
    title('Transfer Function of the Prototype Filter - First Stage')
    grid on; box on;

    subplot(3,1,2)
    hold on;
    plot (W, 20*log10(abs(H0)));
    plot([ 0 Fp*zero_stuff_factor], [-0.5*Ap -0.5*Ap],'k-.','LineWidth',1);
    plot([ 0 Fp*zero_stuff_factor], [ 0.5*Ap  0.5*Ap],'k-.','LineWidth',1);
    plot([Fp*zero_stuff_factor Fp*zero_stuff_factor], [-0.5*Ap  0.5*Ap],'k-.','LineWidth',1);
    hold off;
    axis ([0 1.5*Fp*zero_stuff_factor -4.5*Ap 4.5*Ap]);
    title ('Passband - First Stage')
    grid on; box on;

    subplot (3,1,3);
    hold on;
    plot (W, 20*log10(abs(H0)));
    plot([Fs*zero_stuff_factor 1], [-As -As],'k-.','LineWidth',1);
    plot([Fs*zero_stuff_factor Fs*zero_stuff_factor], [-60 0],'k-.','LineWidth',1);
    hold off;
    axis ([0 1 -(As+60) 3]);
    title ('Stopband - First Stage')
    grid on; box on;


    [H,W] = freqz (h, 1, n_taps*8);
    %Scaling Factor
    Ho = max(abs(H));
    %Rescaling the frequency axis
    W = W/pi;

    figure;
    subplot(3,1,1)
    hold on;
    plot (W, abs(H));
    hold off;
    axis ([0 3.5*Fp -0.15 1.15]);
    title('Transfer Function of the Prototype Filter - Second Stage')
    grid on; box on;

    subplot(3,1,2)
    hold on;
    plot (W, 20*log10(abs(H)));
    plot ([0 Fp], [0.5*Ap 0.5*Ap],'k-.','LineWidth',1);
    plot ([0 Fp], [-0.5*Ap -0.5*Ap],'k-.','LineWidth',1);
    plot ([Fp Fp], [-0.5*Ap 0.5*Ap],'k-.','LineWidth',1);
    hold off;
    axis ([0 3.5*Fp -4.5*Ap 4.5*Ap]);
    title ('Passband - Second Stage')
    grid on; box on;

    subplot (3,1,3);
    hold on;
    plot (W, 20*log10(abs(H)));
    plot ([Fs 1], [-As -As],'k-.','LineWidth',1);
    plot ([Fs Fs], [-As 0],'k-.','LineWidth',1);
    hold off;
    axis ([0 1/zero_stuff_factor -(As+60) 3]);
    title ('Stopband - Second Stage')
    grid on; box on;
    
    fig = plot_FIR_filter (n_chan, os_factor_f, h);
  end
end
