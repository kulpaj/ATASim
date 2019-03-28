classdef SatSource < ATASim.Sources.Source
    %Class SatSource - groundbased transmitter source class
    
    %Author: Janusz S. Kulpa (June 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        ephSteering_; %movement steering class
        antSteering_; %antena steering (pointing) direction
        power_; %transmission power [W]
        polarisation_; %unused
        antennaPattern_; %beampattern of the transmit antenna
    end
    methods
        function obj=SatSource(sourceName, signal, ephem, power, beam, steering)
            %GroundSource class constructor
            %obj=GroundSource(sourceName, signal, steering, power, pos,
            %beam) creates a ground source object
            % power [dBW] the pre-antenna power
            obj = obj@ATASim.Sources.Source(sourceName,signal);
            assert(isa(steering,'ATASim.Steering.Steering'),'SatSource:SatSource','steering is not Steering object');
            obj.antSteering_ = steering;
            obj.power_ = 10^(power/10);
            assert(isa(ephem,'ATASim.Steering.FileSteering'),'SatSource:SatSource','ephem is not FileSteering object');
            obj.ephSteering_ = ephem;
            assert(isa(beam,'ATASim.BeamPatterns.AntennaPattern'),'SatSource:SatSource','beam is not AntennaPattern object');
            obj.antennaPattern_ = beam;
        end
    end
    
    methods
        function pow = getPower(obj,nSamples,positionStart,timeStart,positionStop,timeStop)
            [azimB,elevB,invRB, azimE, elevE, invRE] = obj.ephSteering_.getInterpolateAzElInvR(timeStart,timeStop);
            
            assert(invRB ~= 0 & invRE ~= 0,'SatSource:getPower','InvR is 0, use celestial source instead');
            
            sourcePosStart = ATASim.ENUPos();
            sourcePosStart.updateFromRAzEl(1/invRB,azimB,elevB);
            sourcePosStop = ATASim.ENUPos();
            sourcePosStop.updateFromRAzEl(1/invRE,azimE,elevE);
            
            lambda = ATASim.ATAConstants.c/obj.signal_.getFc();
            
            diffPosStart = positionStart - sourcePosStart;
            diffPosStop = positionStop - sourcePosStop;
            
            [R1,azimAngle1,elevAngle1] = diffPosStart.getRAzEl();
            [R2,azimAngle2,elevAngle2] = diffPosStop.getRAzEl();
            
            [steeringAzim1,steeringAzim2,steeringElev1,steeringElev2] = obj.antSteering_.getAzimuthAndElevation(sourcePosStart,timeStart,sourcePosStop,timeStop);
            
            azimAntenna = linspace(azimAngle1-steeringAzim1,azimAngle2-steeringAzim2,nSamples);
            elevAntenna = linspace(elevAngle1-steeringElev1,elevAngle2-steeringElev2,nSamples);
            Gant = obj.antennaPattern_.getGain(azimAntenna,elevAntenna).';
            
            Range = linspace(R1,R2,nSamples).';
            
            %setting min distance to 1 cm to avoid inf power
            Range = max(Range,0.01);
            
            pow = (obj.power_*Gant*lambda*lambda)./(4*pi*Range).^2;
        end
        
        function [azimStart, elevStart, azimStop,elevStop] = getAngles(obj,positionStart,timeStart,positionStop,timeStop)
            [azimB,elevB,invRB, azimE, elevE, invRE] = obj.ephSteering_.getInterpolateAzElInvR(timeStart,timeStop);
            
            assert(invRB ~= 0 & invRE ~= 0,'SatSource:getAngles','InvR is 0, use celestial source instead');
            
            sourcePosStart = ATASim.ENUPos();
            sourcePosStart.updateFromRAzEl(1/invRB,azimB,elevB);
            sourcePosStop = ATASim.ENUPos();
            sourcePosStop.updateFromRAzEl(1/invRE,azimE,elevE);
            
            diffPos1 = sourcePosStart - positionStart;
            diffPos2 = sourcePosStop - positionStop;
            
            [~,azimStart,elevStart] = diffPos1.getRAzEl();
            [~,azimStop,elevStop] = diffPos2.getRAzEl();
        end
        
        function [distStart,tDelStart,distStop,tDelStop] = getDistAndTimeDely(obj,positionStart,timeStart,positionStop,timeStop)
            [azimB,elevB,invRB, azimE, elevE, invRE] = obj.ephSteering_.getInterpolateAzElInvR(timeStart,timeStop);
                        
            assert(invRB ~= 0 & invRE ~= 0,'SatSource:getDistAndTimeDely','InvR is 0, use celestial source instead');
            
            sourcePosStart = ATASim.ENUPos();
            sourcePosStart.updateFromRAzEl(1/invRB,azimB,elevB);
            sourcePosStop = ATASim.ENUPos();
            sourcePosStop.updateFromRAzEl(1/invRE,azimE,elevE);
            
            distStart = sourcePosStart.distance(positionStart);
            distDel1 = sourcePosStart.distance - distStart;
            tDelStart = ATASim.TimeT(distDel1/ATASim.ATAConstants.c);
            
            distStop = sourcePosStop.distance(positionStop);
            distDel2 = sourcePosStop.distance - distStop;
            tDelStop = ATASim.TimeT(distDel2/ATASim.ATAConstants.c);
        end
    end
end