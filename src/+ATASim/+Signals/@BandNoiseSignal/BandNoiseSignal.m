classdef BandNoiseSignal < ATASim.Signals.SourceSignal
    %Class BandNoiseSignal - band limited noise source signal class
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        filter_; % signal shaping filter (designfilt)
        filtOrder_; % filter order
    end
    properties (Constant)
        %filterError_ = 1e-6; %may be used instead of filtOrder_ if
        %evaluation is included (and much bigger order introduced)
        defaultFreqSpacing_ = 1e3; % frequency step in filter design
        defaultFiltOrder_ = 100; % filter order
        doPlotFilter_ = 0;
    end
    methods % public
        function obj = BandNoiseSignal(fs, fc, tint,maxAntTime, maxReflTime,startTime,passCell, filterOrder, freqSpacing)
            %BandNoiseSignal class constructor
            %obj = BandNoiseSignal(fs, fc, tint,maxAntTime, maxReflTime,startTime,passCell, filterOrder, freqSpacing)
            %creates an object.
            
            obj = obj@ATASim.Signals.SourceSignal(fs, fc, tint,maxAntTime,maxReflTime);
            
            if(isempty(filterOrder) || filterOrder == 0)
                obj.filtOrder_ = obj.defaultFiltOrder_;
            else
                obj.filtOrder_ = filterOrder;
            end
            if(isempty(freqSpacing) || freqSpacing == 0)
                freqSpacing = obj.defaultFreqSpacing_;
            end
            
            obj.createFilter(passCell,freqSpacing)
            obj.samplesVect_ = zeros(obj.reflLen_ + obj.sinkLen_+obj.mainLen_+1 + obj.filtOrder_,1);
            obj.lastGenTime_ = ATASim.TimeT(0);
            obj.makeSamples(startTime);
            [obj.samplesVect_, obj.signalNormFactor_] = obj.normalizeSignal(obj.samplesVect_);
        end
    end
    
    methods % implementing abstract methods
        function makeSamples(obj,time)
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
                if(~isinf(obj.signalNormFactor_))
                    x = obj.signalNormFactor_*x;
                end
                xintermidiate(validLen-obj.filtOrder_+1:end) = xintermidiate(validLen-obj.filtOrder_+1:end) + x;
                
                obj.samplesVect_ = xintermidiate;
            end
            obj.lastGenTime_ = time;
        end
    end
    methods %(Access=private)
        function createFilter(obj,passCell, freqSpacing)
            %createFilter creates filter based on passband criteria
            %obj.createFilter(passCell, freqSpacing) creates a filter object.
            
            freqList = linspace(-0.5,0.5,obj.fs_/freqSpacing+1);
            ampList = zeros(size(freqList));
            for iK = 1:length(passCell)
                fl =  obj.calcNormFreq(passCell{iK}.startFreq);
                fh =  obj.calcNormFreq(passCell{iK}.stopFreq);
                [~, flInd] = min(abs(freqList-fl));
                [~, fhInd] = min(abs(freqList-fh));
                
                actAmpl = ones(1,fhInd - flInd + 1)* 10^(passCell{iK}.relPower/10);
                
                
                for iL = 1:length(passCell{iK}.shapeInterp)
                    switch (passCell{iK}.shapeInterp{iL}.type)
                        case 'spline'
                            bbfreqList = freqList(flInd:fhInd);
                            spObj = spline(obj.calcNormFreq(passCell{iK}.shapeInterp{iL}.freq),10.^(passCell{iK}.shapeInterp{iL}.gain/10));
                            currAmpl = ppval(spObj,bbfreqList);
                        case '1/f'
                            hfFreqList = freqList(flInd:fhInd) * obj.fs_ + obj.fc_;
                            hfFreqListNrm = hfFreqList/hfFreqList(1);
                            currAmpl = 1./hfFreqListNrm;
                        case '1/f2'
                            hfFreqList = freqList(flInd:fhInd) * obj.fs_ + obj.fc_;
                            hfFreqListNrm = hfFreqList/hfFreqList(1);
                            currAmpl = 1./(hfFreqListNrm.^2);
                        case 'gaussian'
                            currAmpl = gausswin(fhInd - flInd + 1,passCell{iK}.shapeInterp{iL}.sigma).';
                        case 'spectralindex'
                            hfFreqList = freqList(flInd:fhInd) * obj.fs_ + obj.fc_;
                            hfFreqListNrm = hfFreqList/hfFreqList(1);
                            currAmpl = hfFreqListNrm.^(passCell{iK}.shapeInterp{iL}.alpha);
                        case 'function'
                            hfFreqList = freqList(flInd:fhInd) * obj.fs_ + obj.fc_;
                            currAmpl = passCell{iK}.shapeInterp{iL}.funHandle(hfFreqList);
                        otherwise
                            error('BandNoiseSignal:createFilter','unknown shape ingerpolation type');
                    end
                    
                    assert(all(currAmpl >= 0),'BandNoiseSignal:createFilter','All gain values must be greater than 0');
                    assert(all(size(actAmpl) == size(currAmpl)),'BandNoiseSignal:createFilter','Output dimension mismatch');
                    actAmpl = actAmpl .* currAmpl;
                end
                
                ampList(flInd:fhInd) = ampList(flInd:fhInd) + actAmpl;
                
                
            end
            ampList(1) = 0;
            ampList(end) = 0;
            
            obj.filter_ = designfilt('arbmagfir','FilterOrder',obj.filtOrder_, 'Frequencies',freqList*obj.fs_,'Amplitudes',ampList,'SampleRate',obj.fs_);
            
            if(obj.doPlotFilter_)
                freqz(obj.filter_,10000,'whole');
                pause(3);
            end
        end
    end
end