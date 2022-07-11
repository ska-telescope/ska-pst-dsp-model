classdef PureTone < Generator
    % generates complex-valued sinusoide
    
    properties
        period = 26.5      % number of samples in one cycle of wave
        amplitude = 1.0    % amplitude of waved
        current = 0        % current sample
    end
   
    methods
      
        function [obj, x] = generate (obj, nsample)
            % returns:
            %   obj = the modified object
            %   x   = the next nsample samples of the wave

            arguments
                obj     (1,1) PureTone
                nsample (1,1) {mustBeInteger, mustBeNonnegative}
            end
            
            freq = 1.0/obj.period;
            t = 0:nsample-1;
            x = complex(zeros(1,1,nsample,'single'));
            x(1,1,:) = exp(j*(2*pi*freq*(t+obj.current)));  
            
            obj.current = obj.current + nsample;
            
        end % of generate function
    end % of methods section
end % of SquareWave class definition
