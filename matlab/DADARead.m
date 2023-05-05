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

            obj.n_dim = str2num(obj.header('NDIM'));
            obj.n_pol = str2num(obj.header('NPOL'));
            obj.n_bit = str2num(obj.header('NBIT'));
            obj.n_chan = str2num(obj.header('NCHAN'));
            obj.dtype = 'single';
            if obj.n_bit == 64
                obj.dtype = 'double';
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
            if obj.dtype == 'int8'
                data = cast(data,'double');
            end

            x = reshape(data, obj.n_pol*obj.n_dim, obj.n_chan, nsample);
            
        end % of generate function
    end % of methods section
end % of DADARead class definition
