function simulateSingleTime( obj, currTime, endCurrTime )
%simulateSingleTime single integration time simulation
%obj.simulateSingleTime(currTime) runs simulation for currTime

for iK = 1:length(obj.scene_.sources_)
    obj.scene_.sources_{iK}.simulate(currTime);
end

for iK = 1:length(obj.scene_.sinks_)
    cSink = obj.scene_.sinks_{iK};
    cSink.resetSignal(currTime);   
    [sPosStart,sPosStop] = cSink.getStartStopPosition(currTime,endCurrTime);
    fprintf('doing id %d\n',cSink.id_);
    
    for iL = 1:length(obj.scene_.sources_)
        cSource = obj.scene_.sources_{iL};
        sSig = cSource.getSamples(sPosStart,currTime,sPosStop,endCurrTime);
        [azimStart, elevStart, azimStop,elevStop] = cSource.getAngles(sPosStart,currTime,sPosStop,endCurrTime);
        cSink.pushSignal(sSig,azimStart, elevStart, azimStop,elevStop,currTime,endCurrTime)
    end

    cSink.saveData();
end



end

