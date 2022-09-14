% Verifies SKAO-CSP_Mid_PST_REQ-386 and SKAO-CSP_Low_PST_REQ-697

% SKAO-CSP_Low_PST_REQ-697
% https://skaoffice.jamacloud.com/perspective.req#/items/904175?projectId=335
% After channelization inversion, the maximum power of the temporal leakage 
% of the narrowest possible impulse response function of the CSP_Low.PST 
% shall be less than −4 Δt dB for temporal offsets between 1 and 15 microseconds, 
% and less than -60 dB (power ratio) for larger temporal offsets. 
% Here Δt is the absolute time difference in microseconds between the centre
% of the impulse response function and the time offset at which the leakage is measured.

% SKAO-CSP_Mid_PST_REQ-386
% https://skaoffice.jamacloud.com/perspective.req#/items/904438?projectId=335
% After channelization inversion, the maximum power of the temporal leakage 
% of the narrowest possible impulse response function of the CSP_Mid.PST 
% shall be less than −200 Δt dB for temporal offsets from 20 to 300 nanoseconds, 
% and less than -60 dB (power ratio) for larger temporal offsets. 
% Here Δt is the absolute time difference in microseconds between the centre 
% of the impulse response function and the time offset at which the leakage is measured.

classdef TestImpulse < TestSignal
    
    properties
        offset = 0         % sample offset of delta
        current = 0        % current sample
        dB_max = -60;
    end
   
    methods
      
        function [obj, result] = test (obj, input)
            % returns:
            %   obj = the modified object
            %   result = the test result (pass < 1; fail > 1)

            arguments
                obj     (1,1) TestImpulse
                input   % time samples to be tested
            end
            
            input_size = size(input);
            nsample = input_size(3);
            nchan = input_size(2);
            npol = input_size(1);

            off = obj.offset - obj.current + 1;

            for ipol = 1:npol
                for ichan = 1:nchan

                    x=squeeze( input(ipol,ichan,:) );

                    [vmax,imax] = max(x);
                    fprintf ('TestImpulse imax=%d expect=%d \n',imax,off);

                    % add one for matlab array index convention
                    exp_index = off + 1;

                    amp_dB = 20 * log10(abs(x));
                    %figure
                    %plot(amp_dB)
                    %pause

                    for i = 1:nsample
                        if (i < off-1 || i > off+1)
                            dB = amp_dB(i);
                            if (dB > obj.dB_max)
                                fprintf ('TestImpulse fail off=%d i=%d dB=%f', off,i,dB)
                                result = -1;
                                return;
                            end
                        end
                    end
                end
            end

            obj.current = obj.current + nsample;
            result = 0;
            
        end % of test function
    end % of methods section
end % of TestImpulse class definition
