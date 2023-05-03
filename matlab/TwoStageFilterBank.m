classdef TwoStageFilterBank < Channelizer
    % two stages of analysis polyphase filter banks
    
    properties
        stage1  (1,1) FilterBank
        stage2  (:,1) FilterBank
        critical = 0  % output critically sampled subset of channels
        single = 0    % output only channel 0
    end
   
    methods

        function obj = TwoStageFilterBank (config)
            % returns:
            %   obj = the configured FilterBank object
                 
            obj = obj@Channelizer;
            
            if nargin > 0
            
              fprintf ('TwoStageFilterBank::configure analysis function=%s\n',...
                     config.analysis_function);
              obj.stage1 = FilterBank (config);
            
              for ichan = 1:obj.stage1.n_chan
                 obj.stage2(ichan) = FilterBank (config);
              end
              
            end
                        
        end % of TwoStageFilterBank constructor

        function [obj, out] = execute (obj, input)
            % returns:
            %   obj      = the modified object
            %   output   = the output of the filter

            arguments
                obj     (1,1) TwoStageFilterBank
                input
            end

            fprintf ('TwoStageFilterBank::execute stage 1\n');
            [obj.stage1, out1] = obj.stage1.execute (input);
            
            os = obj.stage1.os_factor;
            
            nch1 = obj.stage1.n_chan;
            
            if (obj.critical)
                nch2 = (nch1 * os.de) / os.nu;
            else
                nch2 = nch1;
            end
            
            offset = (nch1 - nch2);
            
            if (obj.single == 1)
                nch1 = 1;
            end
            
            fprintf ('TwoStageFilterBank::execute stage 2 nch1=%d nch2=%d offset=%d\n',nch1,nch2,offset);
            for ich = 1:nch1
                
                 [obj.stage2(ich), tmp] = obj.stage2(ich).execute (out1(1,ich,:));
                 
                 if (ich == 1)
                     sz = size(tmp);
                     ndat = sz(3);
                     out = zeros(1,nch1*nch2,ndat,'single'); 
                 end
                 
                 % tmp[0] is DC and tmp[nch2/2] is Nyquist
                 % so chomp out oversampled channels in middle of array
                 out(1,(1:nch2/2)+(ich-1)*nch2,:) = tmp(1,1:nch2/2,:);
                 out(1,(nch2/2:nch2)+(ich-1)*nch2,:) = tmp(1,(nch2/2:nch2)+offset,:);

                 % if tmp[nchan/2] is DC, then keep middle of array
                 %out(1,(1:nch2)+(ich-1)*nch2,:) = tmp(1,(1:nch2)+offset/2,:);

            end
              
            % class(out)
            % out(1,2,1)
            
        end % of execute function
    end % of methods section
end % of FilterBank class definition
