function out = polyphase_synthesis(...
  in,...
  input_fully_spans_Nyquist_zone,...
  input_fft_length,...
  os_factor,...
  deripple_,...
  sample_offset_,...
  input_overlap_,...
  temporal_taper_,...
  spectral_taper_,...
  combine_,...
  verbose_...
)

  % recombine channels that were created using polyphase filterbank.
  % Take into account any oversampling, and the number of received PFB channels
  %
  % This code is adapted from code written by Ian Morrison to analyze spectral
  % and temporal purity of the PFB inversion technique.
  %
  %
  % Example:
  %
  % Recreate coarse channels from channelized data. Do not do any time domain
  % windowing, or overlap discard.
  %
  % .. code-block::
  %
  %   >> size(in)
  %   2 8 7168
  %   >> size(filt)
  %   81 1
  %   >> polyphase_synthesis(in, 128, struct('nu', 8, 'de', 7),...
  %                          struct('deripple', 1, 'filter_coeff', filt))
  %
  % Args:
  %   in ([numeric]): Input array. The dimensionality should be
  %     (n_pol, n_chan, n_dat). Whether the data are complex or real is built
  %     into array.
  %   input_fft_length (double): The length of the forward FFT.
  %   os_factor (struct): The oversampling factor. This is a struct
  %     with members `nu` and `de` corresponding to the oversampling factor's
  %     numerator and denominator, respectively.
  %   deripple_ (struct): A struct containing filter coefficients
  %       used to channelize data. If the 'apply_deripple' struct flag is true,
  %       apply derippling correction or 'ripple equalization'.
  %   sample_offset_ (int): offset applied to channelized input prior to
  %     processing.
  % Returns:
  %   [numeric]: Upsampled time domain output array. The
  %     dimensionaly will be (n_pol, 1, n_dat). Note that `n_dat` for the
  %     return array and the input array will not be the same
  %%
  tstart = tic;

  function windowed = default_window(input_chunk, input_fft_length, input_overlap)
    windowed = input_chunk;
  end

  sample_offset = 1;
  if exist('sample_offset_', 'var')
    sample_offset = sample_offset_;
  end

  deripple = struct('apply_deripple', 0, 'filter_coeff', []);
  if exist('deripple_', 'var')
    deripple = deripple_;
  end

  verbose = 0;
  if exist('verbose_', 'var')
    verbose = verbose_;
  end

  if exist('input_overlap_', 'var')
    input_overlap = input_overlap_;
  else
    input_overlap = input_fft_length / 8;
  end

  if exist('temporal_taper_', 'var')
    temporal_taper = temporal_taper_;
  else
    temporal_taper = @default_window;
  end

  if exist('spectral_taper_', 'var')
    spectral_taper = spectral_taper_;
  else
    spectral_taper = @default_window;
  end

  if exist('combine_', 'var')
    combine = combine_;
  else
    combine = 1;
  end

  in = in(:, :, sample_offset:end);

  size_in = size(in);
  n_pol = size_in(1);
  n_chan = size_in(2);
  n_dat = size_in(3);
  dtype = class(in);
  if verbose
    fprintf('polyphase_synthesis: n_pol=%d, n_chan=%d, n_dat=%d\n', n_pol, n_chan, n_dat);
    fprintf('polyphase_synthesis: os_factor.nu=%d, os_factor.de=%d\n', os_factor.nu, os_factor.de);
    fprintf('polyphase_synthesis: input spans DC=%d\n', input_fully_spans_Nyquist_zone);
  end

  input_keep = input_fft_length - 2*input_overlap;

  n_blocks = floor((n_dat - 2*input_overlap) / input_keep);

  output_fft_length = normalize(os_factor, input_fft_length) * n_chan;
  output_overlap = normalize(os_factor, input_overlap) * n_chan;
  output_keep = output_fft_length - 2*output_overlap;
  
  if verbose
    fprintf('polyphase_synthesis: input_fft_length=%d\n', input_fft_length);
    fprintf('polyphase_synthesis: output_fft_length=%d\n', output_fft_length);
    fprintf('polyphase_synthesis: input_overlap=%d\n', input_overlap);
    fprintf('polyphase_synthesis: output_overlap=%d\n', output_overlap);
    fprintf('polyphase_synthesis: input_keep=%d\n', input_keep);
    fprintf('polyphase_synthesis: output_keep=%d\n', output_keep);
    fprintf('polyphase_synthesis: sample_offset=%d\n', sample_offset);
    fprintf('polyphase_synthesis: n_blocks=%d\n', n_blocks);
  end
  out = complex(zeros(n_pol, 1, n_blocks*output_keep, dtype));


  FN_width = (input_fft_length*os_factor.de)/os_factor.nu;
  FN_width_2 = FN_width / 2;

  discard_2 = (input_fft_length - FN_width) / 2;
  
  if deripple.apply_deripple
    if verbose
      fprintf('polyphase_synthesis: applying deripple\n');
    end
    passband_length = FN_width/2;
    [H0,W] = freqz(deripple.filter_coeff, 1, n_chan*passband_length);
    % figure; ax = gca;
    % plot(abs(H0));
    % grid(ax, 'on');
    % use just the baseband passband section of transfer function
    % - apply to both halves of channel
    filter_response = ones(passband_length+1,1)./abs(H0(1:passband_length+1,1));
  end

  FFFF = complex(zeros(n_chan*FN_width, 1));
  FN = complex(zeros(FN_width, n_chan, dtype));
  in_dat = complex(zeros(n_chan, input_fft_length));

  chan0_psd = zeros(input_fft_length);
  
  fine_chan_per_coarse_chan = n_chan / combine;

  % fig = figure;
  for n=1:n_blocks
    for i_pol=1:n_pol
      in_step_s = input_keep*(n-1) + 1;
      in_step_e = in_step_s + input_fft_length - 1;

      out_step_s = output_keep*(n-1) + 1;
      out_step_e = out_step_s + output_keep - 1;

      in_dat(:) = squeeze(in(i_pol, :, in_step_s:in_step_e));
      % size(in_dat)
      % % zero first and last input_discard:
      % ax = subplot(2, 1, 1);
      % plot(abs(in_dat(:)));
      % ax = subplot(2, 1, 2);
      % plot(imag(in_dat(:)));
      % pause;
      in_dat = temporal_taper(in_dat, input_fft_length, input_overlap);
      % in_dat(:, 1:input_overlap) = complex(0, 0);
      % in_dat(:, (input_fft_length - input_overlap)+1:end) = complex(0, 0);

      % fft operates on each of the columns
      spectra = transpose(in_dat);
      spectra = fft(spectra, input_fft_length);

      % WvS - swap harmonics in each channel
      spectra = fftshift(spectra, 1);

      chan0_psd = chan0_psd + abs(spectra(:,1)).^2;

      FN = complex(zeros(FN_width, n_chan, dtype));
      for chan = 1:n_chan
        % fprintf('i_block=%d, i_pol=%d, chan=%d\n', n, i_pol, chan);
        % size(FN)
        % phase_shift_arr(chan);

        jchan = chan;

        if (combine > 1)

           % compute new index using C-style indexing
           jchan = jchan - 1;

           % fprintf ('fine chan per coarse chan = %d\n',fine_chan_per_coarse_chan);

           % re-order input channels in DSB monotonically
           coarse_channel = floor(jchan / fine_chan_per_coarse_chan);
           fine_channel = mod(jchan,fine_chan_per_coarse_chan);

           % fprintf ('chan=%d coarse=%d fine=%d \n', chan, coarse_channel, fine_channel);

           output_channel = floor(coarse_channel / combine);
           coarse_offset = mode(coarse_channel, combine);

           % fprintf ('output=%d offset=%d \n', output_channel, coarse_offset);

           % swap halves of the band within the output channel
           coarse_offset = mod ((coarse_offset + combine/2), combine);
           
           % swap halves of the band within the coarse channel
           fine_channel = mod ((fine_channel + fine_chan_per_coarse_chan/2), fine_chan_per_coarse_chan);

           jchan = (output_channel * combine + coarse_offset) * fine_chan_per_coarse_chan + fine_channel;

           % convert back to Matlab-style indexing
           jchan = jchan + 1;
        end

        FN(1:FN_width, chan) = spectra((1:FN_width)+discard_2, jchan);
        
        if deripple.apply_deripple
          % applied_response = zeros(passband_length*2, 1);
          for ii = 1:passband_length
              % fprintf('%d, %d\n', ii, passband_length-ii+2)
              FN(ii,chan) = FN(ii,chan)*filter_response(passband_length-ii+2);
              FN(passband_length+ii,chan) = FN(passband_length+ii,chan)*filter_response(ii);
              % applied_response(ii) = filter_response(passband_length-ii+2);
              % applied_response(passband_length+ii) = filter_response(ii);
          end
        end
        
        if (input_fully_spans_Nyquist_zone == 0)
            FFFF((1:FN_width) + (chan-1)*FN_width) = FN(:, chan);
        end
        
      end
      % size(FN(:, 1))
      % catted = cat(1, FN(:, 1), FN(:, 2));
      % ax = subplot(211); plot(angle(catted)); grid(ax, 'on');
      % ax = subplot(212); plot(abs(catted)); grid(ax, 'on');
      % pause

      %% Combine chunks & back-transform
      if (input_fully_spans_Nyquist_zone == 1)
          
          % upper half of chan 1 is first part of FFFF
          FFFF(1:FN_width_2) = FN(FN_width_2+1:FN_width,1); 
          
          % and lower half of chan 1 is last part of FFFF
          FFFF(n_chan*FN_width - FN_width_2 + 1:end) = FN(1:FN_width/2,1);
                    
          for chan = 1 : n_chan-1
              idx_start = (chan-1)*FN_width + FN_width_2;
              idx_end = idx_start + FN_width;
              FFFF(idx_start + 1:idx_end) = FN(:, chan+1);
          end
      end
      
      % length(FFFF)

      FFFF = spectral_taper(FFFF, length(FFFF), input_overlap);

      % back transform
      iFFFF = ifft(FFFF)./(os_factor.nu/os_factor.de);

      % for chan = 1:n_chan
      %   ax = subplot(n_chan+1, 2, 2*chan-1);
      %   plot(real(squeeze(in_dat(chan,:))));
      %
      %   ax = subplot(n_chan+1, 2, 2*chan);
      %   plot(abs(squeeze(FN(:, chan))))
      %
      % end
      %
      % ax = subplot(n_chan+1, 2, 2*n_chan+2);
      % plot(log10(abs(fftshift(FFFF))))
      % pause
      % if n == 1
      %   out(i_pol, 1, 1:out_step_e+output_overlap) = iFFFF(1:output_fft_length-output_overlap);
      % else
      out(i_pol, 1, out_step_s:out_step_e) = iFFFF(output_overlap + 1:output_fft_length-output_overlap);
      % out(i_pol, 1, output_keep*(n-1) + 1:output_keep*(n)) = iFFFF(output_overlap + 1:output_fft_length-output_overlap);
      % output_keep*(n-1) + 1
      % out_step_s + output_keep - 1
      % if n == 1
      %   out(i_pol, 1, out_step_s:out_step_e) = iFFFF(output_overlap + 1:output_fft_length-output_overlap);
      % else
      %   out(i_pol, 1, out_step_s-output_overlap:out_step_s-1) = squeeze(out(i_pol, 1, out_step_s-output_overlap:out_step_s-1)) + iFFFF(1:output_overlap);
      %   out(i_pol, 1, out_step_s:out_step_e) = iFFFF(output_overlap + 1:output_fft_length-output_overlap);
      % end
      % out(i_pol, 1, out_step_s:out_step_e) = iFFFF(1:output_keep);
      % end
      % out(i_pol, 1, out_step_s:out_step_e) = ifft(FFFF)./(os_factor.nu/os_factor.de);  % re-scale by OS factor
    end
  end
  
  % plot (chan0_psd);
  % pause;
  
  if verbose
    tdelta = toc(tstart);
    fprintf('polyphase_synthesis: Elapsed time is %f seconds\n', tdelta);
  end
end
