function taitime = UTC2TAI(utctime)
%UTC2TAI converts UTC to TAI time
%taitime = UTC2TAI(utctime) recalculates the UTC time from TAI time.
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

if utctime > dec2016update
    taitime = utctime + 37;
elseif utctime > jun2015update
    taitime = utctime + 36;
elseif utctime  > jun2012update
    taitime = utctime + 35;
elseif utctime > dec2008update
    taitime = utctime + 34;
elseif utctime > dec2005update
    taitime = utctime + 33;
else
    taitime = utctime + 32;
    warning('ATATools:Misc:UTC2TAI','date before 31-dec-2005 midnight. Results may be inaccurate!');
end