classdef SquareWave < Generator
    % generates amplitude-modulated noise
    
    properties
        period = 26        % number of samples in one cycle of wave
        duty_cycle = 0.5   % duty cycle of the square wave
        on_amp = 1.0       % standard deviation of on-pulse noise
        off_amp = 0        % standard deviation of off-pulse noise
        current = 0        % current sample
    end
   
    methods
      
        function [obj, x] = generate (obj, nsample)
            % returns:
            %   obj = the modified object
            %   x   = the next nsample samples of the wave

            arguments
                obj     (1,1) SquareWave
                nsample (1,1) {mustBeInteger, mustBeNonnegative}
            end
            
            ioff = floor (obj.period*obj.duty_cycle);
            nout = 0;
            x = complex(zeros(1,1,nsample,'single'));
            % fprintf ('SquareWave::generate ' ); size(x)

            while (nout < nsample)
                
                iphase = mod (obj.current, obj.period);
                
                if (iphase < ioff)
                    % on-pulse
                    n = ioff-iphase;
                    a = sqrt(obj.on_amp * 0.5);
                else
                    % off-pulse
                    n = obj.period - iphase;
                    a = sqrt(obj.off_amp * 0.5);
                end
                
                if (nout + n >= nsample)
                    n = nsample - nout;
                end
                
                % add n more random values to the output x
                if (a > 0)
                    x(1,1,nout+(1:n)) ...
                        = a*(randn([1 n],'single') + 1i*randn([1 n],'single'));
                end

                % fprintf ('SquareWave::generate ' ); size(x)
                
                nout = nout + n;
                obj.current = obj.current + n;
                
            end % of loop over remaining samples

            if isreal(x)
                error ('SquareWave::generate produced real-valued result');
            end

        end % of generate function
    end % of methods section
end % of SquareWave class definition
