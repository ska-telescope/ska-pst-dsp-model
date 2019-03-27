function out = polyphase_synthesis_alt (in, input_fft_length, os_factor)
  % recombine channels that were created using polyphase filterbank.
  % Take into account any oversampling, and the number of received PFB channels
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

end
