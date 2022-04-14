classdef DADAFile
    % writes data to a file with a DADA header
    
    properties
        filename = ''
        fileID   = -1
        header_template = '../config/default_header.json'
        header   = containers.Map();
    end
   
    methods
      
        function obj = open (obj, fname)
            % returns:
            %   obj = the modified object

            arguments
                obj      (1,1) DADAFile
                fname    (1,1) string
            end
            
            obj.fileID = fopen (fname, 'wt');
            obj.filename = fname;
            
            json_str = fileread(obj.header_template);
            obj.header = struct2map(jsondecode(json_str));

        end % of open function

        function obj = write (obj, data)
            % returns:
            %   obj = the modified object

            arguments
                obj      (1,1)   DADAFile
                data     (:,:,:)
            end

            if (obj.fileID == -1)
                obj = open (obj, obj.filename);
                write_dada_header (obj.fileID, data, obj.header);
            end
            
            write_dada_data (obj.fileID, data);
            
        end % of write function

        function obj = close (obj)
            % returns:
            %   obj = the modified object

            arguments
                obj      (1,1) DADAFile
            end

            fclose (obj.fileID);
            
        end % of close function

    end % of methods section
end % of SquareWave class definition
