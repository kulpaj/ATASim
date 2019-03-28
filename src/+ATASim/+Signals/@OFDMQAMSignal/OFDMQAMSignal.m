classdef OFDMQAMSignal < ATASim.Signals.OFDMIQSignal & ATASim.Signals.Coding.QAMCoding
    %Class QAMSignal - QAM single channel signal class
    
    %Author: Janusz S. Kulpa (Dec 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    
   
    methods % public
        function obj = OFDMQAMSignal(fs, fc, tint,maxAntTime,maxReflTime,startTime,qamFreq,qamTsymbol, channels, guardfrac,qamBPS)
            obj = obj@ATASim.Signals.OFDMIQSignal(fs, fc, tint,maxAntTime,maxReflTime,startTime,qamFreq,qamTsymbol, channels, guardfrac);
            obj = obj@ATASim.Signals.Coding.QAMCoding(qamBPS);
            
            symbols = obj.getSymbolSpace();
            
            symbolsNo = floor(length(symbols)*rand(obj.noOfChannels_,1));
            
            
            
            obj.lastSymbols_ = symbols(symbolsNo+1);
            obj.makeSamples(startTime);
            [obj.samplesVect_, obj.signalNormFactor_] = obj.normalizeSignal(obj.samplesVect_);
        end
        
        
    end

end
