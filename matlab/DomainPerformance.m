classdef DomainPerformance
  % Defines methods that determine the numerical performance of the PFB inversion
  % algorithm
  methods

    function res = temporal_difference(obj, a, b)
      diff = abs(a - b).^2;
      res = [max(diff), sum(diff), mean(diff)];
    end


    function res = temporal_performance(obj, a, varargin)
      err = ErrorAnalysis;
      % fprintf('max(a)=%f', max(abs(a)));
      a = abs(a).^2;
      % fprintf(' max(a.^2)=%f\n', max(abs(a).^2));
      % res = [err.max_spurious_power(a),...
      %        err.total_spurious_power(a),...
      %        err.mean_spurious_power(a)];
      res = [err.max_spurious_power(a, varargin{:}),...
             err.total_spurious_power(a, varargin{:})];
    end

    function res = spectral_performance(obj, a, fft_length, varargin)
      err = ErrorAnalysis;
      a_fft = abs(fft(a, fft_length)./fft_length).^2;
      % res = [err.max_spurious_power(a_fft),...
      %        err.total_spurious_power(a_fft),...
      %        err.mean_spurious_power(a_fft)];
      res = [err.max_spurious_power(a_fft, varargin{:}),...
             err.total_spurious_power(a_fft, varargin{:})];
    end
  end
end
