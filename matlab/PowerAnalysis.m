classdef PowerAnalysis
  % defines a collection of functions that can be used to analyze power
  % of time series/spectra

  methods
    function b = dB(obj, a)
      b = abs(a);
      b = b / max(b);
      b = 20.0.*log10(abs(a) + 1e-13);
    end
  end
end
