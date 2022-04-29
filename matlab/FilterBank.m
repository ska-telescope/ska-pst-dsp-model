classdef FilterBank
    % analysis polyphase filter bank with input buffering
    
    properties
        % analysis filter bank function
        pfb_analysis = @polyphase_analysis

        % over sampling ratio
        os_factor = struct('nu', 8, 'de', 7)

        filt_coeff          % filter coefficients
        n_chan              % number of channels in ouput
        input_buffer        % input_buffer
        buffered_samples=0  % number of time samples in the input buffer
    end
   
    methods

        function obj = configure (obj, config)
            % returns:
            %   obj = the configured FilterBank object
            %   x   = the next nsample samples of the wave

            arguments
                obj     (1,1) FilterBank
                config
            end
            
            fprintf ('FilterBank::configure analysis function=%s\n',...
                     config.analysis_function);
                 
            obj.pfb_analysis = str2func(sprintf('@%s', config.analysis_function));
            obj.filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
            obj.n_chan = config.channels;
            obj.os_factor = config.os_factor;
            
        end % of configure function

        function [obj, output] = execute (obj, input)
            % returns:
            %   obj      = the modified object
            %   output   = the output of the filter

            arguments
                obj     (1,1) FilterBank
                input
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
                    fprintf ('FilterBank: output length = %d samples is not a multiple of %d\n',output_size(3), obj.os_factor.nu);
                    output_ndat = output_size(3) - remainder;
                    fprintf ('FilterBank: reducing output from %d to %d\n', output_size(3),output_ndat);
                    output = output(:,:,1:output_ndat);
                end
            end
            
            input_idat = output_size(3) * obj.n_chan * obj.os_factor.de / obj.os_factor.nu;
            obj.buffered_samples = input_size(3) - input_idat;
            
            if (obj.buffered_samples > 0)
                obj.input_buffer = input (:,:,(input_idat+1):end);
            end
            
        end % of execute function
    end % of methods section
end % of FilterBank class definition
