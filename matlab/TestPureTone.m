% Verifies SKAO-CSP_Mid_PST_REQ-385 and SKAO-CSP_Low_PST_REQ-627

% SKAO-CSP_Low_PST_REQ-627
% https://skaoffice.jamacloud.com/perspective.req#/items/904175?projectId=335
% After channelization inversion, the maximum spurious response to a pure tone 
% within the bandwidth output by CSP_Low.PST shall be no more than -60 dB (power ratio).

% SKAO-CSP_Mid_PST_REQ-385
% https://skaoffice.jamacloud.com/perspective.req#/items/904436?projectId=335
% After channelization inversion, the maximum spurious response to a pure tone 
% within the bandwidth output by CSP_Mid.PST shall be no more than -60 dB (power ratio).

classdef TestPureTone < TestSignal
    
    properties
        frequency = 1/26.5 % cycles per sample

        % SKAO-CSP_Mid_PST_REQ-385 and SKAO-CSP_Low_PST_REQ-627
        dB_max = -60;
    end
   
    methods
      
        function [obj, result] = test (obj, input)
            % returns:
            %   obj = the modified object
            %   result = the test result (pass < 1; fail > 1)

            arguments
                obj     (1,1) TestPureTone
                input   % time samples to be tested
            end
            
            input_size = size(input);
            nchan = input_size(2);
            npol = input_size(1);

            max_nfft = 8 * 1024 * 1024;

            for ipol = 1:npol
                for ichan = 1:nchan

                    x=squeeze( input(ipol,ichan,:) );
                    size_x = size(x);
                    nfft = size_x(1);

                    if (nfft > max_nfft)
                        nfft = max_nfft;
                        x=x(1:nfft);
                    end

                    % add one for matlab array index convention
                    exp_index = obj.frequency * nfft + 1;

                    fft_dB = 20 * log10(abs(fft(x)./nfft));

                    [a_max,a_index] = max(fft_dB);

                    fft_dB = fft_dB - a_max;
                    figure
                    plot(fft_dB)
                    pause

                    if ( a_index ~= exp_index )

                        alt_index = nfft/2 + exp_index;
                        if ( a_index == alt_index )
                            fprintf ('TestPureTone: bandswap detected \n');
                        else
                            fprintf ('TestPureTone: unexpected max index=%d (expected=%d nfft=%d)\n',...
                                a_index, exp_index, nfft);
                            result = -1;
                            return;
                        end

                    end

                    dB_avg = 0;
                    for i = 1:nfft
                        if (i ~= a_index)
                            dB = fft_dB(i);
                            if (dB > obj.dB_max)
                                fprintf ('TestPureTone fail i=%d dB=%lf', i,dB)
                                result = -1;
                                return;
                            end
                            dB_avg = dB_avg + dB;
                        end
                    end

                    dB_avg = dB_avg/(nfft-1);
                end
            end

            result = 0;

        end % of test function
    end % of methods section
end % of TestPureTone class definition
