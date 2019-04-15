function out=polyphase_analysis(in, filt, block, os_factor, verbose_)

  % Polyphase analysis filterbank with cyclic shift of data into FFT
  % to remove spectrum rotation in output data
  % @method polyphase_analysis
  % @author John Bunton <CSIRO> 2003, 2016
  % @author Dean Shaff <dshaff@swin.edu.au; Swinburne University> 2019

  % @param {single/double []} in - input data. The dimensionality should be
  %   (n_pol, n_chan, n_dat), where n_chan is equal to 1.
  % @param {single/double []} filt - prototype lowpass filter
  %   (length should be multiple of step). Should be single dimensional array.
  % @param {single/double} block - length of fft
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
    fprintf('polyphase_analysis: dtype=%s\n', dtype);
    fprintf('polyphase_analysis: nblocks=%d\n', nblocks);
  end
  %block=block*2;     % Interleaved filterbank
  %phases=phases/2;   %produces critically sampled outputs as well as
                      %intermediate frequency outputs
  prev_bytes = 1;
  out = complex(zeros(n_pol, block, nblocks, dtype));
  for i_pol = 1:n_pol
    if verbose
      fprintf('polyphase_analysis: %d/%d pol\n', i_pol, n_pol);
    end
    for k=0:nblocks-1
      if mod(k, 10000) == 0 && verbose;
        for b=1:prev_bytes
          fprintf('\b');
        end
        prev_bytes = fprintf('polyphase_analysis: %d/%d blocks\n', k, nblocks);
      end
      temp=f.*in(1+step*k:fl+step*k);

      %index for cyclic shift of data to FFT to eliminate spectrum rotation
      index = (step*k - floor(step*k/block)*block);
      temp=circshift(temp',index)';

      temp2=(1:block)*0;
      for m=0:phases-1
        temp2=temp2+temp(1+block*m:block*(m+1));
      end
      out(i_pol, 1:block, k+1)= fft(temp2); %temp2;%
    end
  end
end
