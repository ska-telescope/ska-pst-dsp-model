% Used to explore frequency channel and harmonic order

classdef TestFrequencyComb < TestSignal
    
    properties
      frequencies
      os_factor = struct('nu', 8, 'de', 7)
      two_stage
    end
   
    methods
      
        function [obj, result] = test (obj, input)
            % returns:
            %   obj = the modified object
            %   result = the test result (pass < 1; fail > 1)

            arguments
                obj     (1,1) TestFrequencyComb
                input   % time samples to be tested
            end
            
            input_size = size(input);
            nchan = input_size(2);
            npol = input_size(1);

            max_nfft = 8 * 1024;

            fsize = size(obj.frequencies);
            nharm = fsize(1);

            % fprintf ('TestFrequencyComb: harmonics=%d \n', nharm)

            for ipol = 1:npol
                for ichan = 1:nchan

                    x=squeeze( input(ipol,ichan,:) );
                    size_x = size(x);
                    nfft = size_x(1);

                    % fprintf ('TestFrequencyComb: nfft=%d \n', nfft)

                    if (nfft > max_nfft)
                        nfft = max_nfft;
                        x=x(1:nfft);
                    end

                    fft_in = abs(fft(x)./(nfft*nchan));

                    hfac = normalize(obj.os_factor,nchan*nfft);
                    if (obj.two_stage)
                        hfac = normalize(obj.os_factor,hfac);
                    end

                    % figure
                    % plot(fft_in)
                    % pause

                    for i = 1:nharm
                        jchan = floor(obj.frequencies(i) * nchan);
                        jchan = mod(jchan+nchan, nchan);
                        jchan = jchan + 1;

% fprintf ('iharm=%d -> jchan=%d \n', i, jchan)

                        if (jchan == ichan)
                            offset = (ichan-1)/nchan;

% fprintf ('offset=%f = %f -- %f\n', ...
%   obj.frequencies(i)-offset,(obj.frequencies(i)-offset)*nfft,1.0/nchan)

                            iharm = round( (obj.frequencies(i)-offset)*hfac );
                            iharm = mod (iharm+nfft, nfft);
                            iharm = iharm + 1;

% fprintf ('TestFrequencyComb: test harmonic[%d]=%f in chan=%d offset=%f i=%d\n', ...
  % i, obj.frequencies(i), ichan, offset, iharm);

                            if ( fft_in(iharm) < 0.5 )
                                fprintf ('TestFrequencyComb: did not detect expected harmonic[%d]=%f \n', i, obj.frequencies(i))
                                fprintf ('  in chan=%d offset=%f i=%d nfft=%d\n', ichan, offset, iharm, nfft)
                                result = -1;

figure
plot(fft_in)
pause
                                return;
                            end
                        end
                    end
                end
            end

            result = 0;

        end % of test function
    end % of methods section
end % of TestFrequencyComb class definition
