classdef InverseFilterBank < DeChannelizer
    % polyphase synthesis with input buffering
    
    properties
        % over sampling ratio
        os_factor = struct('nu', 8, 'de', 7)

        filt_coeff          % filter coefficients
        n_fft               % input fft length
        overlap             % input overlap
        sample_offset = 0
        window_function
        deripple = 0
        conjugate_result = 0
        
        input_buffer        % input_buffer
        buffered_samples=0  % number of time samples in the input buffer
    end
   
    methods

        function obj = InverseFilterBank (config)
            % returns:
            %   obj = the configured InverseFilterBank object
                 
            obj = obj@DeChannelizer;
            
            if nargin > 0
            
            obj.filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
            obj.n_fft = config.input_fft_length;
            obj.os_factor = config.os_factor;
            obj.overlap = config.input_overlap;
            obj.deripple = config.deripple;
            obj.conjugate_result = config.conjugate_synthesis_result;
            
            win = PFBWindow();
            factory = win.lookup(config.fft_window);
            obj.window_function = factory(config.input_fft_length, config.input_overlap);
            
            % fprintf ('InverseFilterBank::configure window function=%s nfft=%d overlap=%d\n',...
            %         config.fft_window,config.input_fft_length,config.input_overlap);
                 
            end
            
        end % of InverseFilterBank constructor

        function [obj, output] = execute (obj, input)
            % returns:
            %   obj      = the modified object
            %   output   = the output of the filter

            arguments
                obj     (1,1) InverseFilterBank
                input
            end
            
            if (obj.buffered_samples > 0)
                input = cat(3,obj.input_buffer,input);
                obj.buffered_samples = 0;
            end
            
            size_in = size(input);
            n_pol  = size_in(1);
            n_chan = size_in(2);
            n_dat  = size_in(3);

            if isreal(input)
                error ('polyphase_synthesis input data are real-valued!');
            end

            verbose = 0;

            output = polyphase_synthesis (input, obj.n_fft, obj.os_factor,...
                struct('apply_deripple', obj.deripple, 'filter_coeff', obj.filt_coeff),...
                obj.sample_offset+1, obj.overlap,...
                obj.window_function,obj.conjugate_result,verbose);
            
            if isreal(output)
                fprintf ('size of input data ');
                size(input)
                error ('polyphase_synthesis output data are real-valued!');
            end
                    
            remainder = 1;
            
            modu = obj.os_factor.nu; % * obj.os_factor.nu;
            
            while (remainder ~= 0)
                output_size = size(output);
                input_idat = output_size(3) * obj.os_factor.nu / (n_chan * obj.os_factor.de);
                obj.buffered_samples = n_dat - input_idat;
                            
                remainder = mod (obj.buffered_samples, modu);
                
                if (remainder ~= 0)
                    fprintf ('InverseFilterBank: buffer length = %d samples is not a multiple of %d\n',...
                          obj.buffered_samples, modu);
                    obj.buffered_samples = obj.buffered_samples + modu - remainder;
                    input_idat = n_dat - obj.buffered_samples;
                    output_ndat = input_idat * (n_chan * obj.os_factor.de) / obj.os_factor.nu;
                    fprintf ('InverseFilterBank: reducing output from %d to %d\n', output_size(3),output_ndat);
                    output = output(:,:,1:output_ndat);
                end
            end

            remainder = mod (obj.buffered_samples, obj.os_factor.nu);                
            if (remainder ~= 0)
                fprintf ('InverseFilterBank: buffer length = %d samples is not a multiple of %d\n',...
                         obj.buffered_samples, obj.os_factor.nu);
            end
            
            if (obj.buffered_samples > 0)
                % fprintf ('Buffering %d samples\n', obj.buffered_samples);
                obj.input_buffer = input (:,:,(input_idat+1):end);
            end
            
        end % of execute function
    end % of methods section
end % of InverseFilterBank class definition
