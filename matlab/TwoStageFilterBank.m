classdef TwoStageFilterBank < Channelizer
    % two stages of analysis polyphase filter banks
    
    properties
        stage1  (1,1) FilterBank
        stage2  (:,1) FilterBank
    end
   
    methods

        function obj = TwoStageFilterBank (config)
            % returns:
            %   obj = the configured FilterBank object
                 
            obj = obj@Channelizer;
            
            if  nargin > 0
            
              fprintf ('TwoStageFilterBank::configure analysis function=%s\n',...
                     config.analysis_function);
              obj.stage1 = FilterBank (config);
            
              for ichan = 1:obj.stage1.n_chan
                 obj.stage2(ichan) = FilterBank (config);
              end
            end
            
        end % of TwoStageFilterBank constructor

        function [obj, output] = execute (obj, input)
            % returns:
            %   obj      = the modified object
            %   output   = the output of the filter

            arguments
                obj     (1,1) TwoStageFilterBank
                input
            end

            [obj.stage1, output] = obj.stage1.execute (input);
            
        end % of execute function
    end % of methods section
end % of FilterBank class definition
