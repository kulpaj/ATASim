classdef QAMSignal < ATASim.Signals.IQSignal & ATASim.Signals.Coding.QAMCoding
    %Class QAMSignal - QAM single channel signal class
    
    %Author: Janusz S. Kulpa (Dec 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    
   
    methods % public
        function obj = QAMSignal(fs, fc, tint,maxAntTime,maxReflTime,startTime,qamFreq,qamTsymbol,qamBPS)
            obj = obj@ATASim.Signals.IQSignal(fs, fc, tint,maxAntTime,maxReflTime,startTime,qamFreq,qamTsymbol);
            obj = obj@ATASim.Signals.Coding.QAMCoding(qamBPS);
            
            symbols = obj.getSymbolSpace();
            
            obj.lastSymbol_ = symbols(1);
            obj.makeSamples(startTime);
            [obj.samplesVect_, obj.signalNormFactor_] = obj.normalizeSignal(obj.samplesVect_);
        end
        
        
    end
%     methods % implementing abstract
%         function Symbols = getSymbolSpace(obj)
%             Symbols = 
%             part1 = sqrt(2^obj.bitPerSymbol_);
%             if(~rem(part1,1)) %square
%                 I = linspace(-1,1,part1);
%                 Q = linspace(-1,1,part1);
%                 [IM,QM] = meshgrid(I,Q);
%                 IQM = IM+1j*QM;
%                 Symbols = IQM(:);
%             else
%                 switch (obj.bitPerSymbol_)
%                     case 1 %BPSK
%                         Symbols = [-1; 1];
%                     case 5
%                         I = linspace(-1,1,6);
%                         Q = linspace(-1,1,6);
%                         [IM,QM] = meshgrid(I,Q);
%                         IQM = IM+1j*QM;
%                         Symbols = IQM(:);
%                         Symbols = setdiff(Symbols,[1+1j,1-1j,-1+1j,-1-1j]);
%                 end
%             end
%         end
%     end
end
