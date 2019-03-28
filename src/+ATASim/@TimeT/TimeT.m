classdef TimeT < handle
    %Class TimeT - for sec_ and ns_ time storage and calculation
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties %(Access=private)
        sec_; % sec_ variable. TAI time should be used
        ns_; % ns_ variable (0:99999999)
    end
    
    properties(Constant)%(Constatn,Access=private)
        nsAccuracy_ = 1; %the accuracy in ns to which the equality is checked
    end
    
    methods
        function obj = TimeT(varargin)
            %TimeT class constructor
            %possible calls:
            %obj = ATASim.TimeT() - time = 0;
            %obj = ATASim.TimeT(TimeT_var) - copy
            %obj = ATASim.TimeT(time_double) - ns are computed based on
            %fraction of time_double
            %obj = ATASim.TimeT(sec,ns) - both sec and ns
            if nargin == 1
                if(isa(varargin{1},'ATASim.TimeT'))
                    %other TimeT
                    secs = varargin{1}.sec_;
                    nss = varargin{1}.ns_;
                else
                    %seconds only
                    [trg_s,trg_ns] = obj.toSNs(varargin{1});
                    secs = trg_s;
                    nss = trg_ns;
                end
            elseif nargin == 2
                secs = varargin{1};
                nss = varargin{2};
            elseif nargin == 0
                obj.sec_ = 0;
                obj.ns_ = 0;
                return
            else
                error('TimeT:TimeT','Unknown Constructor');
            end
            assert(length(secs) == length(nss),'TimeT:TimeT','inputs should have the same length');
            %             if(length(secs) == 1)
            %                 obj.sec_ = secs;
            %                 obj.ns_ = nss;
            %             else
            for iK = length(secs):-1:1
                obj(iK).sec_ = secs(iK);
                obj(iK).ns_ = nss(iK);
            end
            %             end
        end
        
        function s = getSec(obj)
            %getSec second accessor
            for iK = numel(obj):-1:1
                s(iK) = obj(iK).sec_;
            end
        end
        
        function s = getNs(obj)
            %getNs nanosecond accessor
            for iK = numel(obj):-1:1
                s(iK) = obj(iK).ns_;
            end
        end
        
        function sc = toSamples(obj,fc)
           % toSamples accurately calculates no of samples
           %sc = toSamples(obj,fc)
           for iK = numel(obj):-1:1
               %rounding with 1e-5 accuracy
               sc(iK) = round((fc/1e9)*obj(iK).ns_ + obj(iK).sec_*fc,5);
           end
        end
        
        %if i.e. 0 + ATATime.TimeT is used, following function will fail!!!
        function c = plus(obj,trg)
            %plus time addition (+) overloaded function
            % c = obj + timeTvar creates new TimeT var with value being
            % sum of obj and timeTvar.
            % c = obj + time_double allows to put an floating point
            % variable. Note, that time_double + obj wont work!
            if(isa(trg,'ATASim.TimeT'))
                for iK = numel(obj):-1:1
                    ns = obj(iK).ns_ + trg.ns_;
                    sAdd = floor(ns./1e9);
                    nsRest = mod(ns,1e9);
                    c(iK)=ATASim.TimeT(obj(iK).sec_ + sAdd + trg.sec_,nsRest);
                end
            else
                [trg_s,trg_ns] = obj.toSNs(trg);
                
                for iK = numel(obj):-1:1
                    ns = obj(iK).ns_ + trg_ns;
                    sAdd = floor(ns./1e9);
                    nsRest = mod(ns,1e9);
                    c(iK)=ATASim.TimeT(obj(iK).sec_ + sAdd + trg_s,nsRest);
                end
            end
        end
        
        %if i.e. 0 - ATATime.TimeT is used, following function will fail!!!
        function c = minus(obj,trg)
            %minus time subtraction (-) overloaded function
            % c = obj - timeTvar creates new TimeT var with value being
            % difference of obj and timeTvar.
            % c = obj - time_double allows to put an floating point
            % variable. Note, that time_double - obj wont work!
            if(isa(trg,'ATASim.TimeT'))
                for iK = numel(obj):-1:1
                    ns = obj(iK).ns_ - trg.ns_;
                    sAdd = floor(ns./1e9);
                    nsRest = mod(ns,1e9);
                    c(iK)=ATASim.TimeT(obj(iK).sec_ + sAdd - trg.sec_,nsRest);
                end
            else
                [trg_s,trg_ns] = obj.toSNs(trg);
                
                for iK = numel(obj):-1:1
                    ns = obj(iK).ns_ - trg_ns;
                    sAdd = floor(ns./1e9);
                    nsRest = mod(ns,1e9);
                    c(iK)=ATASim.TimeT(obj(iK).sec_ + sAdd - trg_s,nsRest);
                end
            end
        end
        
        function c = eq(obj,trg)
            c = logical(zeros(size(obj)));
            if(isa(trg,'ATASim.TimeT'))
                for iK = numel(obj):-1:1
                    c(iK) = (obj(iK).sec_ == trg.sec_) .* (abs(obj(iK).ns_ - trg.ns_) < obj(iK).nsAccuracy_);
                end
            else
                [trg_s,trg_ns] = obj.toSNs(trg);
                for iK = numel(obj):-1:1
                    c(iK) = (obj(iK).sec_ == trg_s) .* (abs(obj(iK).ns_ - trg_ns) < obj(iK).nsAccuracy_);
                end
            end
        end
        
        function c = lt(obj,trg)
            assert(isa(trg,'ATASim.TimeT'),'TimeT:lt','input not TimeT');
            c = logical(zeros(size(obj)));
            for iK = numel(obj):-1:1
                if(obj(iK).sec_ == trg.sec_)
                    c(iK) = (obj(iK).ns_ < trg.ns_);
                else
                    c(iK) = (obj(iK).sec_ < trg.sec_);
                end
            end
        end
        
        function c = gt(obj,trg)
            assert(isa(trg,'ATASim.TimeT'),'TimeT:gt','input not TimeT');
            c = logical(zeros(size(obj)));
            for iK = numel(obj):-1:1
                if(obj(iK).sec_ == trg.sec_)
                    c(iK) = (obj(iK).ns_ > trg.ns_);
                else
                    c(iK) = (obj(iK).sec_ > trg.sec_);
                end
            end
        end
        
        function c = le(obj,trg)
            assert(isa(trg,'ATASim.TimeT'),'TimeT:lt','input not TimeT');
            c = logical(zeros(size(obj)));
            for iK = numel(obj):-1:1
                if(obj(iK).sec_ == trg.sec_)
                    c(iK) = (obj(iK).ns_ <= trg.ns_);
                else
                    c(iK) = (obj(iK).sec_ <= trg.sec_);
                end
            end
        end
        
        function c = ge(obj,trg)
            assert(isa(trg,'ATASim.TimeT'),'TimeT:gt','input not TimeT');
            c = logical(zeros(size(obj)));
            for iK = numel(obj):-1:1
                if(obj(iK).sec_ == trg.sec_)
                    c(iK) = (obj(iK).ns_ >= trg.ns_);
                else
                    c(iK) = (obj(iK).sec_ >= trg.sec_);
                end
            end
        end
        
        function d = toDouble(obj)
            %toDouble converts TimeT to floating point seconds
            %d = obj.toDouble() converts the variable. The accuracy may
            %decrease
            
            %warning('TimeT:toDouble','to calculate integer samples, use toSamples instead')
            
            d = zeros(size(obj));
            for iK = numel(obj):-1:1
                d(iK) = obj(iK).sec_ + obj(iK).ns_/1e9;
            end
        end
        
    end
    methods (Static)%(Static,Access=private)
        function [trg_s, trg_ns] = toSNs(val)
            %toSNs converts double to s and ns
            trg_s = floor(val);
            trg_ns = mod(val,1)*1e9;
        end
    end
end