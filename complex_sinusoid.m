function signal = complex_sinusoid (n_bins, frequencies, phases, bin_offset, dtype_)
  % generate a complex sinusoid that is the linear combination of sinusoids
  % with specified frequencies and phases.
  % @method complex_sinusoid
  % @param {double} n_bins - The length of the output array
  % @param {double []} frequencies - frequency components of resulting sinuosoid
  % @param {double []} phases - phase components corresponding to each frequency
  %   component
  % @param {double} bin_offset - Fractional offset from bin center
  % @return {double []} - complex sinusoid

  dtype = 'single';
  if exist('dtype_', 'var')
    dtype = dtype_;
  end

  t = 1:n_bins;
  signal = complex(zeros(1, n_bins, dtype));
  for i = 1:length(frequencies)
    signal = signal + exp(j*(2*pi*(frequencies(i) + bin_offset)/n_bins*t + phases(i)));
  end
end
