function sig = complex_sinusoid_fft(numFreqBins,freqBinOffset,phase,dtype)
  % Generates a complex sinusoid by inverse-FFT'ing a frequency-domain vector
  % containing one delta function.
  %
  % Args:
  %    numFreqBins (int): length of frequency-domain vector
  %       (and the corresponding output time-domain vector)
  %    freqBinOffset (int): the bin number in which the delta function is placed
  %    phase (single/double): phase of sinusoid (0 to 2pi)
  %
  % Returns:
  %    sig - a vector of complex doubles of length numFreqBins

  % Initialize frequency vector
  freqVector = complex(zeros(numFreqBins,1, dtype));

  % Introduce a delta in the specified bin - with required phase rotation
  freqVector(freqBinOffset) = cos(phase) + 1i*sin(phase);

  % figure;
  % subplot(211); plot((1:numFreqBins),abs(freqVector(1:numFreqBins,1))); box on; grid on; title('sig Mag');
  % subplot(212); plot((1:numFreqBins),phase(freqVector(1:numFreqBins,1))); box on; grid on; title('sig Phase'); xlabel('frequency');

  % sig = ifft(fftshift(freqVector)).*numFreqBins;
  sig = ifft(freqVector).*numFreqBins;


end
