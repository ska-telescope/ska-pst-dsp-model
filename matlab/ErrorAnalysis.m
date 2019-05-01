classdef ErrorAnalysis
  % defines a collection of functions that can be used in analyzing error
  % between two time or frequency domain data series.
  methods
    function a = zero_max_val(obj, a)
      [max_val, argmax] = max(a);
      a(argmax) = 0;
    end

    function val = argmax(obj, a)
      [max_val, val] = max(a);
    end

    function val = max_spurious_power(obj, a)
      a = obj.zero_max_val(a);
      val = max(a);
    end

    function val = mean_spurious_power(obj, a)
      a = obj.zero_max_val(a);
      val =  mean(a);
    end

    function val = total_spurious_power(obj, a)
      a = obj.zero_max_val(a);
      val = sum(a);
    end
  end
end
