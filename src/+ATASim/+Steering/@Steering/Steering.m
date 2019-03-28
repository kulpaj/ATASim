classdef Steering < handle
    %Class Steering Abstract Steering class
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawsk
    properties
    end
    
    methods(Abstract)
        getAzimuthAndElevation(obj,positionStart,timeStart,positionStop,timeStop)
    end
    
    methods %probably not nessesary
        function [azStart,azStop] = getAzimuth(obj,positionStart,timeStart,positionStop,timeStop)
            [azStart, azStop,~, ~] = obj.getAzimuthAndElevation(positionStart,timeStart,positionStop,timeStop);
        end
        function [elStart,elStop] = getElevation(obj,positionStart,timeStart,positionStop,timeStop)
            [~, ~,elStart, elStop] = obj.getAzimuthAndElevation(positionStart,timeStart,positionStop,timeStop);
        end
    end
end