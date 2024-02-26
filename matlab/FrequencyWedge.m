classdef FrequencyWedge < Generator
    % two stages of analysis polyphase filter banks
    
    properties
        buffer              % samples to be output
        current = 0;        % current sample
        resolution = 1024 * 1024;
        slope
    end
   
    methods

        function obj = FrequencyWedge ()
            % returns:
            %   obj = new FrequencyWedge object

            obj = obj@Generator;
            obj.slope = sqrt(linspace(0,1,obj.resolution));

        end % of FrequencyWedge constructor

        function [obj, x] = generate (obj, nsample)
            % returns:
            %   obj = the modified object
            %   x   = the next nsample samples of the wave

            arguments
                obj     (1,1) FrequencyWedge
                nsample (1,1) {mustBeInteger, mustBeNonnegative}
            end
            
            nout = 0;
            x = complex(zeros(1,1,nsample,'single'));
            while (nout < nsample)

                if (obj.current == 0)
                    % generate an n-point spectrum of complex-valued noise
                    n = obj.resolution;
                    spectrum = randn([1 n],'single') + 1i*randn([1 n],'single');
                    % put a slope on it
                    spectrum = obj.slope .* spectrum;
                    obj.buffer = ifft(spectrum);
                end

                n = obj.resolution - obj.current;

                if (nout + n >= nsample)
                    n = nsample - nout;
                end

                % add n more random values to the output x
                x(1,1,nout+(1:n)) = obj.buffer(obj.current+(1:n));

                nout = nout + n;
                obj.current = obj.current + n;

                if (obj.current == obj.resolution)
                    obj.current = 0;
                end
            end
            
        end % of generate function
        
    end % of methods section
end % of FrequencyWedge class definition
