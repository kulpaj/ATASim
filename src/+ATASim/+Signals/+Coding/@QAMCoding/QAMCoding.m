classdef QAMCoding < handle
    %Class QAMCoding - QAM code symbol space
    
    %Author: Janusz S. Kulpa (Dec 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    
    %we assume that symbol distibution is uniform and
    properties
        bitPerSymbol_; %bitrate of the signal
    end
    
    methods % public
        function obj = QAMCoding(qamBPS)
            assert(qamBPS > 0 && rem(qamBPS,1) == 0 && qamBPS < 10,'QAMCoding:QAMCoding','Bit per symbol not integer or out of range (%f)',qamBPS)
            
            obj.bitPerSymbol_ = qamBPS;
        end
        
        
    end
    methods % implementing abstract
        function Symbols = getSymbolSpace(obj)
            
            part1 = sqrt(2^obj.bitPerSymbol_);
            if(~rem(part1,1)) %square
                I = linspace(-1,1,part1);
                Q = linspace(-1,1,part1);
                [IM,QM] = meshgrid(I,Q);
                IQM = IM+1j*QM;
                Symbols = IQM(:);
            else
                switch (obj.bitPerSymbol_)
                    case 1 %BPSK
                        Symbols = [-1; 1];
                    case 3
                        Symbols = exp(1j*pi*0.25)*[1; -1; 1j; -1j; 0.5; -0.5; 0.5*1j; -0.5*1j; ];
                    case 5
                        I = linspace(-1,1,6);
                        Q = linspace(-1,1,6);
                        [IM,QM] = meshgrid(I,Q);
                        IQM = IM+1j*QM;
                        Symbols = IQM(:);
                        Symbols = setdiff(Symbols,[1+1j,1-1j,-1+1j,-1-1j]);
                end
            end
        end
    end
end
