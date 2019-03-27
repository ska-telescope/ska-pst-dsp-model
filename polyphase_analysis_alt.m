function out=polyphase_analysis_alt (in, filt, block, os_factor)

% Polyphase analysis filterbank with cyclic shift of data into FFT
% to remove spectrum rotation in output data
% @method polyphase_analysis_alt
% @author Ian Morrison <ian.morrison@curtin.edu.au> 2015
% @author Dean Shaff <dshaff@swin.edu.au> 2019

% @param {single/double []} in - input data. The dimensionality should be
%   (n_pol, n_chan, n_dat), where n_chan is equal to 1.
% @param {single/double []} filt - prototype lowpass filter
%   (length should be multiple of step)
% @param {single/double []} block - length of fft
%   (prefilter length = length(filt)/block
%   if not the 'filt' is padded with zeros to a multiple of block
%   Importantly, This is also the number of channels that will
%   be created by the PFB.
% @param {struct} os_factor - struct with 'nu' and 'de' fields
% @return {single/double []} - output data: two dimensional array.
%   The first dimension is time, the second frequency. The number of frequency
%   frequency channels is equal to `block`

  in_size = size(in);
  n_pol = in_size(1);
  n_chan = in_size(2); % should always be 1
  n_dat = in_size(3);

  dtype = class(in);
  output_ndim = 2;
  if isreal(in)
    output_ndim = 1;
  end

  step = normalize(block, os_factor);
  nblocks = floor(ndat-length(filt) / step);

  out = zeros(n_pol, block, nblocks, dtype);

  for i_pol = 1:n_pol
    PFB_fn = PFB_factory(block, filt, os_factor, output_ndim, dtype);
    for n = 1:nblocks
      out(i_pol, :, n) = PFB_fn(in(i_pol, 1, (n-1)*step:n*step));
    end
  end


end


function PFB = PFB_factory(n_chan, filt_coeff, os_factor, output_ndim_, dtype_, verbose_)

  if os_factor.nu / os_factor.de == 1.0
    pfb_type = 0;
  else
    pfb_type = 1;
  end

  Os = os_factor.nu / os_factor.de;
  L = n_chan;
  M = L/Os;
  L_M = L-M;

  output_ndim = 1;
  if exist('output_ndim_', 'var')
    output_ndim = output_ndim_;
  end

  dtype = 'single';
  if exist('dtype_', 'var')
    dtype = dtype_;
  end

  verbose = 0;
  if exist('verbose', 'var')
    verbose = verbose_;
  end

  if verbose
    fprintf('PFB_factory: output_ndim: %d\n', output_ndim);
    fprintf('PFB_factory: dtype: %s\n', dtype);
  end


  % FiltCoefStruct = load(pfb_filter_coef_fname);
  % h = single(FiltCoefStruct.h);
  %Initiate the Input Mask that is multiplied with the Filter mask
  xM = zeros(1,length(filt_coeff), dtype);
  %Initiate the Output mask
  yP = zeros(L, 1, dtype);
  %Control Index - Initiation
  n = 0;

  if pfb_type == 0
    if verbose
      fprintf('PFB_factory: Using critically sampled PFB\n');
    end
    PFB = @CS_PFB;
  elseif pfb_type == 1
    if verbose
      fprintf('PFB_factory: Using oversampled sampled PFB\n');
    end
    PFB = @OS_PFB;
  end

  function y = CS_PFB(x)
    %Multiplying the Indexed Input Mask and Filter Mask elements and
    %accumulating
    for k = 1 : L
        yP(k,1) = sum(xM(k:L:end).*filt_coeff(k:L:end));
    end; % For k
    %The Linear Shift of Input through the FIFO
    %Shift the Current Samples by M to the Right
    xM(1,L+1:end) = xM(1,1:end-L);
    %Assign the New Input Samples for the first M samples
    xM(1,1:L) = fliplr(x);%Note the Flip (Left-Right) place the Newest sample
                          % to the front
    %transpose(yP((1:L),1))
    %Performing the Circular Shift to Compensate the Shift in Band Center
    %Frequencies
    y1S = yP;
    % if n == 0
    %     y1S = yP;
    % else
    %     y1S = [yP((n_chan-n)+1:end); yP(1:(n_chan-n))];
    % end;

    % %Evaluating the Cross-Stream (i.e. column wise) IDFT
    % yfft = L*L*(ifft(yP));%
    %
    % %Note the Input Signal is Real-Valued. Hence, only half of the output
    % %Channels are Independent. The Packing Method is used here. However,
    % %any Optimized Real IFFT Evaluation Algorithm Can be used in its place
    % %Evaluating the Cross-Stream (i.e. column wise) IDFT using Packing
    % %Method
    % %The Complex-Valued Sequence of Half Size
    y2C = y1S(1:2:end) + 1j*y1S(2:2:end);

    if output_ndim == 1
      %The Complex IDFT of LC=L/2 Points
      IFY2C = L*L/2*ifft(y2C);
      IFY2C;
      y(1:L/2) = (0.5*((IFY2C+conj(circshift(flipud(IFY2C),[+1,0])))...
                  - 1j*exp(2j*pi*(0:1:L/2-1).'/L).*...
                    (IFY2C-conj(circshift(flipud(IFY2C),[+1,0])))));
      % [0,+1]
      y(L/2+1) = 0.5*((IFY2C(1)+conj(IFY2C(1)) + 1j*(IFY2C(1)-conj(IFY2C(1)))));

      y(L/2+2:L) = conj(fliplr(y(2:L/2)));
    elseif output_ndim == 2
      % y1S = y1S.*hann_window;
      y = L*L*ifft(y1S);
      % y = L*fft(y1S); % have to use inverse fft
    end
    %Changing the Control Index
    n = n+1;
    n = mod(n, n_chan);
  end


  function y = OS_PFB(x)

    %Multiplying the Indexed Input Mask and Filter Mask elements and
    %accumulating
    for k = 1 : L
        yP(k,1) = sum(xM(k:L:end).*filt_coeff(k:L:end));
    end; % For k

    %The Linear Shift of Input through the FIFO
    %Shift the Current Samples by M to the Right
    xM(1,M+1:end) = xM(1,1:end-M);
    %Assign the New Input Samples for the first M samples
    xM(1,1:M) = fliplr(x);%Note the Flip (Left-Right) place the Newest sample
                          % to the front

    %Performing the Circular Shift to Compensate the Shift in Band Center
    %Frequencies
    % y1S = yP;
    if n == 0
        idx = [1:L];
        y1S = yP;
    else
        idx = [(os_factor.nu-n)*L_M+1:L 1:(os_factor.nu-n)*L_M];
        y1S = [yP((os_factor.nu-n)*L_M+1:end); yP(1:(os_factor.nu-n)*L_M)];
    end;

    % %Evaluating the Cross-Stream (i.e. column wise) IDFT
    % yfft = L*L*(ifft(yP));%
    %
    % %Modulating the Channels (i.e. FFT Outputs) to compensate the shift in the
    % %center frequency
    % %y = yfft.*exp(2j*pi*(1-M/L)*n*(0:1:L-1).');
    % y = yfft.*exp(-2j*pi*M/L*n*(0:1:L-1).');

    % %Note the Input Signal is Real-Valued. Hence, only half of the output
    % %Channels are Independent. The Packing Method is used here. However,
    % %any Optimized Real IFFT Evaluation Algorithm Can be used in its place
    % %Evaluating the Cross-Stream (i.e. column wise) IDFT using Packing
    % %Method
    % %The Complex-Valued Sequence of Half Size
    if output_ndim == 1
      y2C = y1S(1:2:end) + 1j*y1S(2:2:end);
      %The Complex IDFT of LC=L/2 Points
      IFY2C = L*L/2*ifft(y2C);
      %
      y(1:L/2) = (0.5*((IFY2C+conj(circshift(flipud(IFY2C),[+1,0])))...
                  - 1j*exp(2j*pi*(0:1:L/2-1).'/L).*...
                   (IFY2C-conj(circshift(flipud(IFY2C),[+1,0])))));
      % [0,+1]
      y(L/2+1) = 0.5*((IFY2C(1)+conj(IFY2C(1)) + 1j*(IFY2C(1)-conj(IFY2C(1)))));

      y(L/2+2:L) = conj(fliplr(y(2:L/2)));
    elseif output_ndim == 2
      % y1S = y1S.*hann_window;
      y = L*L*ifft(y1S);
      % y = L*fft(y1S);
    end
    %Changing the Control Index
    n = n+1;
    n = mod(n, os_factor.nu);
  end
end
