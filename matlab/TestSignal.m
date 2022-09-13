classdef (Abstract) TestSignal
    % abstract base class of objects that test signals
    
    methods (Abstract)

        test (obj, x)
            % inputs:
            %   obj = the modified object
            %   x   = the samples to be tested
            % returns:
            %   obj = the modified object
            %   result = the test result (pass < 1; fail > 1)
            
    end % of methods section
end % of TestSignal class definition
