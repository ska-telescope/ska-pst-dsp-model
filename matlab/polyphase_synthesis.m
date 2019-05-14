function out = polyphase_synthesis (...
  in,...
  input_fft_length,...
  os_factor,...
  deripple_,...
  sample_offset_,...
  calc_overlap_handler_,...
  window_handler_,...
  verbose_...
)

  % recombine channels that were created using polyphase filterbank.
  % Take into account any oversampling, and the number of received PFB channels
  %
  % This code is adapted from code written by Ian Morrison to analyze spectral
  % and temporal purity of the PFB inversion technique.
  %
  % @method polyphase_synthesis
  % @param {double/single []} in - Input array. The dimensionality should be
  %   (n_pol, n_chan, n_dat). Whether the data are complex or real is built
  %   into array.
  % @param {double} input_fft_length - The length of the forward FFT.
  % @param {struct} os_factor - The oversampling factor. This is a struct
  %   with members `nu` and `de` corresponding to the oversampling factor's
  %   numerator and denominator, respectively.
  % @param {struct} deripple_ - A struct containing filter coefficients
  %     used to channelize data. If the 'apply_deripple' struct flag is true,
  %     apply derippling correction or 'ripple equalization'.
  % @param {int} sample_offset_ - offset applied to channelized input prior to
  %   processing.
  % @return {double/single []} - Upsampled time domain output array. The
  %   dimensionaly will be (n_pol, 1, n_dat). Note that `n_dat` for the
  %   return array and the input array will not be the same
  tstart = tic;
  function overlap = default_calc_overlap(input_fft_length)
    overlap = round(input_fft_length*0.125);
  end

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

  if exist('calc_overlap_handler_', 'var')
    calc_overlap_handler = calc_overlap_handler_;
  else
    calc_overlap_handler = @default_calc_overlap;
  end

  if exist('window_handler_', 'var')
    window_handler = window_handler_;
  else
    window_handler = @default_window;
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
  end

  input_overlap = calc_overlap_handler(input_fft_length);
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


  FN_width = input_fft_length*os_factor.de/os_factor.nu;

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
  % j is complex number.
  % in Python we have to write 1j; this is not necessary in Matlab
  phase_shift_arr = [0,...
    j,...
    0.5 + (sqrt(3.0)/2.0)*j,...
    sqrt(3.0)/2.0 + 0.5i,...
    1,...
    sqrt(3.0)/2.0 - 0.5i,...
    0.5 - (sqrt(3.0)/2.0)*j,...
    -j
  ];
  % fig = figure;
  for i_pol=1:n_pol
    for n=1:n_blocks
      in_step_s = input_keep*(n-1) + 1;
      in_step_e = in_step_s + input_fft_length - 1;

      out_step_s = output_keep*(n-1) + 1;
      out_step_e = out_step_s + output_keep - 1;

      in_dat = squeeze(in(i_pol, :, in_step_s:in_step_e));
      % size(in_dat)
      % % zero first and last input_discard:
      % ax = subplot(2, 1, 1);
      % plot(abs(in_dat(:)));
      % ax = subplot(2, 1, 2);
      % plot(imag(in_dat(:)));
      % pause;
      in_dat = window_handler(in_dat, input_fft_length, input_overlap);
      % in_dat(:, 1:input_overlap) = complex(0, 0);
      % in_dat(:, (input_fft_length - input_overlap)+1:end) = complex(0, 0);
      % ax = subplot(2, 1, 2);
      % plot(abs(in_dat(:)));
      % pause

      spectra = transpose(in_dat);
      spectra = fft(spectra, input_fft_length); % fft operates on each of the columns
      spectra = fftshift(spectra, 1);
      spectra = fftshift(spectra, 2);
      FN = complex(zeros(FN_width, n_chan, dtype));
      for chan = 1:n_chan
        discard = (1.0 - (os_factor.de/os_factor.nu))/2.0;
        % phase_shift_arr(chan);
        % FN(:, chan) = spectra(round(discard*input_fft_length)+1:round((1.0-discard)*input_fft_length), chan).*phase_shift_arr(chan);
        FN(:, chan) = spectra(round(discard*input_fft_length)+1:round((1.0-discard)*input_fft_length), chan);
        if deripple.apply_deripple
          % applied_response = zeros(passband_length*2, 1);
          for ii = 1:passband_length
              % fprintf('%d, %d\n', ii, passband_length-ii+2)
              FN(ii,chan) = FN(ii,chan)*filter_response(passband_length-ii+2);
              FN(passband_length+ii,chan) = FN(passband_length+ii,chan)*filter_response(ii);
              % applied_response(ii) = filter_response(passband_length-ii+2);
              % applied_response(passband_length+ii) = filter_response(ii);
          end
          % figure
          % plot(applied_response);
          % pause
        end
      end
      % size(FN(:, 1))
      % catted = cat(1, FN(:, 1), FN(:, 2));
      % ax = subplot(211); plot(angle(catted)); grid(ax, 'on');
      % ax = subplot(212); plot(abs(catted)); grid(ax, 'on');
      % pause

      %% Combine chunks & back-transform

      FFFF = FN(FN_width/2+1:FN_width,1); % upper half of chan 1 is first part of FFFF
      for chan = 2 : n_chan
          FFFF = [FFFF; FN(:,chan)];
      end
      FFFF = [FFFF; FN(1:FN_width/2,1)]; % lower half of chan 1 is last part of FFFF
    	% back transform
      iFFFF = ifft(fftshift(FFFF))./(os_factor.nu/os_factor.de);


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
  if verbose
    tdelta = toc(tstart);
    fprintf('polyphase_synthesis: Elapsed time is %f seconds\n', tdelta);
  end
end
