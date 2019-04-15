function out=polyphase_analysis_alt (in, filt, block, os_factor, verbose_)

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

  verbose = 0;
  if exist('verbose_', 'var')
    verbose = verbose_;
  end

  in_size = size(in);
  n_pol = in_size(1);
  n_chan = in_size(2); % should always be 1
  n_dat = in_size(3);

  dtype = class(in);
  output_ndim = 2;
  if isreal(in)
    output_ndim = 1;
  end

  filt = cast(filt, dtype);

  step = normalize(os_factor, block);
  filt_padded = pad_filter(filt, block);
  nblocks = floor((n_dat-length(filt_padded)) / step);

  if verbose
    fprintf('polyphase_analysis_alt: dtype=%s\n', dtype);
    fprintf('polyphase_analysis_alt: nblocks=%d\n', nblocks);
  end

  out = complex(zeros(n_pol, block, nblocks, dtype));
  prev_bytes = 1;
  for i_pol = 1:n_pol
    % if verbose
    %   fprintf('polyphase_analysis_alt: %d/%d pol\n', i_pol, n_pol);
    % end
    PFB_fn = PFB_factory(block, filt, os_factor, output_ndim, dtype, 0);
    for n = 1:nblocks

      if mod(n, randi([5000, 10000],1,1)) == 0 && verbose;
        for b=1:prev_bytes
          fprintf('\b');
        end
        prev_bytes = fprintf('polyphase_analysis_alt: %d/%d blocks', (i_pol-1)*nblocks+n, n_pol*nblocks);
      end
      % fprintf('n_dat=%d, n*step=%d\n', n_dat, n*step);
      i_block = PFB_fn(squeeze(in(i_pol, 1, (n-1)*step+1:n*step)));
      % i_block
      % pause
      % out(i_pol, :, n) = transpose(i_block);
      out(i_pol, :, n) = i_block;
    end
  end
  if verbose
    fprintf('\n');
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
  if exist('verbose_', 'var')
    verbose = verbose_;
  end

  if verbose
    fprintf('PFB_factory: output_ndim: %d\n', output_ndim);
    fprintf('PFB_factory: dtype: %s\n', dtype);
  end


  %Initiate the Input Mask that is multiplied with the Filter mask
  xM = zeros(length(filt_coeff), 1, dtype);
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

  function f = compute_fft(time_domain_arr, fft_size, output_ndim)
    % Transform `time_domain_arr` into the frequency domain.

    % Note that in the case where the input signal is real-valued only half
    % of the output channels are independent. The Packing Method is used here. However,
    % any Optimized Real IFFT Evaluation Algorithm Can be used in its place
    % Evaluating the Cross-Stream (i.e. column wise) IDFT using Packing Method
    % In the case of complex input, simply take the inverse fourier transform.
    if output_ndim == 1
      %The Complex IDFT of LC=L/2 Points
      y2C = time_domain_arr(1:2:end) + 1j*time_domain_arr(2:2:end);
      IFY2C = fft_size*fft_size/2*ifft(y2C);
      IFY2C;
      y(1:fft_size/2) = (0.5*((IFY2C+conj(circshift(flipud(IFY2C),[+1,0])))...
                  - 1j*exp(2j*pi*(0:1:fft_size/2-1).'/fft_size).*...
                    (IFY2C-conj(circshift(flipud(IFY2C),[+1,0])))));
      % [0,+1]
      y(fft_size/2+1) = 0.5*((IFY2C(1)+conj(IFY2C(1)) + 1j*(IFY2C(1)-conj(IFY2C(1)))));

      y(fft_size/2+2:fft_size) = conj(fliplr(y(2:fft_size/2)));
    elseif output_ndim == 2
      y = fft_size*fft_size*ifft(time_domain_arr);
      % y = L*fft(y1S); % have to use inverse fft
    end
    f = y;
  end


  function y = CS_PFB(x)
    %Multiplying the Indexed Input Mask and Filter Mask elements and
    %accumulating
    for k = 1 : L
        yP(k,1) = sum(xM(k:L:end).*filt_coeff(k:L:end));
    end; % For k
    %The Linear Shift of Input through the FIFO
    %Shift the Current Samples by M to the Right
    xM(L+1:end, 1) = xM(1:end-L, 1);
    %Assign the New Input Samples for the first M samples
    % xM(1:L, 1) = fliplr(x); %Note the Flip (Left-Right) place the Newest sample
    xM(1:L, 1) = flipud(x); %Note the Flip (Left-Right) place the Newest sample
                           % to the front
    y1S = yP;

    y = compute_fft(y1S);

    %Changing the Control Index
    n = n+1;
    n = mod(n, n_chan);
  end


  function y = OS_PFB(x)

    %Multiplying the Indexed Input Mask and Filter Mask elements and
    %accumulating
    for k = 1 : L
        yP(k,1) = sum(xM(k:L:end).*filt_coeff(k:L:end));
    end % For k

    % The Linear Shift of Input through the FIFO
    % Shift the Current Samples by M to the Right
    xM(M+1:end, 1) = xM(1:end-M, 1);
    % Assign the New Input Samples for the first M samples
    % xM(1:M, 1) = fliplr(x); % `fliplr` places the newest samples at the front
    xM(1:M, 1) = flipud(x); % `fliplr` places the newest samples at the front
    % Performing circular shift to compensate the shift in band center
    % Frequencies
    if n == 0
        idx = [1:L];
        y1S = yP;
    else
        idx = [(os_factor.nu-n)*L_M+1:L 1:(os_factor.nu-n)*L_M];
        y1S = [yP((os_factor.nu-n)*L_M+1:end); yP(1:(os_factor.nu-n)*L_M)];
    end;

     % Modulating the Channels (i.e. FFT Outputs) to compensate the shift in the
     % center frequency
     % y = yfft.*exp(2j*pi*(1-M/L)*n*(0:1:L-1).');
     % y = yfft.*exp(-2j*pi*M/L*n*(0:1:L-1).');


    y = compute_fft(y1S, L, output_ndim);
    %Changing the Control Index
    n = n+1;
    n = mod(n, os_factor.nu);
  end
end
