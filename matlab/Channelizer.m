classdef (Abstract) Channelizer
    % abstract base class of objects that divide a signal in frequency
    
    methods (Abstract)

        execute (obj, input)
            % returns:
            %   obj      = the modified Channelizer subclass object
            %   output   = the channelized form of input
            
    end % of methods section
end % of Channelizer class definition
