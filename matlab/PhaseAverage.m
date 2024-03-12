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

            phase = ((1:nsample) + obj.current) * obj.frequency;
            ibin = mod (round(phase * obj.nbin), obj.nbin) + 1;
            ibin = ibin';  % transpose ibin vector
            
            for ipol = 1:dim(1)
                for ichan = 1:dim(2)
                    x = squeeze(data(ipol,ichan,:));
                    y = accumarray(ibin,x,[obj.nbin 1]);
                    y = reshape(y,[1 1 obj.nbin]);
                    obj.result(ipol,ichan,:) = obj.result(ipol,ichan,:) + y;
                end
            end

            obj.current = obj.current + nsample;

        end % of average function
    end % of methods section
end % of PhaseAverage class definition
