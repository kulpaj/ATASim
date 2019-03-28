classdef SourceSignal < handle
    %Class SourceSignal - abstract class for signal simulation
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties %protected?
        mainLen_; %the number of samples corresponding to declared (maximum) integration (constant position interval) time,
        sinkLen_; %the number of samples corresponding to scene (receivers) size with respect to ATASim.ENUPos(0,0,0);
        reflLen_; %the number of samples corresponding to furthest reflecting point (receivers) with respect to ATASim.ENUPos(0,0,0);
        
        fs_; %sampling frequency [Hz]
        fc_; %signal center (carrier) frequency [Hz]
        samplesVect_; % data vector of the samples of the signal
        lastGenTime_; % the time corresponding to samplesVect_[sinkLen_+1] (the "actual" sample)
        signalNormFactor_ = -Inf;
    end
    properties(Constant)
        sampleShiftAcc_ =1e-9; %sample fraction that will be considered 0
    end
    methods % public
        function obj = SourceSignal(fs, fc, tint,maxAntTime, maxReflTime)
            %SourceSignal class constructor
            %obj = SourceSignal(fs, fc, tint,maxAntTime, maxReflTime)
            %maxAntTime - time nessesary for light to travel from center to
            %furtherst antenna
            %maxReflTime - time nessesary for light to travel from center
            %to furthest reflector
            
            %protection in case no reflectors are far away
            maxReflTime = max(maxReflTime,maxAntTime);
            
            obj.fs_ = fs;
            obj.fc_ = fc;
            obj.mainLen_ = tint.toSamples(fs);
            obj.sinkLen_ = ceil(fc*maxAntTime);
            obj.reflLen_ = ceil(fc*maxReflTime);
            obj.lastGenTime_ = ATASim.TimeT(0);
        end
        
        
        function y = getSamples(obj,timeStart,timeStop,rangeStart,rangeStop)
            %getSamples returns the remodulated, time-shifted samples
            %y = obj.getSamples(time,timeStop,rangeStart,rangeStop)
            
            %we are assuming that rangeStop is proper, i.e. calculated wrt
            %last but one sample before timeStop
            
            %sample reflLen_+1 of vector samplesVect_ corresponds to
            %lastGenTime_
            
            timeDiff = timeStart-obj.lastGenTime_;
            %here the toDouble function is used instead of to samples,
            %because fractional samples may be encountered!
            samplIdx = obj.fs_*timeDiff.toDouble();
            
            samplIdxStart = samplIdx + obj.reflLen_ + 1;
            
            assert(samplIdxStart >= 1,'SourceSignal:getSamples','time is too early!');
            
            intTime = timeStop - timeStart;
            nSamples = intTime.toSamples(obj.fs_)+1;
            
            intShift = round(samplIdxStart);
            fracShift = samplIdxStart - intShift;
            
            assert(intShift + nSamples -1 <= obj.reflLen_ + obj.sinkLen_+obj.mainLen_+1,'SourceSignal:getSamples','time is too late or intTime too big!');
            
            xMod = obj.timeShift(obj.samplesVect_,fracShift);
            ynotNorm = obj.phaseDistShift(xMod(intShift:intShift+nSamples-1),rangeStart,rangeStop );
            %xMod = obj.timeShift(obj.samplesVect_(intShift:intShift+nSamples-1),fracShift);
            %ynotNorm = obj.phaseDistShift(xMod,rangeStart,rangeStop );
            
            %y = obj.normalizeSignal(ynotNorm);
            y = ynotNorm;
        end
        
        function fc = getFc(obj)
            %getFc central frequency accessor
            %fc = obj.getFc() returns central (carrier) frequency
            fc = obj.fc_;
        end
    end
    
    methods(Abstract)
        %function that updates the samplesVect_ for new timestamp
        makeSamples(obj,time)
        
    end
    
    methods %(Access=private)
        function f = calcNormFreq(obj,freq)
            %calcNormFreq calculates a normalized frequency
            %f = obj.calcNormFreq(freq) calculates the normalized frequency
            %with respect to carrier and sampling frequencies
            f = (freq - obj.fc_)./obj.fs_;
            assert(all(f >= -0.5) && all(f <= 0.5),'SourceSignal:calcNormFreq','signal frequency beyond frequency range (%f, %f)', obj.fc_-obj.fs_/2, obj.fc_+obj.fs_/2);
        end
        
        function y = phaseDistShift(obj,x,dStart,dStop)
            
            oneOverLambda = obj.fc_/ATASim.ATAConstants.c;
            drange = linspace(dStart,dStop,length(x)).';
            y = x.*exp(-1j*mod(2*pi*drange*oneOverLambda,2*pi));
        end
    end
    methods (Static)
        function [y,norm]= normalizeSignal(x)
            %normalizeSignal normalizes the power of the signal
            %y = normalizeSignal(x) normalizes the power of the signal x
            %with respect to signal length
            norm = sqrt(length(x))/sqrt(x'*x);
            y = norm*x;
        end
        
        function y = timeShift(x,shift)
            %timeShift shifts the signal in time
            %y = timeShift(x,shift) shifts signal x by shift samples
            y = ATATools.Calc.timeShift(x,shift);
            
%             if abs(shift) < ATASim.Signals.SourceSignal.sampleShiftAcc_
%                 y = x;
%                 return
%             end
%             
%             %TODO: this extension is done to eliminate a (circular) bias.
%             %Consider if this is important or not
%             xnew = [x;zeros(length(x),1)];
%             
%             N = length(xnew);
%             mod = linspace(-pi,pi-2*pi/N,N);
%             
%             X = fftshift(fft(xnew));
%             
%             Y = X.*exp(1j*mod.'*shift);
%             ynew = ifft(fftshift(Y));
%             
%             y = ynew(1:length(x));
            
        end
        
        function y = freqShift(x,shift)
            %freqShift shifts the signal in frequency
            %y = freqShift(x,shift)  shifts signal x by shift frequency
            %bins
            N = length(x);
            mod = linspace(0,2*pi-2*pi/N,N);
            y = x.*exp(1j*mod.'*shift);
        end
    end
    
end