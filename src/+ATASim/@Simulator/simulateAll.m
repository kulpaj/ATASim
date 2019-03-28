function simulateAll( obj )
%simulateAll runs entire simulation for all time stamps


assert(obj.startTime_ < obj.stopTime_,'Simulator:simulateAll', 'start time later than stop time')

currTime = obj.startTime_;

disp('starting simulation loop')

while(currTime < obj.stopTime_)
    lastSampleTime = currTime + obj.tint_-obj.singleSampleTime_;
    obj.simulateSingleTime(currTime, lastSampleTime);
    currTime = currTime + obj.tint_;
    if(obj.show_progress_)
         diff=(obj.stopTime_-currTime);
         disp(diff.toDouble);
    end
end
    
end

