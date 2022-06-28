classdef (Abstract) Generator
    % abstract base class of objects that generate signals
    
    methods (Abstract)

        generate (obj, nsample)
            % returns:
            %   obj = the modified object
            %   x   = the next nsample samples of the signal
            
    end % of methods section
end % of Generator class definition
