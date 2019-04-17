function out = polyphase_synthesis_alt (in, input_fft_length, os_factor, sample_offset_)
  % recombine channels that were created using polyphase filterbank.
  % Take into account any oversampling, and the number of received PFB channels
  %
  % This code is adapted from code written by Ian Morrison to analyze spectral
  % and temporal purity of the PFB inversion technique.
  %
  % @method polyphase_synthesis_alt
  % @param {double/single []} in - Input array. The dimensionality should be
  %   (n_pol, n_chan, n_dat). Whether the data are complex or real is built
  %   into array.
  % @param {double} input_fft_length - The length of the forward FFT.
  % @param {struct} os_factor - The oversampling factor. This is a struct
  %   with members `nu` and `de` corresponding to the oversampling factor's
  %   numerator and denominator, respectively.
  % @return {double/single []} - Upsampled time domain output array. The
  %   dimensionaly will be (n_pol, 1, n_dat). Note that `n_dat` for the
  %   return array and the input array will not be the same

  sample_offset = 1;
  if exist('sample_offset_', 'var')
    sample_offset = sample_offset_;
  end

  in = in(:, :, sample_offset:end);

  size_in = size(in);
  n_pol = size_in(1);
  n_chan = size_in(2);
  n_dat = size_in(3);
  dtype = class(in);
  n_blocks = floor(n_dat / input_fft_length);
  fprintf('polyphase_synthesis_alt: n_pol=%d, n_chan=%d, n_dat=%d\n', n_pol, n_chan, n_dat);

  output_fft_length = normalize(os_factor, input_fft_length) * n_chan;
  out = complex(zeros(n_pol, 1, n_blocks*output_fft_length, dtype));

  fprintf('polyphase_synthesis_alt: n_blocks=%d, output_fft_length=%d, sample_offset=%d\n', n_blocks, output_fft_length, sample_offset);

  FN_width = input_fft_length*os_factor.de/os_factor.nu;

  phase_shift_arr = [0,...
    1j,...
    0.5 + (sqrt(3.0)/2.0)*1j,...
    sqrt(3.0)/2.0 + 0.5i,...
    1,...
    sqrt(3.0)/2.0 - 0.5i,...
    0.5 - (sqrt(3.0)/2.0)*1j,...
    -1j
  ];


  for i_pol=1:n_pol
    for n=1:n_blocks
      in_step_s = input_fft_length*(n-1)+1;
      in_step_e = input_fft_length*n;
      out_step_s = output_fft_length*(n-1)+1;
      out_step_e = output_fft_length*n;
      spectra = transpose(squeeze(in(i_pol, :, in_step_s:in_step_e)));
      spectra = fft(spectra); % fft operates on each of the columns
      spectra = fftshift(spectra, 1);
      spectra = fftshift(spectra, 2);
      FN = complex(zeros(FN_width, n_chan, dtype));
      for chan = 1:n_chan
        discard = (1.0 - (os_factor.de/os_factor.nu))/2.0;
        phase_shift_arr(chan);
        % FN(:, chan) = spectra(round(discard*input_fft_length)+1:round((1.0-discard)*input_fft_length), chan).*phase_shift_arr(chan);
        FN(:, chan) = spectra(round(discard*input_fft_length)+1:round((1.0-discard)*input_fft_length), chan);
        % if (equaliseRipple)
        %     for ii = 1:passbandLength
        %         % fprintf('%d, %d\n', ii, passbandLength-ii+2)
        %         FN(ii,chan) = FN(ii,chan)*deripple(passbandLength-ii+2);
        %         FN(passbandLength+ii,chan) = FN(passbandLength+ii,chan)*deripple(ii);
        %     end;
        % end;
      end

      %% Combine chunks & back-transform

      FFFF = FN(FN_width/2+1:FN_width,1); % upper half of chan 1 is first part of FFFF
      for chan = 2 : n_chan
          FFFF = [FFFF; FN(:,chan)];
      end
      FFFF = [FFFF; FN(1:FN_width/2,1)]; % lower half of chan 1 is last part of FFFF
    	% back transform
      out(i_pol, 1, out_step_s:out_step_e) = ifft(fftshift(FFFF))./(os_factor.nu/os_factor.de);  % re-scale by OS factor
      % out(i_pol, 1, out_step_s:out_step_e) = ifft(FFFF)./(os_factor.nu/os_factor.de);  % re-scale by OS factor
    end
end
