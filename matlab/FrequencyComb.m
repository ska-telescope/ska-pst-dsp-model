classdef FrequencyComb < Generator
    % two stages of analysis polyphase filter banks
    
    properties
        tone  (:,1) PureTone
        ntone = 0
    end
   
    methods

        function obj = FrequencyComb (amplitudes, frequencies)
            % returns:
            %   obj = new FrequencyComb object

            obj = obj@Generator;
            
            sz = size(amplitudes);
            obj.ntone = sz(1);
            
            fprintf ("ntone=%u\n", obj.ntone);
            
            for itone = 1:obj.ntone
                 obj.tone(itone) = PureTone;
                 fprintf ( "i=%u amp=%f frequency=%f \n",...
                     itone, amplitudes(itone), frequencies(itone) );
                 obj.tone(itone).amplitude = amplitudes(itone);
                 obj.tone(itone).frequency = frequencies(itone);
            end
                        
        end % of FrequencyComb constructor

        function [obj, x] = generate (obj, nsample)
            % returns:
            %   obj = the modified object
            %   x   = the next nsample samples of the wave

            arguments
                obj     (1,1) FrequencyComb
                nsample (1,1) {mustBeInteger, mustBeNonnegative}
            end
            
            x = complex(zeros(1,1,nsample,'single'));
            for itone = 1:obj.ntone
                [obj.tone(itone), tmp] = generate (obj.tone(itone), nsample);
                x = x + tmp;
            end
            
        end % of generate function
        
    end % of methods section
end % of FrequencyComb class definition
