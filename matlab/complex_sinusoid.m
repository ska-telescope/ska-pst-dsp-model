function signal = complex_sinusoid(n_bins, frequencies, phases, bin_offset, dtype_)
  % generate a complex sinusoid that is the linear combination of sinusoids
  % with specified frequencies and phases.
  %
  % Example:
  %
  %   >> complex_sinusoid(100, [1, 10], [pi/4, pi/4], 0.1, 'single');
  %
  % Args:
  %   n_bins ([double]): The length of the output array
  %   frequencies ([double]): frequency components of resulting sinuosoid
  %   phases ([double]): phase components corresponding to each frequency
  %     component
  %   bin_offset (double): Fractional offset from bin center
  %   dtype_ (string): Data type of return array.
  % Returns:
  %  [dtype]: array containing complex sinusoid

  dtype = 'single';
  if exist('dtype_', 'var')
    dtype = dtype_;
  end

  t = 0:n_bins-1;
  signal = complex(zeros(1, n_bins, dtype));
  for i = 1:length(frequencies)
    signal = signal + exp(j*(2*pi*(frequencies(i) + bin_offset)/n_bins*t + phases(i)));
  end
end
