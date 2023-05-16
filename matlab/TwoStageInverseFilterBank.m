classdef TwoStageInverseFilterBank < DeChannelizer
    % two stages of analysis polyphase filter banks
    
    properties
        stage1  (1,1) InverseFilterBank
        stage2  (:,1) InverseFilterBank
        config1 = containers.Map();
        config2 = containers.Map();
        nch1 = 0    % number of channels output by stage 1 filter bank
        nch2 = 0    % number of channels output by stage 2 filter bank        
        single = 0  % output only a single coarse channel
        combine = 1 % number of coarse channels combined on inversion
        built = false
    end
   
    methods

        function obj = TwoStageInverseFilterBank (config)
            % returns:
            %   obj = new TwoStageInverseFilterBank object
                 
            obj = obj@DeChannelizer;

            fprintf ('TwoStageInverseFilterBank::configure analysis function=%s\n',...
                     config.analysis_function);
            obj.config1 = config;
            obj.config2 = config;
            obj.stage1 = InverseFilterBank (config);
            obj.nch1 = config.channels;
            obj.nch2 = config.channels;
            obj.built = false;

        end % of TwoStageInverseFilterbank constructor
        
        function obj = set_stage2_config (obj, config)
            arguments
                obj     (1,1) TwoStageInverseFilterBank
                config   % name of analysis filterbank configuration
            end
            obj.config2 = config;
            obj.nch2 = config.channels;

        end % of TwoStageInverseFilterBank::set_stage2_config

        function obj = build (obj)
            arguments
                obj     (1,1) TwoStageInverseFilterBank
            end
            
            for ichan = 1:obj.nch1
                obj.stage2(ichan) = InverseFilterBank (obj.config2);
            end 
            obj.built = true;

        end % of TwoStageInverseFilterBank::build

        function obj = frequency_taper (obj, name)
            % returns:
            %   obj = new TwoStageInverseFilterBank object
                 
            arguments
                obj     (1,1) TwoStageInverseFilterBank
                name    % name of taper function
            end
            
            if ~obj.built
                obj = build(obj);
            end
            for ichan = 1:obj.nch1
                obj.stage2(ichan) = obj.stage2(ichan).frequency_taper(name);
            end
                        
        end % of TwoStageInverseFilterBank::f_taper

        function [obj, out] = execute (obj, input)
            % returns:
            %   obj      = the modified object
            %   output   = the output of the filter

            arguments
                obj     (1,1) TwoStageInverseFilterBank
                input
            end

            if ~obj.built
                obj = build(obj);
            end

            os = obj.stage1.os_factor;            
            
            sz = size(input);
            nchan = sz(2);

            nch_out = nchan / obj.nch2;
                                    
            fprintf ('TwoStageInverseFilterBank::execute invrt 2 nch_in=%d nch_out=%d nch2=%d\n',...
                nchan,nch_out,obj.nch2);

            critical = false;
            
            if obj.nch2 == normalize(os, obj.stage2(1).nchan)
                fprintf ('TwoStageInverseFilterBank::execute critical\n');
                critical = true;
            elseif obj.nch2 == obj.stage2(1).nchan
                fprintf ('TwoStageInverseFilterBank::execute oversampled\n');
                if (obj.combine > 1)
                    error ('TwoStageInverseFilterBank::execute cannot combine oversampled coarse channels');
                end
            else
                error ('TwoStageInverseFilterBank::execute invalid nchan');
            end
            
            nch_in = obj.nch2 * obj.combine;
            nch_out = nch_out / obj.combine;

            if (obj.single)
                nch_out = 1;
            end

            for ich = 1:nch_out
                
                intmp = input(1,(1:nch_in)+(ich-1)*nch_in,:);
                
                obj.stage2(ich).critical = critical;
                obj.stage2(ich).combine = obj.combine;

                [obj.stage2(ich), tmp] = obj.stage2(ich).execute (intmp);
                
                if (ich == 1)  
                    
                    if isreal(intmp)
                        error ('input data are real !');
                    end
                    
                    if isreal(tmp)
                        error ('stage2 output data are real');
                    end
                    
                   sz = size(tmp);
                   ndat = sz(3);
                   out = complex(zeros(1,nch_out,ndat));
                   
                end
                 
                out(1,ich,:) = tmp(1,1,:);
                 
            end
            
            if isreal(tmp)
                error ('output data are real !!!');
            end
            
        end % of execute function
    end % of methods section
end % of TwoStageInverseFilterBank class definition
