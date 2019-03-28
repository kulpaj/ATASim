classdef Source < handle
    properties
        signal_; % SourceSignal class
        name_;
    end
    
    
    
    methods (Abstract)
        %the signal power at receiver position
        getPower(obj,nSamples,positionStart,timeStart,positionStop,timeStop);
        %what angle of arrival the sink would have
        getAngles(obj,positionStart,timeStart,positionStop,timeStop)
        %time delay between 0,0,0 and sinkPos
        getDistAndTimeDely(obj,positionStart,timeStart,positionStop,timeStop)
    end
    
    methods
        function obj = Source(sourceName, signal)
            assert(isa(signal,'ATASim.Signals.SourceSignal'),'Source:Source','signal must be ATASim.Sources.SourceSignal class');
            %assert(isa(refPos,'ATASim.ENUPos'),'Source:Source','refPos must be ATASim.ENUPos class');
            obj.signal_ = signal;
            obj.name_ = sourceName;
            %obj.refPos_ = refPos;
        end
        function y = getSamples(obj,positionStart,timeStart,positionStop,timeStop)

            
            %
            [rangeStart,tDelStart,rangeStop,tDelStop] = obj.getDistAndTimeDely(positionStart,timeStart,positionStop,timeStop);
            
            %TODO FIXME
            %obtaining a signal (we believe no stretch processing is done
            %here, however it might be added later, since we have
            %everythink for that) We just average the time dely here and
            %add it to timeStart and timeStop. The proper way would be to
            %add tDelStop to timeStop and tDelStart to timeStart and add
            %additional parameter to signal.getSamples call to indicate the
            %actual integration time, so the signal might be resampled.
            
            tDel = tDelStart+tDelStop;
            actTimeDel = ATASim.TimeT(tDel.toDouble()/2);
            
            sinkTimeStart = timeStart + actTimeDel;
            sinkTimeStop = timeStop + actTimeDel;            
            
            yC = obj.signal_.getSamples(sinkTimeStart,sinkTimeStop,rangeStart,rangeStop);
            
            %obtaining power levels (linear interpolation between stop and
            %start points)
            pLvl = obj.getPower(length(yC),positionStart,timeStart,positionStop,timeStop);
            disp(10*log10(pLvl(1)))
            %getting the actual signal
            y = yC .* sqrt(pLvl);
            
        end
        function simulate(obj,time)
            obj.signal_.makeSamples(time);
        end
    end
    
    
    
end