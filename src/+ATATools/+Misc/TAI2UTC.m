function utctime = TAI2UTC(taitime)
%TAI2UTC converts TAI to UTC time
%utctime = TAI2UTC(taitime) recalculates the UTC time from TAI time.
%
%WARNING, may be inaccurate if vector is used with different leap-second
%time stamps. In such condition correction will be done based on the
%earliest timestamp!

%WARNING: all datenum should be substituted with numbers to shorten computation!

%e = datenum('01-jan-1970 00:00:00');

%x = datenum('31-dec-2016 23:59:59');
%dec2016update = (x-e)*86400;
dec2016update = 1483228798;

%x = datenum('30-jun-2015 23:59:59');
%jun2015update = (x-e)*86400;
jun2015update = 1435708798;

%x = datenum('30-jun-2012 23:59:59');
%jun2012update = (x-e)*86400;
jun2012update = 1341100798;

%x = datenum('31-dec-2008 23:59:59');
%dec2008update = (x-e)*86400;
dec2008update = 1230767998;

%x = datenum('31-dec-2005 23:59:59');
%dec2005update = (x-e)*86400;
dec2005update = 1136073598;

if taitime - 37 > dec2016update
    utctime = taitime - 37;
elseif taitime - 36 > jun2015update
    utctime = taitime - 36;
elseif taitime - 35 > jun2012update
    utctime = taitime - 35;
elseif taitime - 34 > dec2008update
    utctime = taitime - 34;
elseif taitime - 33 > dec2005update
    utctime = taitime - 33;
else
    utctime = taitime - 32;
    warning('ATATools:Misc:TAI2UTC','date before 31-dec-2005 midnight. Results may be inaccurate!');
end