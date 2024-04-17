classdef DADARead < Generator
    % reads from DADAFile
    
    properties
        filename = ''
        fileID   = -1
        header   = containers.Map();

        n_dim = 1
        n_pol = 1
        n_chan = 1
        n_bit = 1
        dtype = 'none'

        low_cbf_input = false

    end
   
    methods
        function obj = open (obj, fname)
            % returns:
            %   obj = the modified object

            arguments
                obj      (1,1) DADARead
                fname    (1,1) string
            end
            
            obj.fileID = fopen (fname, 'r');
            obj.header = read_header (obj.fileID);

            hdr_size = str2num(obj.header('HDR_SIZE'));
            fseek(obj.fileID, hdr_size, 'bof');

            obj.low_cbf_input = strcmp(obj.header('INSTRUMENT'), 'LowCBF');

            fprintf('DADARead::open low_cbf_input=%d instrument=%s \n', obj.low_cbf_input, obj.header('INSTRUMENT'));

            obj.n_dim = str2num(obj.header('NDIM'));
            obj.n_pol = str2num(obj.header('NPOL'));
            obj.n_bit = str2num(obj.header('NBIT'));
            obj.n_chan = str2num(obj.header('NCHAN'));

            fprintf('DADARead::open nbit=%d ndim=%d npol=%d nchan=%d\n', obj.n_bit, obj.n_dim, obj.n_pol, obj.n_chan);

            obj.dtype = 'single';
            if obj.n_bit == 64
                obj.dtype = 'double';
            elseif obj.n_bit == 16
                obj.dtype = 'int16';
            elseif obj.n_bit == 8
                obj.dtype = 'int8';
            end
            obj.filename = fname;

        end % of open function

        function [obj, x] = generate (obj, nsample)
            % returns:
            %   obj = the modified object
            %   x   = the next nsample samples from the file

            arguments
                obj     (1,1) DADARead
                nsample (1,1) {mustBeInteger, mustBeNonnegative}
            end
            
            ndat = nsample * obj.n_chan * obj.n_pol * obj.n_dim;
            data = fread(obj.fileID, ndat, obj.dtype);
            if obj.n_bit ~= 32
                data = cast(data,'double');
            end

            if obj.low_cbf_input
                % fprintf('DADARead::generate low_cbf_input\n')
                x = reshape_low_cbf_data(data, obj.n_dim, obj.n_pol, obj.n_chan);
            else
                x = reshape_dada_data(data, obj.n_dim, obj.n_pol, obj.n_chan);
            end

            x = complex(x);
            
        end % of generate function
    end % of methods section
end % of DADARead class definition
