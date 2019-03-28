classdef MeasPattern < ATASim.BeamPatterns.AntennaPattern
    
    properties
        %gridAz_;
        %gridEl_;
        %gridDat_;
        interpolant_;
        maxAz_;
        maxEl_;
        minAz_;
        minEl_;
    end
    
    methods
        function obj = MeasPattern(fileName)
           [az, el, re, im] = ATATools.IO.readAntennaDat(fileName);
           %obj.gridAz_ = az;
           %obj.gridEl_ = el;
           %obj.gridDat_ = re+1j*im;
           obj.interpolant_ = scatteredInterpolant(az,el,(re+1j*im),'linear','none');
           obj.maxAz_ = max(az);
           obj.minAz_ = min(az);
           obj.maxEl_ = max(el);
           obj.minEl_ = min(el);
        end
    end
    
    methods %implementing abstract functions
        function y  = getGain(obj,azim,elev)
            %getGain antenna gain for given azimuth and elevation
            %y = obj.getGain(azim,elev) returns (linear) power gain for
            %given direction
            
            assert(all(size(azim) == size(elev)),'PencilPattern:getGain','elev and azim pattern does not match')
            
            y = obj.interpolant_(obj.modTo180180(azim),obj.modTo180180(elev));
            %y( (azim > obj.maxAz_) | (azim < obj.minAz_) | (elev > obj.maxEl_) | (elev < obj.minEl_) ) = 0;
            %y = max(y,0);
            y(isnan(y)) = 0;
            
            assert(all(size(azim) == size(y)),'PencilPattern:getGain','something went wrong')
        end
    end
    
end