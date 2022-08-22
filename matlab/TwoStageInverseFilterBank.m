classdef TwoStageInverseFilterBank < DeChannelizer
    % two stages of analysis polyphase filter banks
    
    properties
        stage1  (1,1) InverseFilterBank
        stage2  (:,1) InverseFilterBank
        nch1 = 0    % number of channels output by stage 1 filter bank
        single = 0  % output only a single coarse channel
        combine = 1 % number of coarse channels combined on inversion
    end
   
    methods

        function obj = TwoStageInverseFilterBank (config)
            % returns:
            %   obj = new TwoStageInverseFilterBank object
                 
            obj = obj@DeChannelizer;
            
            if nargin > 0
            
              fprintf ('TwoStageInverseFilterBank::configure analysis function=%s\n',...
                     config.analysis_function);
              obj.stage1 = InverseFilterBank (config);
            
              obj.nch1 = config.channels;
              
              for ichan = 1:obj.nch1
                 obj.stage2(ichan) = InverseFilterBank (config);
              end
              
            end
                        
        end % of TwoStageInverseFilterBank constructor

        function [obj, out] = execute (obj, input)
            % returns:
            %   obj      = the modified object
            %   output   = the output of the filter

            arguments
                obj     (1,1) TwoStageInverseFilterBank
                input
            end
            
            os = obj.stage1.os_factor;            
            
            sz = size(input);
            nchan = sz(2);

            nch1 = obj.nch1;
            
            nch2 = nchan / nch1;
                        
            fprintf ('invrt 2 nch1=%d nchan=%d nch2=%d\n',nch1,nchan,nch2);

            critical = false;
            
            if (nch2 == (obj.nch1 * os.de) / os.nu)
                fprintf ('TwoStageInverseFilterBank::execute critical\n');
                critical = true;
            elseif (nch2 == obj.nch1)
                fprintf ('TwoStageInverseFilterBank::execute oversampled\n');
                if (obj.combine > 1)
                    error ('TwoStageInverseFilterBank::execute cannot combine oversampled coarse channels');
                end
            else
                error ('TwoStageInverseFilterBank::execute invalid nchan');
            end
            
            nch2 = nch2 * obj.combine;
            nch1 = nch1 / obj.combine;

            if (obj.single)
                nch1 = 1;
            end

            for ich = 1:nch1
                
                intmp = input(1,(1:nch2)+(ich-1)*nch2,:);
                
                obj.stage2(ich).critical = critical;
                
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
                   out = complex(zeros(1,nch1,ndat));
                   
                end
                 
                out(1,ich,:) = tmp(1,1,:);
                 
            end
            
            if isreal(tmp)
                error ('output data are real !!!');
            end
            
        end % of execute function
    end % of methods section
end % of TwoStageInverseFilterBank class definition
