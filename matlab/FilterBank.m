classdef FilterBank < Channelizer
    % analysis polyphase filter bank with input buffering
    
    properties
        % analysis filter bank function
        pfb_analysis = @polyphase_analysis

        % over sampling ratio
        os_factor = struct([])

        filt_coeff          % filter coefficients
        n_chan              % number of channels in ouput
        input_buffer        % input_buffer
        buffered_samples=0  % number of time samples in the input buffer

        rndInput = false;   % round input to integer
        rmsInput = 0.0;     % scale input to have rms before rounding
        
        rndOutput = false;  % round output to integer
        rmsOutput = 0.0;    % scale output to have rms before rounding

    end
   
    methods
        
        function obj = FilterBank (config)
            % returns:
            %   obj = the configured FilterBank object
            
            %fprintf ('FilterBank::configure analysis function=%s\n',...
            %         config.analysis_function);
                  
              obj = obj@Channelizer;
              
            if nargin > 0
              obj.pfb_analysis = str2func(sprintf('@%s', config.analysis_function));
              obj.filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
              obj.n_chan = config.channels;
              obj.os_factor = config.os_factor;

              obj.rndInput = config.rndInput;
              obj.rmsInput = config.rmsInput;
              obj.rndOutput = config.rndOutput;
              obj.rmsOutput = config.rmsOutput;

                if ( obj.rndInput )
                  % fprintf ('FilterBank: Rounding input to integer\n')
                end
                
                if ( obj.rmsInput > 0.0 )
                  % fprintf ('FilterBank: Scaling input to have rms=%f before rounding\n', obj.rmsInput)
                end
                
                if ( obj.rndOutput )
                  % fprintf ('FilterBank: Rounding output to integer\n')
                end
                
                if ( obj.rmsOutput > 0.0 )
                  % fprintf ('FilterBank: Scaling output to have rms=%f before rounding\n', obj.rmsOutput)
                end
            end
            
        end % of FilterBank constructor

        function [obj, output] = execute (obj, input)
            % returns:
            %   obj      = the modified object
            %   output   = the output of the filter

            arguments
                obj     (1,1) FilterBank
                input
            end

            if obj.rndInput
                scale = 1.0;
                if obj.rmsInput > 0
                    stddev = sqrt(var(input,0,"all"));
                    % fprintf ("input rms=%e \n", stddev);
                    scale = obj.rmsInput / stddev;
                end
                input = complex(round(scale * input));
            end

            if (obj.buffered_samples > 0)
                input = cat(3,obj.input_buffer,input);
                obj.buffered_samples = 0;
            end
            
            input_size = size(input);
            output = obj.pfb_analysis (input, obj.filt_coeff, obj.n_chan, obj.os_factor);

            remainder = 1;
            while (remainder ~= 0)
                output_size = size(output);
                remainder = mod (output_size(3), obj.os_factor.nu);
                
                if (remainder ~= 0)
                    % fprintf ('FilterBank: output length = %d samples is not a multiple of %d\n',output_size(3), obj.os_factor.nu);
                    output_ndat = output_size(3) - remainder;
                    % fprintf ('FilterBank: reducing output from %d to %d\n', output_size(3),output_ndat);
                    output = output(:,:,1:output_ndat);
                end
            end
            
            if (obj.rndOutput)
                scale = 1.0;
                if (obj.rmsOutput)
                    stddev = sqrt(var(output,0,"all"));
                    scale = obj.rmsOutput / stddev;
                end
                output = complex(round(scale * output));
            end

            if isreal(output)
                output = complex(output);
            end
            
            input_idat = output_size(3) * obj.n_chan * obj.os_factor.de / obj.os_factor.nu;
            obj.buffered_samples = input_size(3) - input_idat;
            
            if (obj.buffered_samples > 0)
                obj.input_buffer = input (:,:,(input_idat+1):end);
            end
            
        end % of execute function
    end % of methods section
end % of FilterBank class definition
