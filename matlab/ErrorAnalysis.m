classdef ErrorAnalysis
  % Defines a collection of functions that can be used in analyzing error
  % between two time or frequency domain data series.
  methods

    function a = zero_max_val(obj, a, domain_)
      % Zero the bin where the maximum value of an array occurs, or zero a
      % range of bins on either side of the position of the maximum value if
      % ``domain_`` is specified.
      %
      % Args:
      %   a (numeric): The array to zero
      %   domain_ (numeric): Optional. The number of bins *on either side* of the
      %     position of the maximum value to zero
      % Returns:
      %   numeric: input array ``a`` with zeroed bins.

      domain = 0;
      if exist('domain_', 'var')
        domain = domain_;
      end

      [max_val, argmax] = max(a);
      n=size(a);
      fprintf('max: idx=%d n=%d\n', argmax, n);
      
      low = argmax - domain;
      if (low < 1)
        low = 1;
      end

      high = argmax + domain;
      if (high > length(a))
        high = length(a);
      end
      a(low:high) = 0;
    end

    function val = argmax(obj, a)
      [max_val, val] = max(a);
    end

    function val = max_spurious_power(obj, a, varargin)
      a = obj.zero_max_val(a, varargin{:});
      val = max(a);
    end

    function val = mean_spurious_power(obj, a, varargin)
      a = obj.zero_max_val(a, varargin{:});
      val =  mean(a);
    end

    function val = total_spurious_power(obj, a, varargin)
      a = obj.zero_max_val(a, varargin{:});
      val = sum(a);
    end
  end
end
