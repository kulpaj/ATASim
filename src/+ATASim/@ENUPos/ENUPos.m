classdef ENUPos < handle
    %Class ENUPos - for East-North-Up Cartesian coordinate system
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        e_; % Cartesian coordinates East [m]
        n_; % Cartesian coordinates North [m]
        u_; % Cartesian coordinates Up [m]
    end
    
    %WARN, not foolproof for vectors
    methods
        function obj = ENUPos(varargin)
            %ENUPos class constructor
            %obj = ATASim.ENUPos() default constructor for position 0,0,0
            %obj = ATASim.ENUPos(enuPos) creates a position from other ENUPos item
            %obj = ATASim.ENUPos(e,n,u) creates a position 3 double variables
            if nargin == 0
                obj.e_ = 0;
                obj.n_ = 0;
                obj.u_ = 0;
            elseif nargin == 1
                assert(isa(varargin{1},'ATASim.ENUPos'),'ENUPos:ENUPos','parametr must be ENUPos');
                obj.e_ = varargin{1}.e_;
                obj.n_ = varargin{1}.n_;
                obj.u_ = varargin{1}.u_;
            elseif nargin == 3
                assert(isnumeric(varargin{1}) && isnumeric(varargin{2}) && isnumeric(varargin{3}),'ENUPos:ENUPos','parametr must be numeric');
                obj.e_ = varargin{1};
                obj.n_ = varargin{2};
                obj.u_ = varargin{3};
            else
                error('ENUPos:ENUPos','bad input')
            end
        end
        
        function updateFromRAzEl(obj,rSteer,azimSteer,elevSteer)
            %updateFromRAzEl updates the position based on rSteer,azimSteer,elevSteer from point 0 0 0 
            %obj.updateFromRAzEl(rSteer,azimSteer,elevSteer)
            obj.e_ = rSteer.* cosd(elevSteer) .* sind(azimSteer);
            obj.n_ = rSteer.*cosd(elevSteer) .* cosd(azimSteer);
            obj.u_ = rSteer.*sind(elevSteer);
        end
        
        function [r,az,el] = getRAzEl(obj)
            %getRAzEl calculates range, azimuth and elevation form point 0,0,0
            %[r,az,el] = obj.getRAzEl() returns (r)ange [m], (az)imuth
            %[deg] and (el)evation [deg] wrt point 0,0,0
            partGrnd = obj.e_^2+obj.n_^2;
            
            r = sqrt(partGrnd + obj.u_^2);
            
            gPath = sqrt(partGrnd);
            el = atan2d(obj.u_,gPath);
            
            %TODO check if it is in good, where and how azim goes?
            %warning('ENUPos:getRAzEl','check angles!')
            az = atan2d(obj.e_,obj.n_);
        end
        
        function y = distance(obj,trg)
            %distance calculates the distance between points
            %y = obj.distance() calculates dist to point 0,0,0
            %y = obj.distance(pos) calculates dist between pos and obj
            if nargin == 1
                %distance to 0
                y = sqrt(obj.e_^2 + obj.n_^2 + obj.u_^2);
            elseif isa(trg,'ATASim.ENUPos')
                y = sqrt((obj.e_-trg.e_)^2 + (obj.n_-trg.n_)^2 + (obj.u_-trg.u_)^2);
            else
                error('ENUPos:distance','bad call parameters');
            end
        end

        function pos = minus(obj,trg)
            %minus difference of two ENUPos
            %pos = obj - trg return the diference (element by element) of
            %trg and obj positions
            assert(isa(trg,'ATASim.ENUPos'),'ENUPos:minus','trg must be ENUPos')
            pos = ATASim.ENUPos(obj.e_ - trg.e_,obj.n_ - trg.n_, obj.u_ - trg.u_);
        end
        
        function pos = plus(obj,trg)
            %plus sum of two ENUPos
            %pos = obj + trg return the sum (element by element) of trg and
            %obj positions
            assert(isa(trg,'ATASim.ENUPos'),'ENUPos:plus','trg must be ENUPos')
            pos = ATASim.ENUPos(obj.e_ + trg.e_,obj.n_ + trg.n_, obj.u_ + trg.u_);
        end
        
        function c = eq(obj,trg)
            assert(isa(trg,'ATASim.ENUPos'),'ENUPos:eq','trg must be ENUPos')
            c = (obj.e_ == trg.e_) & (obj.n_ == trg.n_) & (obj.u_ == trg.u_);
        end
        
        function e = getE(obj)
           %getE e_ value accessor
           e = obj.e_;
        end
        
        function n = getN(obj)
           %getN n_ value accessor
           n = obj.n_;
        end
        
        function u = getU(obj)
           %getU u_ value accessor
           u = obj.u_;
        end
        
        function disp(obj)
            %disp display the position
            fprintf('ENUPos:\n');
            for iK = 1:numel(obj)
                fprintf('\t%f,%f,%f\n',obj(iK).e_,obj(iK).n_,obj(iK).u_);
            end
        end
    end
    
    methods %disabled comparators
        function ge(~,~)
            error('ENUPos:ge','unable to compare two positions!')
        end
        function gt(~,~)
            error('ENUPos:ge','unable to compare two positions!')
        end
        function le(~,~)
            error('ENUPos:ge','unable to compare two positions!')
        end
        function lt(~,~)
            error('ENUPos:ge','unable to compare two positions!')
        end
    end
end