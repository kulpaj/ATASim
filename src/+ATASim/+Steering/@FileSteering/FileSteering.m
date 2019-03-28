classdef FileSteering < ATASim.Steering.Steering
    %Class FileSteering ephemeris based steering class
    %angle and elev calculated from ephemeris file data and range
    %mutliple entities (Receivers, Sources) can use a single steering
    %object.
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        timeAdjustedDouble_; %double vector - time with respect to startOfFileTime_
        startOfFileTime_; %TimeT for first sample
        endOfFileTime_; %TimeT for last sample
        azimuthPolySpline_; %Azumuth Spline Polynomial
        elevationPolySpline_; %Elevation Spline Polynomial
        invRangePolySpline_; %invRange Spline Polynomial [in 1/km]
        
        
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
            obj.startOfFileTime_ = ATASim.TimeT(data(1,1));
            obj.endOfFileTime_ = ATASim.TimeT(data(end,1));
            obj.timeAdjustedDouble_ = data(:,1) - obj.startOfFileTime_.toDouble();
            %obj.timeUtc_ = ATASim.TimeT(data(:,2));
            
            obj.azimuthPolySpline_ = spline(obj.timeAdjustedDouble_,data(:,3));
            obj.elevationPolySpline_ = spline(obj.timeAdjustedDouble_,data(:,4));
            obj.invRangePolySpline_ = spline(obj.timeAdjustedDouble_,data(:,5));
            
            %for faster processing if multiple calls are executed
            obj.lastTimeStart_ = obj.startOfFileTime_;
            obj.lastAzStart_ = data(1,3); % = ppval(obj.azimuthPolySpline_,0);
            obj.lastElStart_ = data(1,4); % = ppval(obj.elevationPolySpline_,0);
            obj.lastRangStart_ = data(1,5); % = ppval(obj.invRangePolySpline_,0);
            obj.lastTimeStop_ = obj.startOfFileTime_;
            obj.lastAzStop_ = data(1,3); % = ppval(obj.azimuthPolySpline_,0);
            obj.lastElStop_ = data(1,4); % = ppval(obj.elevationPolySpline_,0);
            obj.lastRangStop_ = data(1,5); % = ppval(obj.invRangePolySpline_,0);
        end
    end
    
    methods %implementing abstract methods
        function [azStart, azStop,elStart, elStop] = getAzimuthAndElevation(obj,positionStart,timeStart,positionStop,timeStop)
            [az1,el1,invR1, az2, el2, invR2] = obj.getInterpolateAzElInvR(timeStart,timeStop);
            %note that invR should be here in 1/m, because
            %getInterpolateAzElInvR is dividing by 1e3
            if(invR1 == 0 && invR2 ==0)
                %so far away that the position does not matter
                azStart = az1;
                azStop = az2;
                elStart = el1;
                elStop = el2;
            elseif(invR1 ~= 0 && invR2 ~= 0)
                %we could calculate position of the source at the begining
                %and in the end. 
                sourcePosStart = ATASim.ENUPos();
                sourcePosStart.updateFromRAzEl(1/invR1,az1,el1);
                
                diffPos1 = sourcePosStart - positionStart;
                [~,azStart,elStart] = diffPos1.getRAzEl();
                
                sourcePosStop = ATASim.ENUPos();
                sourcePosStop.updateFromRAzEl(1/invR2,az2,el2);
                
                diffPos2 = sourcePosStop - positionStop;
                [~,azStop,elStop] = diffPos2.getRAzEl();
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
            
            [az1,el1,invR1km] = obj.getFromPoly(timeStart);
            [az2,el2,invR2km] = obj.getFromPoly(timeStop);
            
            %conversion from km^-1 to m^-1
            invR2 = invR2km/1e3; 
            invR1 = invR1km/1e3;
            
            obj.lastTimeStart_ = timeStart;
            obj.lastAzStart_ = az1;
            obj.lastElStart_ = el1;
            obj.lastRangStart_ = invR1;
            
            obj.lastTimeStop_ = timeStop;
            obj.lastAzStop_ = az2;
            obj.lastElStop_ = el2;
            obj.lastRangStop_ = invR2;
        end
        
        function [az,el,invR] = getFromPoly(obj,time)
            assert(time >= obj.startOfFileTime_ && time <= obj.endOfFileTime_,'FileSteering:getFromPoly','time beyond steering file data')
            tdiff = time - obj.startOfFileTime_;
            tdd = tdiff.toDouble();
            az = ppval(obj.azimuthPolySpline_,tdd);
            el = ppval(obj.elevationPolySpline_,tdd);
            invR = ppval(obj.invRangePolySpline_,tdd);
        end
    end
end