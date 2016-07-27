classdef myClassHandle < handle
    
    properties (SetAccess = private)
        Delta
    end
        
    methods
        function y = multip(this, u)
            y = 2 * u;
            this.Delta = y;
        end
    end
end