function out = polyphase_synthesis (in, input_fft_length, os_factor)
  % recombine channels that were created using polyphase filterbank.
  % Take into account any oversampling, and the number of received PFB channels
  % @method polyphase_synthesis
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

  in_size = size(in);
  n_pol = in_size(1);
  n_chan = in_size(2);
  n_dat = in_size(3);
  fprintf('polyphase_synthesis: n_pol=%d, n_chan=%d, n_dat=%d\n', n_pol, n_chan, n_dat);

  input_os_keep = normalize(os_factor, input_fft_length);
  output_fft_length = n_chan * input_os_keep;
  input_os_keep_2 = input_os_keep / 2;
  input_os_discard = input_fft_length - input_os_keep;
  input_os_discard_2 = input_os_discard / 2;

  n_blocks = floor(n_dat / input_fft_length);

  fprintf('polyphase_synthesis: n_blocks=%d, output_fft_length=%d\n', n_blocks, output_fft_length);

  out = complex(zeros(n_pol, 1, n_blocks*output_fft_length));

  stitched = complex(zeros(1, 1, output_fft_length));
  os_factor_float = os_factor.nu / os_factor.de;
  for i_block = 1:n_blocks
    for i_pol = 1:n_pol
      for i_chan = 1:n_chan
        freq_domain_i_chan = fft(in(i_pol,i_chan,(i_block-1)*input_fft_length+1:i_block*input_fft_length));
        idx_1_s = input_fft_length-input_os_keep_2+1;
        if i_chan == 1
          stitched(1:input_os_keep_2) = freq_domain_i_chan(idx_1_s:end);
          stitched(output_fft_length-input_os_keep_2+1:end) = freq_domain_i_chan(1:input_os_keep_2);
        else
          idx = (i_chan-2)*input_os_keep + input_os_keep_2;
          stitched(1, 1, idx+1: idx+input_os_keep_2) = freq_domain_i_chan(idx_1_s:end);
          idx = idx + input_os_keep_2;
          stitched(1, 1, idx+1: idx+input_os_keep_2) = freq_domain_i_chan(1:input_os_keep_2);
        end
      end
      out(i_pol, 1, (i_block-1)*output_fft_length+1:i_block*output_fft_length) = ifft(stitched)/os_factor_float;
    end
  end
end
