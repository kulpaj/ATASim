function printScene(obj,timestamp)
%printScene 2d print scene of the simulator
%   printScene() prints the scene at the beginnig of simulation
%   printScene(etime) prints the scene at the instant of etime
%   seconds after beginning of simuation
%   printScene(timestamp) prints the scene at the instant of etime
%   seconds after beginning of simuation


if nargin < 2
    timestamp = obj.startTime_.toDouble();
end


for iK = 1:numel(timestamp)
    %we are assuming that if timestamp is 10 times smaller that obj.startTime_
    TDiff =obj.stopTime_ - obj.startTime_;
    if (timestamp(iK)< obj.startTime_.toDouble()*0.1 && timestamp(iK) < TDiff.toDouble())
        ctime_sim = obj.startTime_ + timestamp(iK);
    elseif (timestamp(iK) >= obj.startTime_.toDouble() && timestamp(iK) < obj.stopTime_.toDouble())
        ctime_sim = timestamp(iK);
    else 
        error('ATASim:Simulator:printScene','timestamp could not be resolved')
    end
    
    
    hfig = figure(iK);
    clf(hfig);
    haxes = axes(hfig);
    obj.scene_.printScene(ctime_sim, haxes);
    
    
end