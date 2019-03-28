classdef Scene < handle
    %Class Scene - the simulation scene description
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    properties
        sources_; %Cell containing all sources (transmitters)
        sinks_; %Cell containing all sinks (receivers)
        fs_;
        fc_;
        %maybe, if ground reflection will be used, a demMap and scenesize
        %should be used
    end
    methods
        function obj = Scene(xmlstruct)
            simStartTime = ATASim.TimeT(xmlstruct.time.startTime);
            
            fs = xmlstruct.freq.fs;
            fc = xmlstruct.freq.fc;
            obj.fs_ = fs;
            obj.fc_ = fc;
            tint = ATASim.TimeT( xmlstruct.time.blockTime);
            
            LRx = length(xmlstruct.sinks.Antennas);
            obj.sinks_ = cell(LRx,1);
            LTx = length(xmlstruct.sources);
            obj.sources_ = cell(LTx,1);
            
            steeringMap = containers.Map();
            AntPos = ATATools.IO.ReadAtaAnt([],xmlstruct.sinks.AntennaFile);
            
            maxAntTime = obj.calculateMaxAntennaTime(AntPos);
            
            %TODO FIXME recalculate for reflectors
            %maxReflTime = obj.calculateMaxReflTime(AntPos);
            maxReflTime = obj.calculateMaxAntennaTime(AntPos);
            
            %sinks
            for iK = 1:LRx
                currSteering = obj.createSteering(xmlstruct.sinks.Antennas{iK}.steering,steeringMap);
                
                currBeam = obj.createBeam(xmlstruct.sinks.Antennas{iK}.beam);
                
                cId = xmlstruct.sinks.Antennas{iK}.id;
                ind = find(AntPos(:,1) == cId,1);
                assert(~isempty(ind),'Scene:Scene','id %d not found in antenna file',cId);
                currPos = ATASim.ENUPos(-AntPos(ind,3),AntPos(ind,2),AntPos(ind,4));
                %ReceiverRecorder(id,temp,bandwidth,pos,steering,beam,dumpPath)
                obj.sinks_{iK} = ATASim.Sinks.StationaryReceiverRecorder(cId,xmlstruct.sinks.Antennas{iK}.temp,fs,fc,currSteering,currBeam,simStartTime,tint,xmlstruct.sinks.DumpDir,currPos);
            end
            
            
            %sources
            for iK = 1:LTx
                %geting source signal
                currSignal = obj.createSignal(xmlstruct.sources{iK}.signal, fc, fs, simStartTime, tint, maxAntTime, maxReflTime);
                
                sourceName = xmlstruct.sources{iK}.name;
                
                switch(xmlstruct.sources{iK}.type)
                    case 'celestialSource'
                        %geting steering (FILE ONLY!)
                        if(steeringMap.isKey(xmlstruct.sources{iK}.file))
                            currSteering = steeringMap(xmlstruct.sources{iK}.file);
                        else
                            currSteering = ATASim.Steering.FileSteering(xmlstruct.sources{iK}.file);
                            steeringMap(xmlstruct.sources{iK}.file) = currSteering;
                        end
                        %creating source
                        obj.sources_{iK} = ATASim.Sources.CelestialSource(sourceName, currSignal, currSteering, xmlstruct.sources{iK}.powLevel);
                    case 'groundSource'
                        %geting steering
                        currSteering = obj.createSteering(xmlstruct.sources{iK}.beamSteering,steeringMap);
                        
                        currBeam = obj.createBeam(xmlstruct.sources{iK}.beam);
                        
                        currPos = ATASim.ENUPos(xmlstruct.sources{iK}.pos.x,xmlstruct.sources{iK}.pos.y,xmlstruct.sources{iK}.pos.z);
                        
                        obj.sources_{iK} = ATASim.Sources.GroundSource(sourceName, currSignal, currSteering, xmlstruct.sources{iK}.powerdBW, currPos, currBeam);
                        
                    case 'satSource'
                        %geting steering (FILE ONLY!)
                        if(steeringMap.isKey(xmlstruct.sources{iK}.file))
                            currSteering = steeringMap(xmlstruct.sources{iK}.file);
                        else
                            currSteering = ATASim.Steering.FileSteering(xmlstruct.sources{iK}.file);
                            steeringMap(xmlstruct.sources{iK}.file) = currSteering;
                        end
                        
                        currFootprint = obj.createSteering(xmlstruct.sources{iK}.beamSteering,steeringMap);
                        
                        currBeam = obj.createBeam(xmlstruct.sources{iK}.beam);
                        
                        obj.sources_{iK} = ATASim.Sources.SatSource(sourceName, currSignal, currSteering,  xmlstruct.sources{iK}.powerdBW, currBeam, currFootprint);
                    otherwise
                        error('Scene:Scene','unknown source type (%s)',xmlstruct.sources{iK}.type);
                end
            end
        end
        
        function x = calculateMaxAntennaTime(~,antPosMat)
            %calculates time nessesary for wave travel between 0,0,0 and
            %furtherst antenna
            antDistances = sqrt(sum(antPosMat(:,2:4).^2,2));
            maxDist = max(antDistances);
            x = maxDist/ATASim.ATAConstants.c;
        end
    end
    
    methods %private?
        function printScene(obj,timestart,haxes)
            timeSt = ATASim.TimeT(timestart);
            if (nargin < 3)
                hfig = figure();
                haxes = axes(hfig);
            end
            cla(haxes)
            hold on;
            
            %mean position of the antennas (only for plotting)
            X_Med = 0;
            Y_Med = 0;
            for iK = 1:length(obj.sinks_)
                x = obj.sinks_{iK}.position_.getE();
                y = obj.sinks_{iK}.position_.getN();
                X_Med = X_Med + x;
                Y_Med = Y_Med + y;
                [Az,~,El,~] = obj.sinks_{iK}.steering_.getAzimuthAndElevation(obj.sinks_{iK}.position_, timeSt, obj.sinks_{iK}.position_ ,timeSt);
                x_next = x + 20*cosd(El) .* sind(Az);
                y_next = y + 20*cosd(El) .* cosd(Az);
                plot(haxes,x,y,'bv')
                text(haxes,x,y,sprintf('Rx %d',obj.sinks_{iK}.id_))
                plot(haxes,[x,x_next],[y,y_next],'b-');
            end
            X_Med = X_Med/length(obj.sinks_);
            Y_Med = Y_Med/length(obj.sinks_);
            
            MidPos = ATASim.ENUPos(X_Med,Y_Med,0);
            
            is_mid_plotted = 0;
            
            for iL = 1:length(obj.sources_)
                if (isa(obj.sources_{iL},'ATASim.Sources.CelestialSource'))
                    if(~is_mid_plotted)
                        plot(haxes,X_Med,Y_Med,'ro','MarkerSize',6,'Linewidth',2);
                        is_mid_plotted = 1;
                    end
                    [Az,~,El,~] = obj.sources_{iL}.ephSteering_.getAzimuthAndElevation(MidPos, timeSt, MidPos ,timeSt);
                    x_next = X_Med + 30*cosd(El) .* sind(Az);
                    y_next = Y_Med + 30*cosd(El) .* cosd(Az);
                    plot(haxes,[X_Med, x_next],[Y_Med,y_next],'r.-')
                    text(haxes,x_next,y_next,obj.sources_{iL}.name_,'Interpreter','none');
                elseif (isa(obj.sources_{iL},'ATASim.Sources.GroundSource'))
                    x = obj.sources_{iL}.position_.getE();
                    y = obj.sources_{iL}.position_.getN();
                    [Az,~,El,~] = obj.sources_{iL}.steering_.getAzimuthAndElevation(obj.sources_{iL}.position_, timeSt, obj.sources_{iL}.position_ ,timeSt);
                    x_next = x + 20*cosd(El) .* sind(Az);
                    y_next = y + 20*cosd(El) .* cosd(Az);
                    plot(haxes,x,y,'r^')
                    text(haxes,x,y,obj.sources_{iL}.name_,'Interpreter','none');
                    plot(haxes,[x,x_next],[y,y_next],'r-');
                elseif (isa(obj.sources_{iL},'ATASim.Sources.SatSource'))
                    if(~is_mid_plotted)
                        plot(haxes,X_Med,Y_Med,'ro','MarkerSize',3);
                        is_mid_plotted = 1;
                    end
                    error('not implemented')
                end
                
            end
            xlabel(haxes,'East [m]')
            ylabel(haxes,'North [m]')
            
            %mattime = timestart/86400 + datenum('01-Jan-1970');
            title(num2str(timestart))
            hold off
        end
        
        function currBeam = createBeam(~,xmlentry)
            switch (xmlentry.type)
                case 'omni'
                    currBeam = ATASim.BeamPatterns.OmniPattern();
                case 'pencil'
                    currBeam = ATASim.BeamPatterns.PencilPattern(xmlentry.gain, xmlentry.width);
                case 'idealpencil'
                    currBeam = ATASim.BeamPatterns.IdealPencilPattern(xmlentry.gain, xmlentry.width);
                case 'measured'
                    currBeam = ATASim.BeamPatterns.MeasPattern(xmlentry.file);
                otherwise
                    error('Scene:createBeam','unknown antenna beam type (%s)',xmlentry.type);
            end
        end
        
        function [currSteering,fileSteeringMap] = createSteering(~,xmlentry,fileSteeringMap)
            assert(isa(fileSteeringMap,'containers.Map'),'Scene:getSteering','bad call, fileSteeringMap must be containers.Map class')
            if(strcmp(xmlentry.type,'file'))
                if(fileSteeringMap.isKey(xmlentry.file))
                    currSteering = fileSteeringMap(xmlentry.file);
                else
                    currSteering = ATASim.Steering.FileSteering(xmlentry.file);
                    fileSteeringMap(xmlentry.file) = currSteering;
                end
            elseif (strcmp(xmlentry.type,'const'))
                currSteering = ATASim.Steering.ConstSteering(xmlentry.azimuth,xmlentry.elevation);
            else
                error('Scene:createSteering','unknown antenna steering type (%s)',xmlentry.type);
            end
        end
        
        function currSignal = createSignal(~, xmlentry, fc, fs, simStartTime, tint, maxAntTime, maxReflTime)
            switch(xmlentry.type)
                case 'sin'
                    currSignal = ATASim.Signals.HarmonicSignal(fs, fc, tint,maxAntTime,maxReflTime, simStartTime, xmlentry.harmonics);
                case 'bandnoise'
                    currSignal = ATASim.Signals.BandNoiseSignal(fs, fc, tint,maxAntTime,maxReflTime, simStartTime, xmlentry.passCell, xmlentry.filterOrder, xmlentry.freqSpacing);
                case 'chirp'
                    currSignal = ATASim.Signals.ChirpSignal(fs, fc, tint,maxAntTime,maxReflTime, simStartTime, xmlentry.linear, xmlentry.geometric);
                case 'qam'
                    currSignal = ATASim.Signals.QAMSignal(fs,fc,tint,maxAntTime,maxReflTime, simStartTime,xmlentry.freq,xmlentry.tsymbol,xmlentry.bitpersymbol);
                case 'ofdm_qam'
                    currSignal = ATASim.Signals.OFDMQAMSignal(fs,fc,tint,maxAntTime,maxReflTime, simStartTime,xmlentry.freq,xmlentry.tsymbol,xmlentry.channels,xmlentry.guard,xmlentry.bitpersymbol);
                case 'pulsar'
                    currSignal = ATASim.Signals.PulsarSignal(fs, fc, tint,maxAntTime,maxReflTime, simStartTime);
                    error('Scene:createSignal','Not fully implemented (%s)',xmlentry.type);
                otherwise
                    error('Scene:createSignal','unknown signal type (%s)',xmlentry.type);
            end
        end
        
    end
end