classdef FileSteering < ATASim.Steering.Steering
    %Class FileSteering ephemeris based steering class
    %angle and elev calculated from ephemeris file data and range
    %mutliple entities (Receivers, Sources) can use a single steering
    %object.
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        timeTai_; %Tai TimeT vector for each data point in file
        %timeUtc_;
        azimuth_; %Azumuth vector
        elevation_; %Elevation vector
        invRange_; %invRange vector
        
        lastTimeStart_; %timestamp used for fast calculation
        lastAzStart_; %azimuth used for fast calculation
        lastElStart_; %elevation used for fast calculation
        lastRangStart_; %inverse range used for fast calculation
        
        lastTimeStop_; %timestamp used for fast calculation
        lastAzStop_; %azimuth used for fast calculation
        lastElStop_; %elevation used for fast calculation
        lastRangStop_; %inverse range used for fast calculation
    end
    methods
        function obj = FileSteering(filename)
            %FileSteering class constructor
            %obj = FileSteering(filename) creates the steering from a file
            data = ATATools.IO.ReadAtaEphem(filename);
            assert(all(diff(data(:,1))>0),'FileSteering:FileSteering','timestamps in file not ordered properly');
            obj.timeTai_ = ATASim.TimeT(data(:,1));
            %obj.timeUtc_ = ATASim.TimeT(data(:,2));
            obj.azimuth_ = data(:,3);
            obj.elevation_= data(:,4);
            obj.invRange_ = data(:,5);
            
            %for faster processing if multiple calls are executed
            obj.lastTimeStart_ = obj.timeTai_(1);
            obj.lastAzStart_ = obj.azimuth_(1);
            obj.lastElStart_ = obj.elevation_(1);
            obj.lastRangStart_ = obj.invRange_(1);
            obj.lastTimeStop_ = obj.timeTai_(1);
            obj.lastAzStop_ = obj.azimuth_(1);
            obj.lastElStop_ = obj.elevation_(1);
            obj.lastRangStop_ = obj.invRange_(1);
        end
    end
    
    methods %implementing abstract methods
        function az = getAzimuth(obj,positionStart,timeStart,positionStop,timeStop)
            [azTmp,elTmp,invRTmp] = obj.linTimeInterpolate(taitime);
            if(invRTmp == 0)
                az = azTmp;
            else
                error('FileSteering:getAzimuth','not implemented yet');
            end
        end
        function el = getElevation(obj,positionStart,timeStart,positionStop,timeStop)
            [azTmp,elTmp,invRTmp] = obj.linTimeInterpolate(taitime);
            if(invRTmp == 0)
                el = elTmp;
            else
                error('FileSteering:getElevation','not implemented yet');
            end
            
        end
        function [azStart, azStop,elStart, elStop] = getAzimuthAndElevation(obj,positionStart,timeStart,positionStop,timeStop)
            [azTmp,elTmp,invRTmp] = obj.linTimeInterpolate(taitime);
            if(invRTmp == 0)
                az = azTmp;
                el = elTmp;
            else
                error('FileSteering:getAzimuthAndElevation','not implemented yet');
            end
            
        end
    end
    
    methods %(Access=private) %or friend celestialSource
        function [az1,el1,invR1, az2, el2, invR2] = getInterpolateAzElInvR(obj,timeStart,timeStop)
            
            if(timeStart == obj.lastTimeStart_ && timeStop == obj.lastTimeStop_)
                az1 = obj.lastAzStart_;
                el1 = obj.lastElStart_;
                invR1 = obj.lastRangStart_;
                
                az2 = obj.lastAzStop_;
                el2 = obj.lastElStop_;
                invR2 = obj.lastRangStop_;
                
                return
            end
            
            [az1,el1,invR1] = obj.linInterpolate(timeStart);
            [az2,el2,invR2] = obj.linInterpolate(timeStop);
            
        end
        
        
        
        
        function [az,el,invR] = linTimeInterpolate(obj,taitime)
            %linTimeInterpolate interpolates the internal data
            %[az,el,invR]=obj.linTimeInterpolate(taitime) the internal data
            %to the taitime point. Trying to get data from beyond time vector
            %returns the first or last entry and issues a warning.
            %For faster computation, under assumption that multiple objects
            %will call the function with the same timestamp, the last value
            %is saved.
            
            if (taitime == obj.lastTime_)
                az = obj.lastAz_;
                el = obj.lastEl_;
                invR = obj.lastRang_;
                return
            end
            if(taitime < obj.timeTai_(1))
                az = obj.azimuth_(1);
                el = obj.elevation_(1);
                invR = obj.invRange_(1);
                warning('FileSteering:linTimeInterpolate','time is %f second before the data vector',obj.timeTai_(1) - taitime)
                return
            elseif (taitime > obj.timeTai_(end))
                az = obj.azimuth_(end);
                el = obj.elevation_(end);
                invR = obj.invRange_(end);
                warning('FileSteering:linTimeInterpolate','time is %f second after of data vector',taitime - obj.timeTai_(end))
                return
            end
            tdiffv = obj.timeTai_-taitime;
            exact = find(tdiffv == 0,1);
            if(~isempty(exact))
                az = obj.azimuth_(exact);
                el = obj.elevation_(exact);
                invR = obj.invRange_(exact);
                
                obj.lastTime_ = taitime;
                obj.lastAz_ = az;
                obj.lastEl_ = el;
                obj.lastRang_ = invR;
                return
            end
            timeZero = ATASim.TimeT(0);
            lastLesser = find(tdiffv < timeZero,1,'last');
            timeLow = obj.timeTai_(lastLesser);
            timeHigh = obj.timeTai_(lastLesser+1);
            timeDiff = timeHigh - timeLow;
            timeOff = taitime - timeLow;
            factorialPos = (timeOff.toDouble())/(timeDiff.toDouble());
            az = obj.azimuth_(lastLesser) + (obj.azimuth_(lastLesser+1)-obj.azimuth_(lastLesser)) * factorialPos;
            el = obj.elevation_(lastLesser) + (obj.elevation_(lastLesser+1)-obj.elevation_(lastLesser)) * factorialPos;
            invR = obj.invRange_(lastLesser) + (obj.invRange_(lastLesser+1)-obj.invRange_(lastLesser)) * factorialPos;
            
            obj.lastTime_ = taitime;
            obj.lastAz_ = az;
            obj.lastEl_ = el;
            obj.lastRang_ = invR;
        end
    end
end