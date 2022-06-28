classdef (Abstract) DeChannelizer
    % abstract base class of objects that recombine a signal in frequency
    
    methods (Abstract)

        execute (obj, input)
            % returns:
            %   obj      = the modified DeChannelizer subclass object
            %   output   = the dechannelized form of input
            
    end % of methods section
end % of DeChannelizer class definition
