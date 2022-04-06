classdef DomainPerformance
  % Defines methods that determine the numerical performance of the PFB inversion
  % algorithm
  methods

    function res = temporal_difference(obj, a, b)

      plot_things = 0;
      if (plot_things == 1)
        figure;
        ax = subplot(321);
        plot(real(a(1:100)))
        grid(ax, 'on');
        title('real[input]');
        
        ax = subplot(323);
        plot(real(b(1:100)))
        grid(ax, 'on');
        title('real[inverted]');
        
        ax = subplot(325);
        plot(real(a(1:100))-real(b(1:100)))
        grid(ax, 'on');
        title('real[diff]');
        
        ax = subplot(322);
        plot(imag(a(1:100)))
        grid(ax, 'on');
        title('imag[input]');
        
        ax = subplot(324);
        plot(imag(b(1:100)))
        grid(ax, 'on');
        title('imag[inverted]');
        
        ax = subplot(326);
        plot(imag(a(1:100))-imag(b(1:100)))
        grid(ax, 'on');
        title('imag[diff]');
        pause;
      end
      
      diff = abs(a - b).^2;
      %
      % Any change to the following list of N statistics included in res
      % should be reflected in the first N elements of names_spectral
      % (currently defined at line 112 of current_performance.m)
      %
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
      
      %
      % Any change to the following list of statistics included
      % in res should be reflected in names_temporal
      % (currently defined at line 109 of current_performance.m)
      %
      res = [err.max_spurious_power(a, varargin{:}),...
             err.total_spurious_power(a, varargin{:})];
    end

    function res = spectral_performance(obj, a, fft_length, varargin)
      err = ErrorAnalysis;
      a_fft = abs(fft(a, fft_length)./fft_length).^2;
      % res = [err.max_spurious_power(a_fft),...
      %        err.total_spurious_power(a_fft),...
      %        err.mean_spurious_power(a_fft)];
      
      %
      % Any change to the following list of M statistics included in res
      % should be reflected in the last M elements of names_spectral
      % (currently defined at line 112 of current_performance.m)
      %
      res = [err.max_spurious_power(a_fft, varargin{:}),...
             err.total_spurious_power(a_fft, varargin{:})];
    end
  end
end
