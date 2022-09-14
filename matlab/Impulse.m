classdef Impulse < Generator
    % generates complex-valued unit impulse
    
    properties
        offset = 0         % sample offset of delta
        amplitude = 1.0    % amplitude of waved
        current = 0        % current sample
    end
   
    methods
      
        function [obj, x] = generate (obj, nsample)
            % returns:
            %   obj = the modified object
            %   x   = the next nsample samples of the wave

            arguments
                obj     (1,1) Impulse
                nsample (1,1) {mustBeInteger, mustBeNonnegative}
            end
            
            off = obj.offset - obj.current;

            x = complex(zeros(1,1,nsample,'single'));
            
            if (off >= 0 && off < nsample)
                fprintf ('Impulse: at off=%d offset=%d current=%d\n', ...
                    off, obj.offset, obj.current);
                x(1,1,1+off) = obj.amplitude;
            else
                fprintf ('Impulse: no impulse\n')
                x(1,1,1) = 0.0;
            end
            
            obj.current = obj.current + nsample;
            
        end % of generate function
    end % of methods section
end % of SquareWave class definition
