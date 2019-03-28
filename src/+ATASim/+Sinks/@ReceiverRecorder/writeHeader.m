function writeHeader(obj)

packetSerialNumber = 0; %is that right?
hdr_version = 2;
hdr_bps = obj.bps_;    % Hard code, this is writing 32-bit data
hdr_hdrlen = 72;    % Hard code, this routine writes 72-bit headers
hdr_pktype = 0*2^0 + 1*2^1 + 0*2^2; % Packets described are time-domain, complex, integers

fLow = (obj.fc_ - obj.fs_/2)/1e6;
fSkyInt = obj.framePerSec_/1e6; %in MHz,  FSKY is some multiple of 51.2 kHz (the frame rate) below the lowest frequency of the data, which force us to be operating in the upper sideband. 
fSky = floor(fLow/fSkyInt)*fSkyInt;

nBins = obj.dataVectSize_/obj.framePerRecording_;

assert(rem(nBins,1) == 0,'RecieverRecorder:writeHeader','non integer frames per recording! (%f)',nBins);

fwrite(obj.fd_, packetSerialNumber, 'uint32',0,'ieee-le');
fwrite(obj.fd_, nBins, 'uint16', 0, 'ieee-le');
fwrite(obj.fd_, nBins, 'uint16', 0, 'ieee-le');
fwrite(obj.fd_, obj.fc_/1e6, 'float64', 0, 'ieee-le');
fwrite(obj.fd_, fSky, 'float64', 0, 'ieee-le');
fwrite(obj.fd_, obj.fs_/1e6, 'float64', 0, 'ieee-le');
fwrite(obj.fd_, obj.saveGain_, 'float64', 0, 'ieee-le'); %-inf, should be updated after first write!
fwrite(obj.fd_, hdr_version, 'uint8', 0, 'ieee-le');
fwrite(obj.fd_, hdr_bps, 'uint8', 0, 'ieee-le');
fwrite(obj.fd_, hdr_pktype, 'uint8', 0, 'ieee-le');
fwrite(obj.fd_, hdr_hdrlen, 'uint8', 0, 'ieee-le');

% Determine ntp values:
% High bits are the integer part only

ntph = ATATools.Misc.TAI2UTC(obj.currTime_.getSec());  % Start time, seconds
% Low bits are the decimal part, times 2^32
ntpl = floor(obj.currTime_.getNs() * 2^32/1.0e9);  % Start time, nanoseconds
nStreams = 1;

fwrite(obj.fd_, ntph, 'uint32', 0, 'ieee-le');
fwrite(obj.fd_, ntpl, 'uint32', 0, 'ieee-le');
fwrite(obj.fd_, nStreams, 'uint8',0,'ieee-le');

hdr_pol = obj.polarization_;

fwrite(obj.fd_, hdr_pol, 'uint8', 0, 'ieee-le');
fwrite(obj.fd_, obj.frameBytes_, 'uint16', 0, 'ieee-le');

hdr_procflags=repmat('0',1,32);
hdr_procflags(6) = '1'; %correct frequencies, 
hdr_procflags(1) = '1'; %ifft data stored for chan1 (time samples)
hdr_procflags_dec = bin2dec(fliplr(hdr_procflags));
fwrite(obj.fd_, hdr_procflags_dec, 'uint32', 0, 'ieee-le');

units_0=0; %only one stream per file, miriad number here
fwrite(obj.fd_, obj.id_,'uint16',0,'ieee-le');
fwrite(obj.fd_, units_0,'uint16',0,'ieee-le');
fwrite(obj.fd_, units_0,'uint16',0,'ieee-le');
fwrite(obj.fd_, units_0,'uint16',0,'ieee-le');

hdr_reserved = 0;
fwrite(obj.fd_, hdr_reserved,'uint32',0,'ieee-le');

assert(ftell(obj.fd_) == hdr_hdrlen,'RecieverRecorder:writeHeader','header length mismatch');

end