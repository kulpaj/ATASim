function matrix = ReadAtaEphem(filename)
%ReadAtaEphem reads ephem data to a matrix

% Setting up
fid = fopen(filename);
assert(fid ~= -1,'ATATools:IO:ReadAtaEphem','file open error (%s)',filename);
ephem_str = struct('taitime',[],'utctime',[],'az',[],'el',[],'invRange',[]);

% Read data and turn AZ/EL into ENU
iK = 1; % Line counter
while ~feof(fid)
    linedata = sscanf(fgetl(fid),'%f');
    ephem_str.az(iK) = linedata(2);
    ephem_str.el(iK) = linedata(3);
    taitime = linedata(1) * 1e-9;
    
    ephem_str.utctime(iK) = ATATools.Misc.TAI2UTC(taitime);
    ephem_str.taitime(iK) = taitime;
    ephem_str.invRange(iK) = linedata(4);
    
    iK = iK+1;
end
fclose(fid);

matrix = zeros(iK-1,5);
matrix(:,1) = ephem_str.taitime;
matrix(:,2) = ephem_str.utctime;
matrix(:,3) = ephem_str.az;
matrix(:,4) = ephem_str.el;
matrix(:,5) = ephem_str.invRange;
end

