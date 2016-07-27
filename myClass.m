classdef myClass
    
    properties (Constant)
        eta = 0.6;
    end
    
    methods (Static)
        function y = output(myHandle) 
            y = myHandle.Delta * myClass.eta;
        end
    end
end
        