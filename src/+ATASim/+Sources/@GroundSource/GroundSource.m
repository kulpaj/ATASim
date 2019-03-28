classdef GroundSource < ATASim.Sources.Source
    %Class GroundSource - groundbased transmitter source class
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        steering_; %antenna steering class
        power_; %transmission power [W]
        polarisation_; %unused
        position_; %ENU position of transmitter. 
        antennaPattern_; %beampattern of the transmit antenna
    end
    methods
        function obj=GroundSource(sourceName, signal, steering, powerdBW, pos, beam)
            %GroundSource class constructor
            %obj=GroundSource(sourceName, signal, steering, power, pos,
            %beam) creates a ground source object
            % power [dBW] the pre-antenna power
            obj = obj@ATASim.Sources.Source(sourceName,signal);
            assert(isa(steering,'ATASim.Steering.Steering'),'GroundSource:GroundSource','steering is not Steering object');
            obj.steering_ = steering;
            obj.power_ = 10^(powerdBW/10);
            assert(isa(pos,'ATASim.ENUPos'),'GroundSource:GroundSource','pos is not ENUPos object');
            obj.position_ = pos;
            assert(isa(beam,'ATASim.BeamPatterns.AntennaPattern'),'GroundSource:GroundSource','beam is not AntennaPattern object');
            obj.antennaPattern_ = beam;
        end
    end
    
    methods
        function pow = getPower(obj,nSamples,positionStart,timeStart,positionStop,timeStop)
            
            %WARN: we are assuming that it is narrowband here, since lambda(and
            %Power) does not depend on actual frequency, only on center
            %frequency!
            lambda = ATASim.ATAConstants.c/obj.signal_.getFc();
            
            diffPosStart = positionStart - obj.position_;
            diffPosStop = positionStop - obj.position_;
            
            [R1,azimAngle1,elevAngle1] = diffPosStart.getRAzEl();
            [R2,azimAngle2,elevAngle2] = diffPosStop.getRAzEl();
            
            %             R = diffPos.distance();
            %
            %             gPath = sqrt(diffPos.getE^2+diffPos.getN()^2);
            %             elevAngle = atan2d(diffPos.getU,gPath);
            %
            %             %TODO check if it is in good, where and how azim goes?
            %             %warning('GroundSource:getPower','check angles!')
            %             azimAngle = atan2d(diffPos.getE,diffPos.getN);
            
            [steeringAzim1,steeringAzim2,steeringElev1,steeringElev2] = obj.steering_.getAzimuthAndElevation(obj.position_,timeStart,obj.position_,timeStop);
            
            azimAntenna = linspace(azimAngle1-steeringAzim1,azimAngle2-steeringAzim2,nSamples);
            elevAntenna = linspace(elevAngle1-steeringElev1,elevAngle2-steeringElev2,nSamples);
            Gant = obj.antennaPattern_.getGain(azimAntenna,elevAntenna).';
            
            Range = linspace(R1,R2,nSamples).';
            
            %setting min distance to 1 cm to avoid inf power
            Range = max(Range,0.01);
            
            pow = (obj.power_*Gant*lambda*lambda)./(4*pi*Range).^2;
        end
        
        function [azimStart, elevStart, azimStop,elevStop] = getAngles(obj,positionStart,timeStart,positionStop,timeStop)
            %getAngles returns the angle w.r.t reciever of the incoming signal
            %[azimStart, elevStart, azimStop,elevStop] =
            %obj.getAngles(positionStart,timeStart,positionStop,timeStop)
            %returns the angle at witch receiever will encounter
            %signal from this source. for stationary ground source, time is
            %irrelevant
            
            diffPos1 = obj.position_ - positionStart;
            diffPos2 = obj.position_ - positionStop;
            
            [~,azimStart,elevStart] = diffPos1.getRAzEl();
            [~,azimStop,elevStop] = diffPos2.getRAzEl();
        end
        
        function [distStart,tDelStart,distStop,tDelStop] = getDistAndTimeDely(obj,positionStart,timeStart,positionStop,timeStop)
            %getDistAndTimeDely calculates time delay between wavefront at point 0,0,0 and sink and dist between sink and source
            %[distStart,tDelStart,distStop,tDelStop] =
            %getDistAndTimeDely(obj,positionStart,timeStart,positionStop,timeStop)
            %returns the time delay between wave arriving at the center of
            %scene (point 0,0,0) and wave arriving at given position(s).
            %Negative delay means that signal arrives first at the center.
            %For ground source, distance is a total distance between source
            %and sink
            
            distStart = obj.position_.distance(positionStart);
            distDel1 = obj.position_.distance - distStart;
            tDelStart = ATASim.TimeT(distDel1/ATASim.ATAConstants.c);
            
            distStop = obj.position_.distance(positionStop);
            distDel2 = obj.position_.distance - distStop;
            tDelStop = ATASim.TimeT(distDel2/ATASim.ATAConstants.c);
        end
    end
end