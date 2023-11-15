classdef PhaseAverage
    % computes phase-resolved average
    
    properties
        frequency = 0      % wave cycles per sample
        current = 0        % current sample
        nbin = 256
        result
    end
   
    methods
      
        function obj = average (obj, data)
            % returns:
            %   obj = the modified object

            arguments
                obj     (1,1) PhaseAverage
                data    (:,:,:)
            end

            dim = size(data);
            nsample = dim(end);

            if (obj.current == 0)
              dim(end) = obj.nbin;
              obj.result = zeros(dim);
            end

            isamp = 1;

            while (isamp <= nsample)
              phase = obj.current * obj.frequency;
              ibin = mod (round(phase * obj.nbin), obj.nbin) + 1;
              % fprintf("ibin=%d isamp=%d \n", ibin, isamp);
              obj.result(:,:,ibin) = obj.result(:,:,ibin) + data(:,:,isamp);
              isamp = isamp + 1;
              obj.current = obj.current + 1;
            end % of loop over remaining samples
        end % of generate function
    end % of methods section
end % of PhaseAverage class definition
