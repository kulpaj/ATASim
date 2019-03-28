classdef StationaryReceiverRecorder < ATASim.Sinks.ReceiverRecorder
    %Class ReceiverRecorder - groundbased transmitter source class
    
    %Author: Janusz S. Kulpa (May 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        position_; %ENUPos position of reciever
    end
    
    methods
        function obj = StationaryReceiverRecorder(id,temp,fs,fc,steering,beam,startSimTime,tStep,dumpPath,pos)
            obj = obj@ATASim.Sinks.ReceiverRecorder(id,temp,fs,fc,steering,beam,startSimTime,tStep,dumpPath);
            
            assert(isa(pos,'ATASim.ENUPos'),'Receiver:Receiver','pos must be ENUPos class')
            obj.position_ = pos;
            
        end        
    end
    
    methods %implementing
        function [pos1, pos2] = getStartStopPosition(obj,time1,time2)
            
            pos1offset = ATASim.ENUPos();
            pos2offset = ATASim.ENUPos();
            %TODO, FIXME implement beam and check if offset is in good
            %direction!
            %[azStart, azStop ,elStart, elStop] = obj.getAzimuthAndElevation(obj.position_,time1,obj.position_,time2);
            %r = obj.beamPattern_.getCenterOffset();
            %pos1offset.updateFromRAzEl(r,azStart,elStart);
            %pos2offset.updateFromRAzEl(r,azStop,elStop);
            
            pos1 = obj.position_ + pos1offset;
            pos2 = obj.position_ + pos2offset; 
            
        end
    end
end