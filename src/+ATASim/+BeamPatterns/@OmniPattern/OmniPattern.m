classdef OmniPattern < ATASim.BeamPatterns.AntennaPattern
    %Class OmniPattern - Omnidirection beam pattern
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        
    end
    
    methods
        function obj = OmniPattern()
            %OmniPattern class constructor
        end
    end
    methods %implementation of abstract methods
        function y = getGain(~,azim,elev)
            %getGain return gain of the antenna
            %always return 1
            
            assert(all(size(azim) == size(elev)),'PencilPattern:getGain','elev and azim pattern does not match')
            y = ones(size(azim));
        end
    end
end