classdef TwoStageFilterBank < Channelizer
    % two stages of analysis polyphase filter banks
    
    properties
        stage1  (1,1) FilterBank
        stage2  (:,1) FilterBank
        single = 0
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
            
            obj.single = 1;
            
        end % of TwoStageFilterBank constructor

        function [obj, out] = execute (obj, input)
            % returns:
            %   obj      = the modified object
            %   output   = the output of the filter

            arguments
                obj     (1,1) TwoStageFilterBank
                input
            end

            fprintf ('stage 1\n');
            [obj.stage1, out1] = obj.stage1.execute (input);
            
            os = obj.stage1.os_factor;
            
            nch1 = obj.stage1.n_chan;
            nch2 = (nch1 * os.de) / os.nu;
            offset = (nch1 - nch2) / 2;
            
            fprintf ('stage 2 nch2=%d offset=%d\n',nch2,offset);
            for ich = 1:nch1
                
                 [obj.stage2(ich), tmp] = obj.stage2(ich).execute (out1(1,ich,:));
                 
                 if (ich == 1)
                     sz = size(tmp);
                     ndat = sz(3);
                     out = zeros(1,nch1*nch2,ndat); 
                 end
                 
                 out(1,(1:nch2)+(ich-1)*nch2,:) = tmp(1,(1:nch2)+offset,:);
                 
            end
              
        end % of execute function
    end % of methods section
end % of FilterBank class definition
