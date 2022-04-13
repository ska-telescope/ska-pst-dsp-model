classdef SquareWave
   % outputs amplitude-modulated noise
   properties
      period = 26        % samples
      duty_cycle = 0.5   % duty cycle of the square wave
      on_amp = 1.0       % standard deviation of on-pulse noise
      off_amp = 0.0      % standard deviation of off-pulse noise
      current = 0        % current sample
   end
   methods
      function [obj, x] = generate (obj, nsample)
      arguments
         obj     (1,1) SquareWave
         nsample (1,1) {mustBeInteger, mustBeNonnegative}
      end
         % return the next nsample samples of the wave
         iphase = mod(obj.current, obj.period);
         fprintf ('current=%d iphase=%d\n', obj.current, iphase);
         x = linspace (obj.current, obj.current+nsample, nsample);
         obj.current = obj.current + nsample;
         fprintf ('current=%d\n', obj.current);

      end
   end
end
