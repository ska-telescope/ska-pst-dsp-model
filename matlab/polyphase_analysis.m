function out=polyphase_analysis(...
    in,...
    filt,...
    block,...
    os_factor,...
    verbose_...
  )
  % Polyphase analysis filterbank with cyclic shift of data into FFT
  % to remove spectrum rotation in output data
  % .. @method polyphase_analysis
  % .. @author John Bunton <CSIRO> 2003, 2016
  % .. @author Dean Shaff <dshaff@swin.edu.au; Swinburne University> 2019
  %
  % Example:
  %
  % .. code-block::
  %
  %   >> size(in)
  %     2 1 65536
  %   >> size(filt)
  %     81 1
  %   >> polyphase_analysis(in, filt, 8, struct('nu', 8, 'de', 7), 0);
  %
  % Args:
  %   in ([numeric]): input data. The dimensionality should be
  %     (n_pol, n_chan, n_dat), where n_chan is equal to 1.
  %   filt ([numeric]): prototype lowpass filter
  %     (length should be multiple of step). Should be single dimensional array.
  %   block (numeric): length of fft
  %     (prefilter length = length(filt)/block
  %     if not the 'filt' is padded with zeros to a multiple of block
  %     Importantly, This is also the number of channels that will
  %     be created by the PFB.
  %   os_factor (struct): rational number struct; struct with 'nu' and 'de' fields
  %   verbose_ (bool): Optional. verbosity flag. Defaults to false.
  % Return:
  %   [numeric]: The first dimension is time, the second frequency.
  %     The number of frequency channels is equal to ``block``

  tstart = tic;
  verbose = 0;
  if exist('verbose_', 'var')
    verbose = verbose_;
  end

  in_size = size(in);
  n_pol = in_size(1);
  n_chan = in_size(2); % This should always be 1.
  n_dat = in_size(3);
  dtype = class(in);
  is_real = isreal(in);

  filt = cast(filt, dtype);

  % step will be the same as block in the critically sampled case.
  step = floor((block * os_factor.de) / os_factor.nu);
  % Making sure the filter has an integer multiple of block size.
  f = pad_filter(filt, block);

  phases = length(f) / block;

  nblocks=floor( (n_dat-length(f))/step);
  fl=length(f);

  if verbose
    fprintf('polyphase_analysis: length(filt)=%d\n', length(filt));
    fprintf('polyphase_analysis: length(padded filt)=%d\n', fl);
    fprintf('polyphase_analysis: nfft=%d\n', block);
    fprintf('polyphase_analysis: step=%d\n', step);
    fprintf('polyphase_analysis: dtype=%s\n', dtype);
    fprintf('polyphase_analysis: nblocks=%d\n', nblocks);
    fprintf('polyphase_analysis: n_pol=%d\n', n_pol);
    fprintf('polyphase_analysis: n_chan=%d\n', n_chan);
    fprintf('polyphase_analysis: n_dat=%d\n', n_dat);
  end
  %block=block*2;     % Interleaved filterbank
  %phases=phases/2;   %produces critically sampled outputs as well as
                      %intermediate frequency outputs
  % prev_bytes = 1;
  out = complex(zeros(n_pol, block, nblocks, dtype));
  % in_block = complex(zeros(fl, 1));

  for i_pol = 1:n_pol
    if verbose
      fprintf('polyphase_analysis: %d/%d pol\n', i_pol, n_pol);
    end
    in_pol = squeeze(in(i_pol, 1, :));
    for k=0:nblocks-1
        
      % if mod(k, 10000) == 0 && verbose;
      %   for b=1:prev_bytes
      %     fprintf('\b');
      %   end
      %   prev_bytes = fprintf('polyphase_analysis: %d/%d blocks\n', k, nblocks);
      % end
      
      in_block = in_pol(1+step*k:fl+step*k);
      % fprintf('size in_block:');
      % size(in_block)

      % index for cyclic shift of data to FFT to eliminate spectrum rotation
      index = (step*k - floor(step*k/block)*block);
      % fprintf('k=%d shift=%d\n', k, index);
      
      temp=circshift(f.*in_block,index)';
      
      % temp2 = sum(reshape(temp, block, phases), 2);
      % temp2 = circshift(temp2, -index);
      % temp = sum(reshape(temp,))
      
      % block = nfft
      temp2=(1:block)*0;
      for m=0:phases-1
        temp2=temp2+temp(1+block*m:block*(m+1));
      end
      % AT3-235: this produces negative frequency offsets (lower sideband)
      % out(i_pol, :, k+1) = fft(temp2)*block;
      
      % AT3-235: this produces positive frequency offsets (upper sideband)
      out(i_pol, :, k+1) = conj( ifft(temp2)*(block^2) );
    end
  end

  if verbose
    tdelta = toc(tstart);
    fprintf('polyphase_analysis: Elapsed time is %f seconds\n', tdelta);
  end

end
