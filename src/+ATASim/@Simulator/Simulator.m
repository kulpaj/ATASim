classdef Simulator
    properties
        scene_;
        tint_;
        startTime_;
        stopTime_;
        singleSampleTime_;
        show_progress_ = 1;
    end
    
    methods
        function obj = Simulator(xmlName)
            xmlconfig = ATASim.XMLReader.readATASimFile(xmlName);
            obj.scene_ = ATASim.Scene(xmlconfig);
            obj.tint_ = ATASim.TimeT(xmlconfig.time.blockTime);
            obj.startTime_ =  ATASim.TimeT(xmlconfig.time.startTime);
            obj.stopTime_ = ATASim.TimeT(xmlconfig.time.startTime) + xmlconfig.time.obsTime;
            obj.singleSampleTime_ = ATASim.TimeT(1/obj.scene_.fs_);
        end
    end
    
    methods %in other files, 
       simulateAll( obj )
       printScene(obj, timestamp)
    end
    methods %(Access=private)%in other files, 
       simulateSingleTime(obj,timeStart, timeEnd)
    end
    
end