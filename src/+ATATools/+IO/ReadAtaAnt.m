function bf = ReadAtaAnt(bf, fn, doDisp)
% ReadAtaAnt reads the antenna position file
% bf = ReadAtaAnt(bf, fn, doDisp) Reads the ATA.ant file given by a
% specified file name and imports the antenna positions into the state
% variable for the beamformer system.
%
% Rev: 6/26/07, jk: 3/14/2018
% Billy Barott @ HCRO, JKulpa
%bf: The beamformer variable (or [])
%fn: the full path and file name to the ata.ant formatted file
%doDisp: flag to display the progress

if nargin < 3
    doDisp = 0;
end

%warning('ATATools:IO:ReadAtaAnt','use ATATools:IO:antposread if possible')
ant = fopen(fn, 'r');


b = 0;
antlist = [];
while b ~= -1
    b = fgetl(ant);
    if b ~= -1
        if b(1) ~= '#'
            if(doDisp)
                disp(b)
            end
            N = sscanf(b(1:11), '%f');
            E = sscanf(b(12:21), '%f');
            H = sscanf(b(22:30), '%f');
            id =sscanf(b(33:36), '%s');
            mir = sscanf(b(38:42),'%f');
            antlist(length(antlist)+1).N = N;
            antlist(length(antlist)).E = E;
            antlist(length(antlist)).H = H;
            antlist(length(antlist)).id = id;
            antlist(length(antlist)).mir = mir;
        end
    end
end


if nargin==0
    bf=[];
end
%Convert the antenna positions to X,Y,Z with respect to the origin.
%The primary axes are X = north, Y = west, Z = up.
for inc = 1:(length(antlist))
    xx = antlist(inc).N;
    yy = -antlist(inc).E;
    zz = antlist(inc).H;
    mir = antlist(inc).mir;
    bf=[bf; mir, xx, yy, zz];
end

if(doDisp)
    disp('done')
end
