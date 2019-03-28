classdef Receiver < handle
    %Class Receiver - the signal receiever class
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        beamPattern_; %AntennaPattern class
        steering_; %Steering Class
        id_; %int
        temperature_; %double
        polarization_ = 1; %not sure
        fc_; %[Hz] %center frequency
        fs_; %[Hz] %is used as bandwidth, which may not be correct for noise power calculation!
    end
    methods (Abstract)
        getStartStopPosition(obj,time1,time2);
    end
    
    methods
        function obj = Receiver(id,temp,fs,fc,steering,beam)
            assert(isnumeric(id),'Receiver:Receiver','id must be numeric')
            obj.id_ = id;
            assert(isnumeric(temp) & temp >= 0,'Receiver:Receiver','temp must be numeric greater than 0')
            obj.temperature_ = temp;
            assert(isnumeric(fs),'Receiver:Receiver','fs must be numeric')
            obj.fs_ = fs;
            assert(isnumeric(fc),'Receiver:Receiver','fc must be numeric')
            obj.fc_ = fc;
            assert(isa(steering,'ATASim.Steering.Steering'),'Receiver:Receiver','steering must be Steering class')
            obj.steering_ = steering;
            assert(isa(beam,'ATASim.BeamPatterns.AntennaPattern'),'Receiver:Receiver','beam must be AntennaPattern class')
            obj.beamPattern_ = beam;

        end
        function sig = getThermalNoise(obj,len)
            %getThermalNoise return thermal noise signal
            pow = ATASim.ATAConstants.k*obj.temperature_*obj.fs_;
            x = ATASim.Signals.makeGaussianNoise(len);
            %makeGaussianNoise should give a samples with variance \approx 1
            sig = sqrt(pow)*x;
        end
        
        function gain = getGain(obj,len,azimStart, elevStart, azimStop,elevStop,timeStart,timeStop)
            %getGain get gain vector of the antenna
            %gain = obj.getGain(azim,elev,time)
            
            [sPosStart,sPosStop] = obj.getStartStopPosition(timeStart,timeStop);
            [azSteerStart, azSteerStop,elSteerStart, elSteerStop] = obj.steering_.getAzimuthAndElevation(sPosStart,timeStart,sPosStop,timeStop);
            
            azimVec = linspace(azimStart-azSteerStart,azimStop-azSteerStop,len);
            elevVec = linspace(elevStart-elSteerStart,elevStop-elSteerStop,len);
            gain = obj.beamPattern_.getGain(azimVec,elevVec).';
        end
    end
end