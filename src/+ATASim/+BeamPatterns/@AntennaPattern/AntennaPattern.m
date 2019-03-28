classdef AntennaPattern < handle
    %Class AntennaPattern - Abstract antenna pattern class
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    methods(Abstract)
        %get antenna gain for given azimuth and elevation
        getGain(azim,elev);
    end
    
    methods
        function y = modTo180180(~,val)
            %modTo180180 converts the angle to -180 180 range
            y = mod(val+180,360)-180;
        end
    end
end