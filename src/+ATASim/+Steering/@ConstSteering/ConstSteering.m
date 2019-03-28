classdef ConstSteering < ATASim.Steering.Steering
    %Class ConstSteering for fixed antenna position
    %angle and elev are constant in time
        
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        elevation_; %constant elevation [deg]
        azimuth_; % constant azimuth [deg]
    end
    
    methods
        function obj = ConstSteering(az, el)
            %ConstSteering class constructor
            %obj = ConstSteering(az, el) creates a constant steering class
            obj.elevation_ = el;
            obj.azimuth_ = az;
        end
    end
    
    methods %implementing abstract methods
        function [azStart, azStop,elStart, elStop] = getAzimuthAndElevation(obj,~,~,~,~)
            azStart = obj.azimuth_;
            azStop = obj.azimuth_;
            elStart = obj.elevation_;
            elStop = obj.elevation_;
        end
    end
    
end