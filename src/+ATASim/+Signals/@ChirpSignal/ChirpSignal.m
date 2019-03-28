classdef ChirpSignal < ATASim.Signals.SourceSignal
    properties
        linearTerms_;
        geometricTerms_;
        startTime_; %made to aglin the phase
    end
    methods % public
        function obj = ChirpSignal(fs, fc, tint,maxAntTime, maxReflTime, startTime, linearCell, geometricCell)
            obj = obj@ATASim.Signals.SourceSignal(fs, fc, tint,maxAntTime, maxReflTime);
            %part of this is to check if all frequencies are in range
            obj.startTime_ = startTime;
            if(~isempty(linearCell)) %workaround
                obj.linearTerms_ = struct('f0norm',[],'f1norm',[],'tRampNorm',[],'relPower',[]);
            end
            if(~isempty(geometricCell)) %workaround
                obj.geometricTerms_ = struct('f0norm',[],'f1norm',[],'tRampNorm',[],'relPower',[]);
            end
            
            for iK = length(linearCell):-1:1
                tTampNorm = obj.fs_*linearCell{iK}.tRamp;
                obj.linearTerms_(iK) = struct('f0norm',obj.calcNormFreq(linearCell{iK}.f0),'f1norm',obj.calcNormFreq(linearCell{iK}.f1),'tRampNorm',tTampNorm,'relPower',linearCell{iK}.relPower);
            end
            for iK = length(geometricCell):-1:1
                tTampNorm = obj.fs_*geometricCell{iK}.tRamp;
                obj.geometricTerms_(iK) = struct('f0norm',obj.calcNormFreq(geometricCell{iK}.f0),'f1norm',obj.calcNormFreq(geometricCell{iK}.f1),'tRampNorm',tTampNorm,'relPower',geometricCell{iK}.relPower);
                assert(obj.geometricTerms_(iK).f0norm * obj.geometricTerms_(iK).f1norm > 0,'ChirpSignal:ChirpSignal','geometrical chirp is experimental, both upper and lower freq mist be either above or below sampling frequency');
            end
            obj.makeSamples(startTime);
            [obj.samplesVect_, obj.signalNormFactor_] = obj.normalizeSignal(obj.samplesVect_);
        end
        
    end
    
    methods % implementing abstract
        function makeSamples(obj,time)
            %makeSamples creates samples of chirp signal
            %obj.makeSamples(time) creates samples with integration
            %around given time
            
            %assuming each one strats with phase 0 at t=0. We
            %have normalized frequency
            obj.samplesVect_ = zeros(obj.reflLen_ + obj.sinkLen_+obj.mainLen_+1,1);
            samples = (-obj.reflLen_:(obj.mainLen_ + obj.sinkLen_)).';
            currTime = time - obj.startTime_;
            %using here %TimeT.toSamples function may degrade accuracy!
            curr0SampleFract = currTime.toDouble()*obj.fs_;
            samplesCorrected = samples + curr0SampleFract;
            
            for iK = 1:length(obj.linearTerms_)
                k = (obj.linearTerms_(iK).f1norm - obj.linearTerms_(iK).f0norm)/obj.linearTerms_(iK).tRampNorm;
                %cPhaseTerm = 2*pi*obj.linearTerms_(iK).f0norm;
                
                %finding points when phase is changed:
                n_phase_jumps = floor((samplesCorrected)/obj.linearTerms_(iK).tRampNorm);
                phaseJump = mod( (2*pi* (obj.linearTerms_(iK).tRampNorm*obj.linearTerms_(iK).f0norm + k/2*obj.linearTerms_(iK).tRampNorm.^2)) ,2*pi);
                phaseVect = n_phase_jumps*phaseJump;
                
                %TODO: not aligned toward 0:2pi for better accuracy,
                %another mod for 2pi may be beneficial for signal accuracy
                samplesCorrectedMod = mod(samplesCorrected,obj.linearTerms_(iK).tRampNorm);
                obj.samplesVect_ = obj.samplesVect_ + 10^(obj.linearTerms_(iK).relPower/20) * exp(1j*(2*pi* (samplesCorrectedMod*obj.linearTerms_(iK).f0norm + k/2*samplesCorrectedMod.^2) + phaseVect));
                
                %spectrogram(obj.samplesVect_)
                %figure(2)
                %plot(real(obj.samplesVect_))
                %keyboard
            end
            
            for iK = 1:length(obj.geometricTerms_)
                k = (obj.geometricTerms_(iK).f1norm/obj.geometricTerms_(iK).f0norm)^(1/obj.geometricTerms_(iK).tRampNorm);
                
                n_phase_jumps = floor((samplesCorrected)/obj.geometricTerms_(iK).tRampNorm);
                phaseJump = mod(  (2*pi*obj.geometricTerms_(iK).f0norm *((k.^(obj.geometricTerms_(iK).tRampNorm)-1)/log(abs(k))))  ,2*pi);
                phaseVect = n_phase_jumps*phaseJump;
                
                %TODO: not aligned toward 0:2pi for better accuracy,
                %another mod for 2pi may be beneficial for signal accuracy
                %geometric part need to be verified
                obj.samplesVect_ = obj.samplesVect_ + 10^(obj.geometricTerms_(iK).relPower/20) * exp(1j*(2*pi*obj.geometricTerms_(iK).f0norm *((k.^mod(samplesCorrected,obj.geometricTerms_(iK).tRampNorm)-1)/log(abs(k))) + phaseVect));
                
                %spectrogram(obj.samplesVect_)
                %figure(2)
                %plot(real(obj.samplesVect_))
                %keyboard
            end
            if(~isinf(obj.signalNormFactor_))
                obj.samplesVect_ = obj.signalNormFactor_*obj.samplesVect_;
            end
            obj.lastGenTime_ = time;
        end
        
    end
end