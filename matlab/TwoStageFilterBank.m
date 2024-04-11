classdef TwoStageFilterBank < Channelizer
    % two stages of analysis polyphase filter banks
    
    properties
        stage1  (1,1) FilterBank
        stage2  (:,1) FilterBank
        config1 = containers.Map();
        config2 = containers.Map();
        nch1 = 0    % number of channels output by stage 1 filter bank
        nch2 = 0    % number of channels output by stage 2 filter bank                
        critical = 0  % output critically sampled subset of channels
        single = 0    % output only channel 0
        built = false
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
              obj.config1 = config;
              obj.config2 = config;              
              obj.nch1 = config.channels;
              obj.nch2 = config.channels;
            end
                        
        end % of TwoStageFilterBank constructor

        function obj = set_stage2_config (obj, config)
            arguments
                obj     (1,1) TwoStageFilterBank
                config   % name of analysis filterbank configuration
            end
            obj.config2 = config;
            obj.nch2 = config.channels;

        end % of TwoStageFilterBank::set_stage2_config

        function obj = build (obj)
            arguments
                obj     (1,1) TwoStageFilterBank
            end
            
            for ichan = 1:obj.stage1.n_chan
                obj.stage2(ichan) = FilterBank (obj.config2);
            end 
            obj.built = true;

        end % of TwoStageFilterBank::build

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

            if ~obj.built
                obj = build(obj);
            end

            os = obj.stage1.os_factor;
            
            nch1 = obj.stage1.n_chan;
            nch2_orig = obj.stage2(1).n_chan;
            nch2 = nch2_orig;

            if (obj.critical)
                nch2 = (nch2_orig * os.de) / os.nu;
            end
            
            offset = (nch2_orig - nch2);
            
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

            out = complex(out);
            % class(out)
            % out(1,2,1)
            
        end % of execute function
    end % of methods section
end % of FilterBank class definition
