classdef ReceiverRecorder < ATASim.Sinks.Receiver
    %Class ReceiverRecorder - groundbased transmitter source class
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        fd_;
        dataVect_;
        dataVectSize_;
        lastSaveTime_;
        currTime_;
        framePerRecording_;
        saveGain_ = -inf; %numerical gain for saving
    end
    properties
        frameBytes_ = 2048;
        framePerSec_ = 51200; %
        bps_ = 16; %int32
        firstBatchGainMargin_ = 2; %lin. 4 means 2 bits to spare 
    end
    
    methods %(Access=private) %implemented elsewhere
        writeHeader(obj);
        writeSignal(obj,nOfZeros);
    end
    methods
        function obj = ReceiverRecorder(id,temp,fs,fc,steering,beam,startSimTime,tStep,dumpPath)
            obj = obj@ATASim.Sinks.Receiver(id,temp,fs,fc,steering,beam);
                        
            assert(isa(startSimTime,'ATASim.TimeT'),'ReceiverRecorder:ReceiverRecorder','startSimTime must be TimeT')
            obj.lastSaveTime_ = startSimTime-ATASim.TimeT(1/fs);
            obj.dataVectSize_ = tStep.toSamples(fs);
            obj.dataVect_ = [];
            obj.currTime_ = startSimTime;
            
            assert(isdir(dumpPath),'ReceiverRecorder:ReceiverRecorder','directory does not exist (%s)',dumpPath);
            filename = sprintf('%s%cdata%d.bin',dumpPath,filesep,id);
            assert(~exist(filename,'file'),'ReceiverRecorder:ReceiverRecorder','file %s already exist!',filename);
            
            obj.fd_ = fopen(filename,'w','ieee-le');
            assert(obj.fd_ > -1,'ReceiverRecorder:ReceiverRecorder',ferror(obj.fd_));
            
            obj.framePerRecording_ = round(obj.framePerSec_ * tStep.toDouble());
            
            obj.writeHeader();
        end
        
        function delete(obj)
            %delete class destructor
            if ~isempty(obj.fd_) && obj.fd_ ~= 0
                fclose(obj.fd_);
            end
        end
        
        function resetSignal(obj,time)
            assert(time > obj.lastSaveTime_,'ReceiverRecorder:resetSignal','trying to update past recording!')
            obj.dataVect_ = obj.getThermalNoise(obj.dataVectSize_);
            obj.currTime_ = time;
        end
        
        function pushSignal(obj,sSig,azimStart, elevStart, azimStop,elevStop,currTime,endCurrTime)
            
            gain = obj.getGain(length(sSig),azimStart, elevStart, azimStop,elevStop,currTime,endCurrTime);
            10*log10(abs(gain(1)))
            obj.addToSignal(sqrt(gain).*sSig);
        end
        
        function saveData(obj)
            assert(obj.currTime_ > obj.lastSaveTime_,'ReceiverRecorder:saveData','lastSaveTime value in the future wrt currTime');
            timeDiff = obj.currTime_ - obj.lastSaveTime_;
            nOfZeros = timeDiff.toSamples(obj.fs_)-1;
            nBins = obj.dataVectSize_/obj.framePerRecording_;
            assert(rem(nOfZeros,nBins) == 0,'ReceiverRecorder:saveData','number of zero samples (%d) not dividable by frame size (%d)!',nOfZeros,nBins);
            obj.writeSignal(nOfZeros);
            obj.lastSaveTime_ = obj.currTime_ + ATASim.TimeT((obj.dataVectSize_-1)/obj.fs_);
        end
        
    end
    methods %(Access=private)
        function addToSignal(obj,signal)
           assert(length(signal) ==  obj.dataVectSize_,'ReceiverRecorder:addToSignal','signal length mismatch')
           obj.dataVect_ = obj.dataVect_ + signal;
        end
    end
end