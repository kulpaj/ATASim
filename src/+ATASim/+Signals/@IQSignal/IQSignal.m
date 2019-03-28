classdef IQSignal < ATASim.Signals.SourceSignal
    %Class HarmonicSignal - harmonic signal class
    
    %Author: Janusz S. Kulpa (Dec 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    
    %we assume that symbol distibution is uniform and
    properties
        normFreq_; % normalized signal frequency
        symbolSamples_;
        lastSymbol_;
        lastSymbolTstart_;
        tSymbol_;
        startTime_; %the start time used to calculate initial phase
    end
    methods(Abstract)
        getSymbolSpace(obj)
    end
    
    methods % public
        function obj = IQSignal(fs, fc, tint,maxAntTime,maxReflTime,startTime,sigFreq,sigTsymbol)
            obj = obj@ATASim.Signals.SourceSignal(fs, fc, tint,maxAntTime,maxReflTime);
            obj.startTime_ = startTime;
            obj.normFreq_ = obj.calcNormFreq(sigFreq);
            obj.tSymbol_ = ATASim.TimeT(sigTsymbol);
            obj.symbolSamples_ = sigTsymbol*fs;
            obj.lastSymbolTstart_ = ATASim.TimeT(0);
            %Make sure that the constructors inheriting after IQSignal
            %are calling:
            %obj.lastSymbol_ = symbols(1);
            %obj.makeSamples(startTime);
            %so all is properly initialized
        end
        
        
    end
    methods % implementing abstract
        function makeSamples(obj,time)
            
            PossibleSamples = obj.getSymbolSpace();
            NSpace = length(PossibleSamples);
            
            timeEnd = obj.lastGenTime_ + (obj.sinkLen_+obj.mainLen_)/obj.fs_;
            currTime = time - obj.startTime_;
            
            cPhaseTerm = 2*pi*obj.normFreq_;
            if time > timeEnd
                %creating new vector
                samples = (-obj.reflLen_:(obj.mainLen_ + obj.sinkLen_)).';
                
                
                SymbolNumber = (floor(samples/obj.symbolSamples_+obj.startTime_.toDouble/obj.tSymbol_.toDouble));
                SymbolNumber = SymbolNumber - SymbolNumber(1) + 1;
                nSymbols = SymbolNumber(end);
                
                SymbolsInSignal = PossibleSamples(floor(1+NSpace*rand(nSymbols,1)));
                
                %checking if we need to look what the last symbol was
                beg_of_refl_time = currTime - obj.reflLen_/obj.fs_;
                if(beg_of_refl_time > obj.lastSymbolTstart_ + obj.tSymbol_)
                    %do nothing
                else
                    %we must preserve the last sample
                    SymbolsInSignal(1) = obj.lastSymbol_;
                end
                currTimeDouble = currTime.toDouble();
                
                obj.samplesVect_ = SymbolsInSignal(SymbolNumber).* exp(1j*mod(samples*cPhaseTerm + mod(cPhaseTerm*currTimeDouble*obj.fs_,2*pi) , 2*pi));
                
                if(~isinf(obj.signalNormFactor_))
                    obj.samplesVect_ = obj.signalNormFactor_*obj.samplesVect_;
                end
                
                obj.lastSymbol_ = SymbolsInSignal(end);
                obj.lastSymbolTstart_ = currTime + samples(find(SymbolNumber == SymbolNumber(end),1))/obj.fs_;
                
            elseif time < obj.lastGenTime_
                error('IQSignal:makeSamples','trying to generate signal prior to last generation interval')
            else
                timeDiff = time-obj.lastGenTime_;
                samplIdx = timeDiff.toSamples(obj.fs_);
                
                %This may be fixed if the signal will be fraction-shifted
                assert(abs(rem(samplIdx,1)) < obj.sampleShiftAcc_,'IQSignal:makeSamples','Data sample is not an integer!');
                samplIdx = round(samplIdx);
                %end of section that may be fixed
                
                if(samplIdx ~= 0)
                    
                    totalLen = obj.mainLen_+obj.reflLen_ + obj.sinkLen_+1;
                    firstValidSample = samplIdx+1;
                    lastValidSample = totalLen;
                    validLen = lastValidSample-firstValidSample+1;
                    %nToGen = samplIdx;
                    xintermidiate = zeros(totalLen,1);
                    
                    samples = ((obj.mainLen_ + obj.sinkLen_ - samplIdx+1):(obj.mainLen_ + obj.sinkLen_)).';
                    SymbolNumberTmp = samples/obj.symbolSamples_+obj.startTime_.toDouble/obj.tSymbol_.toDouble;
                    
                    SymbolNumber = floor(SymbolNumberTmp) - floor(SymbolNumberTmp(1)) + 1;
                    nSymbols = SymbolNumber(end);
                    
                    SymbolsInSignal = PossibleSamples(floor(1+NSpace*rand(nSymbols,1)));
                    
                    if rat(SymbolNumberTmp(1),1) %we start with part of previous symbol
                        SymbolsInSignal(1) = obj.lastSymbol_;
                    else %we are lucky, starting with brand new symbol
                        
                    end
                    
                    currTimeDouble = currTime.toDouble();
                    
                    xintermidiate(1:validLen) = obj.samplesVect_(firstValidSample:lastValidSample);
                    if(~isinf(obj.signalNormFactor_))
                        xintermidiate(validLen+1:end) = obj.signalNormFactor_*SymbolsInSignal(SymbolNumber).* exp(1j*mod(samples*cPhaseTerm + mod(cPhaseTerm*currTimeDouble*obj.fs_,2*pi) , 2*pi));
                    else
                        xintermidiate(validLen+1:end) = SymbolsInSignal(SymbolNumber).* exp(1j*mod(samples*cPhaseTerm + mod(cPhaseTerm*currTimeDouble*obj.fs_,2*pi) , 2*pi));
                    end
                    
                    
                    obj.samplesVect_ = xintermidiate;
                    obj.lastSymbol_ = SymbolsInSignal(end);
                    obj.lastSymbolTstart_ = currTime + samples(find(SymbolNumber == SymbolNumber(end),1))/obj.fs_;
                end
            end
            obj.lastGenTime_ = time;
        end
    end
end
