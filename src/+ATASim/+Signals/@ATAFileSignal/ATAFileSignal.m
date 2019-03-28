classdef ATAFileSignal < ATASim.Signals.SourceSignal
    %Class ATAFileSignal - file read from
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        fileHandle_;
        antiAliasFilter_; % signal shaping filter (designfilt)
        remodulationFactorNumerator_;
        remodulationFactorDenominator_;
        frequencyShiftNorm_;
        doRemodulate_;
    end
    properties (Constant)
        antiAliasFilterOrder_ = 10;
    end
    methods % public
        function obj = ATAFileSignal(fs, fc, tint,maxAntTime, maxReflTime,startTime, filename, signalCarrier, signalBandwidth, discardTimeFlag)
            
            obj = obj@ATASim.Signals.SourceSignal(fs, fc, tint,maxAntTime,maxReflTime);
            
            obj.fileHandle_ = ATATools.IO.atatcpbinread(filename);
            
            if(~discardTimeFlag)
                %here we should look for the timestamp in the file closest
                %to the startTime variable. It should be added later
                error('ATAFileSignal:ATAFileSignal','not discardTimeFlag option not implemented yet');
            end
            
            if(isempty(signalCarrier))
                signalCarrier = obj.fileHandle_.freq*1e6; %in Hz
            end
            if(isempty(signalBandwidth))
                signalBandwidth = obj.fileHandle_.bw*1e6; %in Hz
            end
            
            keyboard
            
            if(signalBandwidth == fs && signalCarrier == fc)
                obj.doRemodulate_ = 0;
            else
                obj.doRemodulate_ = 1;
                
                obj.frequencyShiftNorm_ = obj.calcNormFreq(signalCarrier);
                
                %filter is applied on signal prior to remodulation
                lowF = ((obj.fc_ - obj.fs_/2) - signalCarrier)/signalBandwidth;
                highF = ((obj.fc_ + obj.fs_/2) - signalCarrier)/signalBandwidth;
                
                lowF = max(lowF,-0.5);
                highF = min(0.5,highF);
            end
            
            
            obj.createAntiAliasFilter(signalBandwidth,lowF,highF);
            
            
            
            
            obj.samplesVect_ = zeros(obj.reflLen_ + obj.sinkLen_+obj.mainLen_+1 + obj.filtOrder_,1);
            obj.lastGenTime_ = ATASim.TimeT(0);
            obj.makeSamples(startTime);
        end
        
        function delete(obj)
            %delete class destructor
            if ~isempty(obj.fileHandle_) && obj.fileHandle_.fh ~= 0
                ATATools.IO.atatcpfileclose(obj.fileHandle_);
            end
        end
    end
    
    methods % implementing abstract methods
        function makeSamples(obj,time)
            
            
            error('redo me')
            
            timeEnd = obj.lastGenTime_ + (obj.sinkLen_+obj.mainLen_)/obj.fs_;
            if time > timeEnd
                %creating new vector
                x = [ATASim.Signals.makeGaussianNoise(obj.reflLen_ + obj.sinkLen_+obj.mainLen_+1);zeros(obj.filtOrder_,1)];
                obj.samplesVect_ = obj.filter_.filter(x); %NOTE: samplesVect is longer than usual by filterLength!
            elseif time < obj.lastGenTime_
                error('BandNoiseSignal:makeSamples','trying to generate signal prior to last generation interval')
            else
                timeDiff = time-obj.lastGenTime_;
                samplIdx = timeDiff.toSamples(obj.fs_);
                
                %This may be fixed if the signal will be fraction-shifted
                assert(abs(rem(samplIdx,1)) < obj.sampleShiftAcc_,'BandNoiseSignal:makeSamples','Data sample is not an integer!');
                samplIdx = round(samplIdx);
                %end of section that may be fixed
                
                totalLen = obj.mainLen_+obj.reflLen_ + obj.sinkLen_+1 +obj.filtOrder_;
                firstValidSample = samplIdx+1;
                lastValidSample = totalLen;
                validLen = lastValidSample-firstValidSample+1;
                nToGen = samplIdx;
                xintermidiate = zeros(totalLen,1);
                
                xintermidiate(1:validLen) = obj.samplesVect_(firstValidSample:lastValidSample);
                xPreFilter = [ATASim.Signals.makeGaussianNoise(nToGen);zeros(obj.filtOrder_,1)];
                x = obj.filter_.filter(xPreFilter);
                xintermidiate(validLen-obj.filtOrder_+1:end) = xintermidiate(validLen-obj.filtOrder_+1:end) + x;
                
                obj.samplesVect_ = xintermidiate;
            end
            obj.lastGenTime_ = time;
        end
    end
    methods %(Access=private)
        function createAntiAliasFilter(obj, signalBandwidth,lowF,highF)
%            LowFilter = designfilt('lowpassiir','FilterOrder',obj.antiAliasFilterOrder_, 'PassbandFrequency',(highF-lowF),'PassbandRipple',0.2);
%            LowFilter22 = iirlp2bpc(LowFilter, 0.5, 2*[lowF, highF]);
            obj.antiAliasFilter_ = designfilt('bandpassfir','FilterOrder',obj.antiAliasFilterOrder_, 'CutoffFrequency1',lowF*signalBandwidth,'CutoffFrequency2',highF*signalBandwidth, 'SampleRate',signalBandwidth);
            
        end
    end
end