classdef XMLReader
    %The class to read important parameters from XML file
    
    %Author: Janusz S. Kulpa (Apr 2018)
    %Embry-Riddle Aeronautical University/Politechnika Warszawska
    methods(Static)
        function configStruct = readATASimFile(filename)
            %readATASimFile reads and converts xml file to a structure
            MainDocument = xmlread(filename);
            Tmp = MainDocument.getChildNodes();
            assert(Tmp.getLength == 1 && strcmp(Tmp.item(0).getTagName,'simulator'),'XMLReader:readATASimFile','unexpected entry, only 1 "simulator" entry expected');
            MainNode = Tmp.item(0);
            configStruct.freq = getFreqStructure(MainNode);
            configStruct.time = getTimeStructure(MainNode);
            configStruct.sinks = getSinksStructure(MainNode);
            configStruct.sources = getSourcesStructure(MainNode);
        end
    end
end

%%
% GENERAL
%

function freqConfig = getFreqStructure(node)
freqConfig = struct('fs',0,'fc',0);
FNode = node.getElementsByTagName('freq');
%keyboard
assert(FNode.getLength == 1,'XMLReader:getFreqStructure','Only 1 "freq" definition allowed');
numVal = str2double(FNode.item(0).getAttribute('fs'));
assert(~isnan(numVal),'XMLReader:getFreqStructure','fs is NaN');
freqConfig.fs = numVal;
numVal = str2double(FNode.item(0).getAttribute('center'));
assert(~isnan(numVal),'XMLReader:getFreqStructure','center is NaN');
freqConfig.fc = numVal;
end

function timeConfig = getTimeStructure(node)
timeConfig = struct('startTime',0,'blockTime',0,'obsTime',0);
FNode = node.getElementsByTagName('time');
assert(FNode.getLength == 1,'XMLReader:getTimeStructure','Only 1 "time" definition allowed');
numVal = str2double(FNode.item(0).getAttribute('start'));
assert(~isnan(numVal),'XMLReader:getFreqStructure','start is NaN');
timeConfig.startTime = numVal;
numVal = str2double(FNode.item(0).getAttribute('blockTime'));
assert(~isnan(numVal),'XMLReader:getFreqStructure','blockTime is NaN');
timeConfig.blockTime = numVal;
numVal = str2double(FNode.item(0).getAttribute('obsTime'));
assert(~isnan(numVal),'XMLReader:getFreqStructure','nIntervals is NaN');
timeConfig.obsTime = numVal;
end

%%
% SINKS
%

function sinksConfig = getSinksStructure(node)
sinksConfig = struct('AntennaFile',[],'DumpDir',[],'Antennas',[]);
FNode = node.getElementsByTagName('sinks');
assert(FNode.getLength == 1,'XMLReader:getSinksStructure','Only 1 "sinks" definition allowed');
AFN = FNode.item(0).getElementsByTagName('antenna_file');
assert(AFN.getLength == 1,'XMLReader:getSinksStructure','Only 1 "sinks/antenna_file" definition allowed');
namestr = string(AFN.item(0).getTextContent().toCharArray().').char;
sinksConfig.AntennaFile = namestr;

AFD = FNode.item(0).getElementsByTagName('dump_dir');
assert(AFD.getLength == 1,'XMLReader:getSinksStructure','Only 1 "sinks/dump_dir" definition allowed');
namestr = string(AFD.item(0).getTextContent().toCharArray().').char;
sinksConfig.DumpDir = namestr;

AFA = FNode.item(0).getElementsByTagName('antenna');
assert(AFA.getLength > 0,'XMLReader:getSinksStructure','at least one "sinks/antenna" must be present');
sinksConfig.Antennas = getAntennasCell(AFA);
end

function ACell = getAntennasCell(node)
LA = node.getLength;
ACell = cell(LA,1);

usedIDs = nan(LA,1);
for iK = 1:LA
    cItem = struct('id',0,'temp',0,'beam',[],'steering',[]);
    currSubnode = node.item(iK-1);
    cVal = str2double(currSubnode.getAttribute('id'));
    assert(~any(usedIDs == cVal) && ~isnan(cVal),'XMLReader:getAntennasCell','mutliple receiver id defined (%d)',cVal);
    cItem.id = cVal;
    usedIDs(iK) = cVal;
    cVal = str2double(currSubnode.getAttribute('temp'));
    assert(~isnan(cVal) && cVal >= 0,'XMLReader:getAntennasCell','temp must be non-negative (%d)',cVal);
    cItem.temp = cVal;
    beamN = currSubnode.getElementsByTagName('beam');
    assert(beamN.getLength == 1,'XMLReader:getAntennasCell','Only 1 "beam" definition allowed');
    cItem.beam = getBeam(beamN);
    steerN = currSubnode.getElementsByTagName('steering');
    assert(steerN.getLength == 1,'XMLReader:getAntennasCell','Only 1 "steering" definition allowed');
    cItem.steering = getSteering(steerN);
    ACell{iK} = cItem;
end

end

function bStruct = getBeam(node)
type = string(node.item(0).getAttribute('type').toCharArray().');

switch lower(type)
    case 'omni'
        bStruct.type = 'omni';
    case 'pencil'
        bStruct.type = 'pencil';
        numVal = str2double(node.item(0).getAttribute('gain'));
        assert(~isnan(numVal),'XMLReader:getBeam','gain is NaN');
        bStruct.gain = numVal;
        numVal = str2double(node.item(0).getAttribute('width'));
        assert(~isnan(numVal),'XMLReader:getBeam','width is NaN');
        bStruct.width = numVal;
    case 'idealpencil'
        bStruct.type = 'idealpencil';
        numVal = str2double(node.item(0).getAttribute('gain'));
        assert(~isnan(numVal),'XMLReader:getBeam','gain is NaN');
        bStruct.gain = numVal;
        numVal = str2double(node.item(0).getAttribute('width'));
        assert(~isnan(numVal),'XMLReader:getBeam','width is NaN');
        bStruct.width = numVal;
    case 'measured'
        bStruct.type = 'measured';
        namestr = string(node.item(0).getAttribute('file').toCharArray().').char;
        bStruct.file = namestr;
    otherwise
        error('XMLReader:getBeam','type not supported (%s)',type);
        
end

end

function sStruct = getSteering(node)

file = string(node.item(0).getAttribute('file').toCharArray().').char;
azim = str2double(node.item(0).getAttribute('azimuth'));
ele = str2double(node.item(0).getAttribute('elevation'));

filetype = ~isempty(file) || ~strcmp(file,'');
consttype = ~isnan(azim) && ~isnan(ele);

assert(xor(filetype,consttype),'XMLReader:getSteering','multiple definition exists, only one: file= or azimuth= elevation= can exists');

if(filetype)
    sStruct.type = 'file';
    sStruct.file = file;
else
    sStruct.type = 'const';
    sStruct.azimuth = azim;
    sStruct.elevation = ele;
end
end

%%
% SOURCES
%

function sourcesConfig = getSourcesStructure(node)

SNode = node.getElementsByTagName('sources');
assert(SNode.getLength == 1,'XMLReader:getSourcesStructure','Only 1 "sources" definition allowed');

celSourcesNode = SNode.item(0).getElementsByTagName('celestial');
grndSourcesNode = SNode.item(0).getElementsByTagName('ground');
satSourcesNode = SNode.item(0).getElementsByTagName('sat');

nCel = celSourcesNode.getLength;
nGrd = grndSourcesNode.getLength;
nSat = satSourcesNode.getLength;
nTot = nCel + nGrd + nSat;

assert(nTot > 0,'XMLReader:getSourcesStructure', 'At least 1 source must be defined');

sourcesConfig = cell(nTot,1);
iT = 1;
for iK = 1:nCel
    sourcesConfig{iT} = getCelestialSource(celSourcesNode.item(iK-1));
    iT = iT + 1;
end

for iK = 1:nGrd
    sourcesConfig{iT} = getGroundSource(grndSourcesNode.item(iK-1));
    iT = iT + 1;
end

for iK = 1:nSat
    sourcesConfig{iT} = getSatSource(satSourcesNode.item(iK-1));
    iT = iT + 1;
end

end

function cSource = getCelestialSource(node)
cSource.type = 'celestialSource';
cSource.name = string(node.getAttribute('name').toCharArray().');

fnode = node.getElementsByTagName('ephFile');
assert(fnode.getLength() == 1,'XMLReader:getCelestialSource','ephFile not found');
cSource.file = string(fnode.item(0).getTextContent().toCharArray().').char;
pnode = node.getElementsByTagName('powLevel');
assert(pnode.getLength() == 1,'XMLReader:getCelestialSource','powLevel not found');
numVal = str2double(pnode.item(0).getTextContent());
assert(~isnan(numVal),'XMLReader:getCelestialSource','powLevel is NaN');
cSource.powLevel = numVal;
snode = node.getElementsByTagName('signal');
assert(snode.getLength() == 1,'XMLReader:getCelestialSource','signal not found');
cSource.signal = getSignal(snode);
end

function cSource = getGroundSource(node)
cSource.type = 'groundSource';
cSource.name = string(node.getAttribute('name').toCharArray().');

pnode = node.getElementsByTagName('powerdbw');
assert(pnode.getLength() == 1,'XMLReader:getGroundSource','power (dBW) not found');
numVal = str2double(pnode.item(0).getTextContent());
assert(~isnan(numVal),'XMLReader:getGroundSource','power is NaN');
cSource.powerdBW = numVal;

posnode = node.getElementsByTagName('position');
assert(posnode.getLength() == 1,'XMLReader:getGroundSource','position not found');
numVal = str2double(posnode.item(0).getAttribute('x'));
assert(~isnan(numVal),'XMLReader:getGroundSource','position/x is NaN');
cSource.pos.x = numVal;
numVal = str2double(posnode.item(0).getAttribute('y'));
assert(~isnan(numVal),'XMLReader:getGroundSource','position/y is NaN');
cSource.pos.y = numVal;
numVal = str2double(posnode.item(0).getAttribute('z'));
assert(~isnan(numVal),'XMLReader:getGroundSource','position/z is NaN');
cSource.pos.z = numVal;

headnode = node.getElementsByTagName('beamSteering');
assert(headnode.getLength() == 1,'XMLReader:getGroundSource','beamHeading not found');
cSource.beamSteering = getSteering(headnode);

beamN = node.getElementsByTagName('beam');
assert(beamN.getLength == 1,'XMLReader:getGroundSource','Only 1 "beam" definition allowed');
cSource.beam = getBeam(beamN);

snode = node.getElementsByTagName('signal');
assert(snode.getLength() == 1,'XMLReader:getGroundSource','signal not found');
cSource.signal = getSignal(snode);
end

function cSource = getSatSource(node)
cSource.type = 'satSource';
cSource.name = string(node.getAttribute('name').toCharArray().');

fnode = node.getElementsByTagName('ephFile');
assert(fnode.getLength() == 1,'XMLReader:getSatSource','ephFile not found');
cSource.file = string(fnode.item(0).getTextContent().toCharArray().').char;

pnode = node.getElementsByTagName('power');
assert(pnode.getLength() == 1,'XMLReader:getSatSource','power not found');
numVal = str2double(pnode.item(0).getTextContent());
assert(~isnan(numVal),'XMLReader:getSatSource','power is NaN');
cSource.power = numVal;

headnode = node.getElementsByTagName('beamSteering');
assert(headnode.getLength() == 1,'XMLReader:getSatSource','beamHeading not found');
cSource.beamSteering = getSteering(headnode);

beamN = node.getElementsByTagName('beam');
assert(beamN.getLength == 1,'XMLReader:getGroundSource','Only 1 "beam" definition allowed');
cSource.beam = getBeam(beamN);

snode = node.getElementsByTagName('signal');
assert(snode.getLength() == 1,'XMLReader:getGroundSource','signal not found');
cSource.signal = getSignal(snode);
end

function sSignal = getSignal(node)
type = string(node.item(0).getAttribute('type').toCharArray().');

switch lower(type)
    case 'bandnoise'
        sSignal = getBandNoiseSignal(node);
    case 'sin'
        sSignal = getHarmonicSignal(node);
    case 'chirp'
        sSignal = getChirpSignal(node);
    case 'qam'
        sSignal = getQAMSignal(node);
    case 'ofdm_qam'
        sSignal = getOFDMQAMSignal(node);
    case 'pulsar'
        sSignal = getPulsarSignal(node);
    case 'file'
        sSignal = getFileSignal(node);
    otherwise
        error('XMLReader:getSignal','type not supported (%s)',type);
end
end

function sSignal = getBandNoiseSignal(node)
sSignal.type = 'bandnoise';
passnode = node.item(0).getElementsByTagName('passband');
PL = passnode.getLength();
%TODO: is that assertion correct? or 1 stop and 1 passnode?
assert(PL > 0,'XMLReader:getBandNoiseSignal','at least one pass or one stopnode must be present');

%value is optional, but if it exist, it must be a number
JString = node.item(0).getAttribute('specResolution');
if(JString.isEmpty() )
    sSignal.freqSpacing = [];
else
    numVal = str2double(JString);
    assert(~isnan(numVal),'XMLReader:getBandNoiseSignal','specResolution is NaN');
    sSignal.freqSpacing = numVal;
end

%value is optional, but if it exist, it must be a number
JString = node.item(0).getAttribute('filterOrder');
if(JString.isEmpty() )
    sSignal.filterOrder = [];
else
    numVal = str2double(JString);
    assert(~isnan(numVal),'XMLReader:getBandNoiseSignal','filterOrder is NaN');
    sSignal.filterOrder = numVal;
end

sSignal.passCell = cell(PL,1);

for iK = 1:PL
    cCell = struct('relPower',[],'startFreq',[],'stopFreq',[]);
    numVal = str2double(passnode.item(iK-1).getAttribute('relPower'));
    assert(~isnan(numVal),'XMLReader:getBandNoiseSignal','relPower is NaN');
    cCell.relPower = numVal;
    numVal = str2double(passnode.item(iK-1).getAttribute('startFreq'));
    assert(~isnan(numVal),'XMLReader:getBandNoiseSignal','startFreq is NaN');
    cCell.startFreq = numVal;
    numVal = str2double(passnode.item(iK-1).getAttribute('stopFreq'));
    assert(~isnan(numVal),'XMLReader:getBandNoiseSignal','stopFreq is NaN');
    cCell.stopFreq = numVal;
    
    %fetching shapeinterp modifiers
    sinode = passnode.item(iK-1).getElementsByTagName('shapeinterp');
    NSI = sinode.getLength();
    cCell.shapeInterp = cell(NSI,1);
    for iL = 1:NSI
        cCell.shapeInterp{iL} = getNoiseShapeInterp(sinode.item(iL-1));
    end
    sSignal.passCell{iK} = cCell;
end

end

function sInterp = getNoiseShapeInterp(item)
type = string(item.getAttribute('type').toCharArray().');
sInterp.type = lower(type);
switch lower(type)
    case 'spline'
        freqstring = string(item.getAttribute('freq').toCharArray().');
        gainstring = string(item.getAttribute('normdb').toCharArray().');
        freqSarray = split(freqstring,';');
        gainSarray = split(gainstring,';');
        LA = length(freqSarray);
        assert(all(size(freqSarray) == size(gainSarray)),'XMLReader:getNoiseShapeInterp', 'spline definition dimension mismatch');
        sInterp.freq = zeros(LA,1);
        sInterp.gain = zeros(LA,1);
        for iL = 1:LA
            numVal = str2double(freqSarray(iL));
            assert(~isnan(numVal),'XMLReader:getNoiseShapeInterp','freq is NaN');
            sInterp.freq(iL) = numVal;
            numVal = str2double(gainSarray(iL));
            assert(~isnan(numVal),'XMLReader:getNoiseShapeInterp','gain is NaN');
            sInterp.gain(iL) = numVal;
        end
    case '1/f'
        %nothing here
    case '1/f2'
        %nothing here
    case 'gaussian'
        numVal = str2double(item.getAttribute('sigma'));
        assert(~isnan(numVal),'XMLReader:getNoiseShapeInterp','sigma is NaN');
        sInterp.sigma = numVal;
    case 'spectralindex'
        numVal = str2double(item.getAttribute('alpha'));
        assert(~isnan(numVal),'XMLReader:getNoiseShapeInterp','alpha is NaN');
        sInterp.alpha = numVal;
    case 'function'
        sInterp.funHandle = str2func(item.getAttribute('value').toCharArray().');
    otherwise
        error('XMLReader:getNoiseShapeInterp','type not supported (%s)',type);
end

end

function sSignal = getHarmonicSignal(node)
sSignal.type = 'sin';
harmnode = node.item(0).getElementsByTagName('harmonic');
HL = harmnode.getLength();
assert(HL > 0,'XMLReader:getHarmonicSignal','at least one harmonic entry must be defined');
sSignal.harmonics = cell(HL,1);
for iK = 1:HL
    cCell = struct('relPower',[],'freq',[]);
    numVal = str2double(harmnode.item(iK-1).getAttribute('relPower'));
    assert(~isnan(numVal),'XMLReader:getHarmonicSignal','relPower is NaN');
    cCell.relPower = numVal;
    numVal = str2double(harmnode.item(iK-1).getAttribute('freq'));
    assert(~isnan(numVal),'XMLReader:getHarmonicSignal','freq is NaN');
    cCell.freq = numVal;
    sSignal.harmonics{iK} = cCell;
end
end

function sSignal =  getChirpSignal(node)
sSignal.type = 'chirp';
linnode = node.item(0).getElementsByTagName('linear');
LL = linnode.getLength();
geomnode = node.item(0).getElementsByTagName('geometric');
GL = geomnode.getLength();
assert(LL + GL > 0,'XMLReader:getChirpSignal','at least one linear of geometric entry must be defined');
sSignal.linear = cell(LL,1);
sSignal.geometric = cell(GL,1);
for iK = 1:LL
    cCell = struct('relPower',[],'f0',[],'f1',[],'tRamp',[]);
    numVal = str2double(linnode.item(iK-1).getAttribute('relPower'));
    assert(~isnan(numVal),'XMLReader:getChirpSignal','relPower is NaN');
    cCell.relPower = numVal;
    numVal = str2double(linnode.item(iK-1).getAttribute('freq0'));
    assert(~isnan(numVal),'XMLReader:getChirpSignal','freq0 is NaN');
    cCell.f0 = numVal;
    numVal = str2double(linnode.item(iK-1).getAttribute('freq1'));
    assert(~isnan(numVal),'XMLReader:getChirpSignal','freq1 is NaN');
    cCell.f1 = numVal;
    numVal = str2double(linnode.item(iK-1).getAttribute('tRamp'));
    assert(~isnan(numVal),'XMLReader:getChirpSignal','tRamp is NaN');
    cCell.tRamp = numVal;
    sSignal.linear{iK} = cCell;
end

for iK = 1:GL
    cCell = struct('relPower',[],'f0',[],'f1',[],'tRamp',[]);
    numVal = str2double(geomnode.item(iK-1).getAttribute('relPower'));
    assert(~isnan(numVal),'XMLReader:getChirpSignal','relPower is NaN');
    cCell.relPower = numVal;
    numVal = str2double(geomnode.item(iK-1).getAttribute('freq0'));
    assert(~isnan(numVal),'XMLReader:getChirpSignal','freq0 is NaN');
    cCell.f0 = numVal;
    numVal = str2double(geomnode.item(iK-1).getAttribute('freq1'));
    assert(~isnan(numVal),'XMLReader:getChirpSignal','freq1 is NaN');
    cCell.f1 = numVal;
    numVal = str2double(geomnode.item(iK-1).getAttribute('tRamp'));
    assert(~isnan(numVal),'XMLReader:getChirpSignal','tRamp is NaN');
    cCell.tRamp = numVal;
    sSignal.geometric{iK} = cCell;
end

end

function sSignal = getQAMSignal(node)
sSignal.type = 'qam';
numVal = str2double(node.item(0).getAttribute('bit_per_symbol'));
assert(~isnan(numVal),'XMLReader:getQAMSignal','bitpersymbol is NaN');
sSignal.bitpersymbol = numVal;
numVal = str2double(node.item(0).getAttribute('tsymbol'));
assert(~isnan(numVal),'XMLReader:getQAMSignal','tsymbol is NaN');
sSignal.tsymbol = numVal;
numVal = str2double(node.item(0).getAttribute('freq'));
assert(~isnan(numVal),'XMLReader:getQAMSignal','freq is NaN');
sSignal.freq = numVal;
end

function sSignal = getOFDMQAMSignal(node)
sSignal.type = 'ofdm_qam';
numVal = str2double(node.item(0).getAttribute('bit_per_symbol'));
assert(~isnan(numVal),'XMLReader:getOFDMQAMSignal','bitpersymbol is NaN');
sSignal.bitpersymbol = numVal;
numVal = str2double(node.item(0).getAttribute('tsymbol'));
assert(~isnan(numVal),'XMLReader:getOFDMQAMSignal','tsymbol is NaN');
sSignal.tsymbol = numVal;
numVal = str2double(node.item(0).getAttribute('freq'));
assert(~isnan(numVal),'XMLReader:getOFDMQAMSignal','freq is NaN');
sSignal.freq = numVal;
numVal = str2double(node.item(0).getAttribute('channels'));
assert(~isnan(numVal),'XMLReader:getOFDMQAMSignal','channels is NaN');
sSignal.channels = numVal;
numVal = str2num(node.item(0).getAttribute('guard'));
assert(~isnan(numVal) && length(numVal) == 1,'XMLReader:getOFDMQAMSignal','guard is NaN');
sSignal.guard = numVal;
end

function sSignal =  getFileSignal(node)

JString = node.item(0).getAttribute('filename');
assert(~JString.isEmpty(),'XMLReader:getFileSignal','no filename given');

sSignal.filename = numVal;

end

function sSignal =  getPulsarSignal(node)
sSignal.type = 'pulsar';
error('XMLReader:getPulsarSignal','Pulsar signal XML reader not implemented');
end

function nodeOut = getElementsByTagNameOneLevel(node,name)
    nodeOut = node.cloneNode(1);
    fc = nodeOut.getFirstChild;
    while ~isempty(fc)
        nc = fc.getNextSibling();
        if(~strcmp(fc.getNodeName,name))
            nodeOut.removeChild(fc);
        end
        fc = nc;
    end
end