classdef OFDMIQSignal < ATASim.Signals.SourceSignal
    %Class HarmonicSignal - harmonic signal class
    
    %Author: Janusz S. Kulpa (Dec 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    
    %we assume that symbol distibution is uniform and
    properties
        normFreq_; % normalized signal frequency
        symbolSamples_;
        lastSymbols_;
        lastSymbolTstart_;
        tSymbol_;
        noOfChannels_;
        normChannels_;
        guardTime_;
        startTime_; %the start time used to calculate initial phase
        
        %for testing purposes, 
        startingPhase_;
    end
    methods(Abstract)
        getSymbolSpace(obj)
    end
    
    methods % public
        function obj = OFDMIQSignal(fs, fc, tint,maxAntTime,maxReflTime,startTime,sigFreq,sigTsymbol, channels, guardfrac)
            obj = obj@ATASim.Signals.SourceSignal(fs, fc, tint,maxAntTime,maxReflTime);
            obj.startTime_ = startTime;
            
            assert(guardfrac >= 0 && guardfrac < 1,'OFDMIQSignal:OFDMIQSignal','guardfrac must be between 0 and 1')
            
            obj.tSymbol_ = ATASim.TimeT(sigTsymbol*(1+guardfrac));
            obj.symbolSamples_ = sigTsymbol*fs;
            obj.lastSymbolTstart_ = ATASim.TimeT(0);
            
            obj.noOfChannels_ = channels;
            
            
            
            freqSpacing = 1/sigTsymbol;
            edgeFreq = (obj.noOfChannels_-1)/2*freqSpacing;
            freqLow = sigFreq - edgeFreq;
            freqHigh = sigFreq + edgeFreq;
            
            %testing if that is not beyond receiver frequency range
            normLow = obj.calcNormFreq(freqLow);
            normHigh = obj.calcNormFreq(freqHigh);
            
            obj.normChannels_ = linspace(normLow,normHigh,obj.noOfChannels_);
            
            %starting phase calculation
            obj.startingPhase_ = rand(obj.noOfChannels_,1)*2*pi;
            %obj.startingPhase_ = zeros(obj.noOfChannels_,1);
            
            %Make sure that the constructors inheriting after OFDMIQSignal
            %are calling:
            %symbols = obj.getSymbolSpace();
            %symbolsNo = floor(length(symbols)*rand(obj.noOfChannels,1));
            %obj.lastSymbols_ = symbols(symbolsNo+1);
            %obj.makeSamples(startTime);
            %[obj.samplesVect_, obj.signalNormFactor_] = obj.normalizeSignal(obj.samplesVect_);
            %so all is properly initialized
        end
        
        
    end
    methods % implementing abstract
        function makeSamples(obj,time)
            
            PossibleSamples = obj.getSymbolSpace();
            %PossibleSamples = 1;
            NSpace = length(PossibleSamples);
            
            timeEnd = obj.lastGenTime_ + (obj.sinkLen_+obj.mainLen_)/obj.fs_;
            currTime = time - obj.startTime_;
            
            if time > timeEnd
                %creating new vector
                samples = (-obj.reflLen_:(obj.mainLen_ + obj.sinkLen_)).';
                
                
                SymbolNumber = (floor(samples/obj.symbolSamples_+obj.startTime_.toDouble/obj.tSymbol_.toDouble));
                SymbolNumber = SymbolNumber - SymbolNumber(1) + 1;
                nSymbols = SymbolNumber(end);
                
                SymbolsInSignal = PossibleSamples(floor(1+NSpace*rand(nSymbols,obj.noOfChannels_)));
                
                %checking if we need to look what the last symbol was
                beg_of_refl_time = currTime - obj.reflLen_/obj.fs_;
                if(beg_of_refl_time > obj.lastSymbolTstart_ + obj.tSymbol_)
                    %do nothing
                else
                    %we must preserve the last sample
                    SymbolsInSignal(1,:) = obj.lastSymbols_;
                end
                currTimeDouble = currTime.toDouble();
                obj.samplesVect_ = zeros(length(SymbolNumber),1);
                for iK = 1:obj.noOfChannels_
                    cPhaseTerm = 2*pi*obj.normChannels_(iK);
                    obj.samplesVect_ = obj.samplesVect_ + SymbolsInSignal(SymbolNumber,iK).* exp(1j*mod(samples*cPhaseTerm + mod(cPhaseTerm*currTimeDouble*obj.fs_+obj.startingPhase_(iK),2*pi) , 2*pi));
                end
                
                if(~isinf(obj.signalNormFactor_))
                    obj.samplesVect_ = obj.signalNormFactor_*obj.samplesVect_;
                end
                
                obj.lastSymbols_ = SymbolsInSignal(end,:);
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
                    
                    SymbolsInSignal = PossibleSamples(floor(1+NSpace*rand(nSymbols,obj.noOfChannels_)));
                    
                    if rat(SymbolNumberTmp(1),1) %we start with part of previous symbol
                        SymbolsInSignal(1,:) = obj.lastSymbols_;
                    else %we are lucky, starting with brand new symbol
                        
                    end
                    
                    currTimeDouble = currTime.toDouble();
                    
                    xintermidiate(1:validLen) = obj.samplesVect_(firstValidSample:lastValidSample);
                    if(~isinf(obj.signalNormFactor_))
                        for iK = 1:obj.noOfChannels_
                            cPhaseTerm = 2*pi*obj.normChannels_(iK);
                            xintermidiate(validLen+1:end) = xintermidiate(validLen+1:end) + obj.signalNormFactor_*SymbolsInSignal(SymbolNumber,iK).* exp(1j*mod(samples*cPhaseTerm + mod(cPhaseTerm*currTimeDouble*obj.fs_ + obj.startingPhase_(iK),2*pi) , 2*pi));
                        end
                    else
                        for iK = 1:obj.noOfChannels_
                            cPhaseTerm = 2*pi*obj.normChannels_(iK);
                            xintermidiate(validLen+1:end) = xintermidiate(validLen+1:end) + SymbolsInSignal(SymbolNumber,iK).* exp(1j*mod(samples*cPhaseTerm + mod(cPhaseTerm*currTimeDouble*obj.fs_ + obj.startingPhase_(iK),2*pi) , 2*pi));
                        end
                    end
                    
                    obj.lastSymbols_ = SymbolsInSignal(end,:);
                    obj.lastSymbolTstart_ = currTime + samples(find(SymbolNumber == SymbolNumber(end),1))/obj.fs_;
                
                    obj.samplesVect_ = xintermidiate;
                    
                end
            end
            obj.lastGenTime_ = time;
        end
    end
end
