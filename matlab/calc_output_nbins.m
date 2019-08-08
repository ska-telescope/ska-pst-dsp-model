function nbins=calc_output_nbins(nbins, channels, os_factor, filter_taps, input_fft_length, input_overlap)
  % given some number of input bins, calculate how many will emerge after
  % channelization and inversion.
  %
  % Args:
  %   nbins (numeric): the number of input bins
  %   channels (numeric): the number of channels the channeliser will create
  %   os_factor (struct): os factor struct
  %   filter_taps (numeric): The number of filter taps
  %   input_fft_length (numeric): The FFT length applied to fine channels during
  %     channelisation
  %   input_overlap (numeric): The overlap discard region applied to fine channels
  %     during channelisation
  % Returns:
  %   numeric: The number of inverted bins

  step = floor((channels * os_factor.de) / os_factor.nu);
  nblocks_pfb = floor((nbins - filter_taps)/step);
  output_pfb = floor((step * nblocks_pfb)/channels);

  input_keep = input_fft_length - 2*input_overlap;
  nblocks_ipfb = floor((output_pfb - 2*input_overlap) / input_keep);

  output_fft_length = normalize(os_factor, input_fft_length) * channels;
  output_overlap = normalize(os_factor, input_overlap) * channels;
  output_keep = output_fft_length - 2*output_overlap;
  nbins = output_keep * nblocks_ipfb;
end
