classdef HarmonicSignal < ATASim.Signals.SourceSignal
    %Class HarmonicSignal - harmonic signal class
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        harmNormFreq_; % normalized signal frequency
        harmLvls_; %relative power of harmonic signal
        startTime_; %the start time used to calculate initial phase
    end
    methods % public
        function obj = HarmonicSignal(fs, fc, tint,maxAntTime,maxReflTime,startTime,harmCell)
            obj = obj@ATASim.Signals.SourceSignal(fs, fc, tint,maxAntTime,maxReflTime);
            
            obj.startTime_ = startTime;
            
            LH = length(harmCell);
            obj.harmNormFreq_ = zeros(LH,1);
            obj.harmLvls_ = zeros(LH,1);
            for iK = 1:LH
                obj.harmNormFreq_(iK,1) = obj.calcNormFreq(harmCell{iK}.freq);
                obj.harmLvls_(iK,1) = harmCell{iK}.relPower;
            end
            obj.makeSamples(startTime);
            [obj.samplesVect_, obj.signalNormFactor_] = obj.normalizeSignal(obj.samplesVect_);
        end
        
        
    end
    methods % implementing abstract
        function makeSamples(obj,time)
            %makeSamples creates samples of harmonic signal
            %obj.makeSamples(time) creates samples with integration
            %around given time
            
            %assuming each one is a sinus and phase 0 starts with t=0. We
            %have normalized frequency
            obj.samplesVect_ = zeros(obj.reflLen_ + obj.sinkLen_+obj.mainLen_+1,1);
            samples = (-obj.reflLen_:(obj.mainLen_ + obj.sinkLen_)).';
            currTime = time - obj.startTime_;
            %using here %TimeT.toSamples function may degrade accuracy!
            currTimeDouble = currTime.toDouble();
            for iK = 1:length(obj.harmNormFreq_)
                cPhaseTerm = 2*pi*obj.harmNormFreq_(iK);
                obj.samplesVect_ = obj.samplesVect_ + 10^(obj.harmLvls_(iK)/20) * exp(1j*(samples*cPhaseTerm + mod(cPhaseTerm*currTimeDouble*obj.fs_,2*pi)));
                %obj.samplesVect_ = obj.samplesVect_ + 10^(obj.harmLvls_(iK)/20) * exp(1j*(samples*2*pi*obj.harmNormFreq_(iK) + mod(2*pi*obj.harmNormFreq_(iK)*currTimeDouble*obj.fs_,2*pi)));
            end
            obj.lastGenTime_ = time;
            if(~isinf(obj.signalNormFactor_))
                obj.samplesVect_ = obj.signalNormFactor_*obj.samplesVect_;
            end
        end
    end
end
