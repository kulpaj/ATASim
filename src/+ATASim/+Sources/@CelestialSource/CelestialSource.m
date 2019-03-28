classdef CelestialSource < ATASim.Sources.Source
    %Class GroundSource - groundbased transmitter source class
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        ephSteering_; % steering class for celestial source
        earthSurfPowLvl_; % the power level of the signal at Earth surface
    end
    methods
        function obj = CelestialSource(sourceName, signal, ephSteering, powLvl)
            obj = obj@ATASim.Sources.Source(sourceName,signal);
            assert(isa(ephSteering,'ATASim.Steering.FileSteering'),'CelestialSource:CelestialSource','steering is not FileSteering object');
            obj.ephSteering_ = ephSteering;
            obj.earthSurfPowLvl_ = powLvl;
        end
    end
    
    methods %implementing abstract
        function y = getPower(obj,nSamples,~,~,~,~)
            y = ones(nSamples,1)*obj.earthSurfPowLvl_;
        end
        
        function [azimStart, elevStart, azimStop,elevStop] = getAngles(obj,~,timeStart,~,timeStop)
            %getAngles returns the angle w.r.t reciever of the incoming signal
            %[azimStart, elevStart, azimStop,elevStop] =
            %getAngles(obj,positionStart,timeStart,positionStop,timeStop)
            %returns the angle at witch receiever  will encounter signal
            %from this source. Returs the positions for start and stop
            %time.
            
            [azimStart,elevStart,invR1, azimStop, elevStop, invR2] = obj.ephSteering_.getInterpolateAzElInvR(timeStart,timeStop);
            %we assume plain wave here
            assert(invR1 == 0 && invR2 == 0,'CelestialSource:getAngles','Source is not infinitely far away!')
        end
        
        function [distStart,tDelStart,distStop,tDelStop] = getDistAndTimeDely(obj,positionStart,timeStart,positionStop,timeStop)
            %getDistAndTimeDely calculates time delay between wavefront at point 0,0,0 and sink and dist between sink and source
            %[distStart,tDelStart,distStop,tDelStop] =
            %getDistAndTimeDely(obj,positionStart,timeStart,positionStop,timeStop)
            %returns the time delay between wave arriving at the center of
            %scene (point 0,0,0) and wave arriving at given position(s).
            %Negative delay means that signal arrives first at the center.
            %For celestial source, distance is a dot product between sink
            %position and steering vector
            
            
            [azimStart,elevStart,invR1, azimStop, elevStop, invR2] = obj.ephSteering_.getInterpolateAzElInvR(timeStart,timeStop);
            %we assume plain wave here
            assert(invR1 == 0 && invR2 == 0,'CelestialSource:getDistAndTimeDely','Source is not infinitely far away!')
            
            e1 = cosd(elevStart) .* sind(azimStart);
            n1 = cosd(elevStart) .* cosd(azimStart);
            u1 = sind(elevStart);
            distStart = dot([e1; n1; u1],[positionStart.getE(); positionStart.getN(); positionStart.getU()]);
            tDelStart = ATASim.TimeT(distStart/ATASim.ATAConstants.c);
            e2 = cosd(elevStop) .* sind(azimStop);
            n2 = cosd(elevStop) .* cosd(azimStop);
            u2 = sind(elevStop);
            distStop = dot([e2; n2; u2],[positionStop.getE(); positionStop.getN(); positionStop.getU()]);
            tDelStop = ATASim.TimeT(distStart/ATASim.ATAConstants.c);
        end
    end
end