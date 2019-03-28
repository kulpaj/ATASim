classdef IdealPencilPattern < ATASim.BeamPatterns.AntennaPattern
    %Class IdealPencilPattern - Ideal pencil beampattern
        
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        gain_; % gain in the mainbeam [dB]
        width_; % width of the main beam [deg]
    end
    
    methods
        function obj = IdealPencilPattern(gain,width)
            %IdealPencilPattern class constructor
            %obj = IdealPencilPattern(gain,width) creates a ideal pencil
            %antena with given gain [dB] and beamwidth [deg]. 
            %The beamwidth in the same in azimuth and elevation and gain is
            %0 beyond main beam
            obj.gain_ = gain;
            obj.width_ = width;
        end
    end
    
    methods %implementing abstract functions
        function y  = getGain(obj,azim,elev)
            %getGain antenna gain for given azimuth and elevation
            %y = obj.getGain(azim,elev) returns (linear) power gain for
            %given direction
            
            assert(all(size(azim) == size(elev)),'PencilPattern:getGain','elev and azim pattern does not match')          
            y = 10^(obj.gain_/10)*(obj.modTo180180(azim).^2 + obj.modTo180180(elev).^2 <= (obj.width_/2)^2);
            assert(all(size(azim) == size(y)),'PencilPattern:getGain','something went wrong')
        end
    end
end