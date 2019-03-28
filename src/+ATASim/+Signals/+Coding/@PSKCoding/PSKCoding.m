classdef PSKCoding < handle
    %Class PSKCoding - PSK code symbol space
    
    %Author: Janusz S. Kulpa (Jan 2019)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    
    %we assume that symbol distibution is uniform and
    properties
        bitPerSymbol_; %bitrate of the signal
    end
    
    methods % public
        function obj = PSKCoding(pskBPS)
            assert(pskBPS > 0 && rem(pskBPS,1) == 0 && pskBPS < 10,'PSKCoding:PSKCoding','Bit per symbol not integer or out of range (%f)',pskBPS)
            
            obj.bitPerSymbol_ = pskBPS;
        end
        
        
    end
    methods % implementing abstract
        function Symbols = getSymbolSpace(obj)
            
            NSym = 2^obj.bitPerSymbol_;
            
            piSpace = (2*pi/NSym)*(0:NSym-1).';
            
            IQM = exp(1j*piSpace);
            Symbols = IQM(:);
        end
    end
end
