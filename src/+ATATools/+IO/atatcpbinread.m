%atatcpbinread reads the data from ATA file
%========================================================================
% Author: William C. Barott
% Revised: February 5, 2009
%         February 6, 2009: Added "floor" to line 205 (hbw) - old ruby
%            script used integer math and automatically rounded.
%         March 9, 2009: Added updates to support atatcptswrite
%         Sept 22, 2010: Added new header format
%         May 2018: Added 16 and 32 bit mode
%
% Written for reading tcp dump files of the standard form 2008-11-11
% Just like atatcpread, but for the binary formatted files.
%========================================================================
% Syntax: dataholder = atatcpbinread(datasource, numrows, startrow, ifftmask)
% datasource: Either a file name (to open a fresh bin file) or a struct of
%      the type returned by a previous call to this function.
% numrows: The maximum number of frames to read.  There are 51200 frames per
%      second of recorded data when the default packet length is used.
% startrow: The number of frames to offset the read from the default row.
%      Successive reads from a struct datasource automatically increment
%      the file pointer, so there is no need to use other than zero unless
%      you want to skip data.
% ifftmask: The inversion mask to apply to the data.  The length of
%      ifftmask determines the number of interleaved streams, and the value
%      0 leaves data raw while the value 1 inverts to a time-domain stream.
%      The default argument is [1 1 1 1].

function dataholder = atatcpbinread(fn, maxrows, startrow, ifftmask)

    if nargin <= 1
        % Maxrows determines the number of frames to read (not the number
        % of samples).  A frame is defined by LDAT 64-bit samples, where
        % LDAT is (usually) the number of enabled fft bins, and is included
        % in the file header.  That makes a single frame 2048/10485760
        % seconds long regardless of the number of samples.
        maxrows = inf;
    end
    if nargin <=2
        % Start row determines the frame at which to start reading,
        % relative to: (a) the first frame, when a filename is included for
        % the argument fn, or (b) the current frame, when a properly-formed
        % struct is included for the argument fn.  Thus, it is not required
        % to increment startrow for successive reads of the same object
        % (because, when passing the object handle, the file pointer
        % increases automatically).  This handles frames in the same 64-bit
        % LDAT method described above.
        startrow = 0;
    end
    if nargin <=3
        % ifftmask determines the deinterlacing behavior and initial
        % reconstruction: Every 16-bits (two bytes) is treated as one
        % complex sample in the file.  The length of ifftmask determines
        % the number of interleaved streams formed by the samples (for
        % example, consecutive bytes would be r1,i1,r2,i2,r3,i3,r1,i1...
        % for three interlaced streams).  The value of ifft mask determines
        % whether a particular stream is processed to be inverted to
        % time-domain data, or whether it is left as frequency-domain data.
        % (1 to invert, 0 to leave raw).  It is useful to leave a stream
        % raw if it contains meta data rather than antenna sample data.
        ifftmask = [1,1,1,1];
    end

    if isa(fn,'struct')
        % If fn is passed as a structure then we're given a data struct and
        % not a string (filename).  So we look for the file handle in the
        % properly-formed structure and do not read header info.  The
        % handle to this file will already point "somewhere" within the
        % file.
        xf = fn.fh;
        readheader = 0;
    else
        % We should be passed a string in the variable fn.  The string
        % should contain a vaild file name.  First we'll append a working
        % directory (useful if you store your data in a central location
        % and don't want to type it every time!). We test if the file exist
        % in current, relative directory tree 
        
        % The directory below is a default working directory
        %if fn(2) ~= ':'
        if(~exist(fn,'file'))
            fn = sprintf('d:\\ATA Data\\%s%s',fn);
        end
        disp('ATATCPREAD: Opening the following data file:')
        disp(fn)
        [xf, msg] = fopen(fn,'r','ieee-le');
        assert(xf > -1,'ATATools:atatcpbinread','ERROR while opening the file: %s',msg);
        readheader = 1; % Read the header, this is a freshly opened file.
    end

    if readheader == 1
        fseek(xf,0,-1);
        % Old header code
        %hdr_sn = fread(xf,1,'ulong',0,'ieee-le');
        %hdr_ldat = fread(xf,1,'ulong',0,'ieee-le');
        %hdr_fcenter = fread(xf,1,'double',0,'ieee-le');
        %hdr_fsky = fread(xf,1,'double',0,'ieee-le');
        %hdr_fbw = fread(xf,1,'double',0,'ieee-le');
        %hdr_gain = fread(xf,1,'double',0,'ieee-le');
        %hdr_version = fread(xf,1,'ulong',0,'ieee-le');
        %ntph = fread(xf,1,'ulong',0,'ieee-le');
        %ntpl = fread(xf,1,'ulong',0,'ieee-le');
        %hdr_timestamp = ntph + ntpl / 2^32;
        %hdr_savestreams = fread(xf,1,'ulong',0,'ieee-le');
        %hdr_procflags = fread(xf,1,'ulong',0,'ieee-le');
        %hdr_reserved = fread(xf,3,'ulong',0,'ieee-le');
        
        % New header code: This ought to be backward compatible with
        % older headers, because of the position of the bits in
        % rearrangement.
        hdr_sn = fread(xf,1,'uint32',0,'ieee-le');
        hdr_ldat = fread(xf,1,'uint16',0,'ieee-le');
        hdr_nbins = fread(xf,1,'uint16',0,'ieee-le');   %NEW
        hdr_fcenter = fread(xf,1,'float64',0,'ieee-le');
        hdr_fsky = fread(xf,1,'float64',0,'ieee-le');
        hdr_fbw = fread(xf,1,'float64',0,'ieee-le');
        hdr_gain = fread(xf,1,'float64',0,'ieee-le');
        hdr_version = fread(xf,1,'uint8',0,'ieee-le');
        hdr_bps = fread(xf, 1, 'uint8',0,'ieee-le');    % NEW
        hdr_pktype = fread(xf, 1, 'uint8',0,'ieee-le'); % NEW
        hdr_hdrlen = fread(xf, 1, 'uint8',0,'ieee-le'); % NEW
        ntph = fread(xf,1,'uint32',0,'ieee-le');
        ntpl = fread(xf,1,'uint32',0,'ieee-le');
        hdr_timestamp = ntph + ntpl / 2^32;
        hdr_savestreams = fread(xf,1,'uint8',0,'ieee-le');
        hdr_polflags = fread(xf,1,'uint8',0,'ieee-le'); % NEW
        hdr_totalchans = fread(xf,1,'uint16',0,'ieee-le');  %NEW
        hdr_procflags = fread(xf,1,'uint32',0,'ieee-le');
        hdr_ds0 = fread(xf, 1, 'uint16',0,'ieee-le');   %NEW
        hdr_ds1 = fread(xf, 1, 'uint16',0,'ieee-le');   %NEW
        hdr_ds2 = fread(xf, 1, 'uint16',0,'ieee-le');   %NEW
        hdr_ds3 = fread(xf, 1, 'uint16',0,'ieee-le');   %NEW
        hdr_reserved = fread(xf,1,'uint32',0,'ieee-le');
        
        expected_hdr_pktype = (0*2^0 + 1*2^1 + 0*2^2);
        %assert(hdr_pktype == expected_hdr_pktype,'ATATools:atatcpbinread','wrong packet type, got %d, expecting %d',hdr_pktype,expected_hdr_pktype);
        warning('ATATools:atatcpbinread','Assertion turned off, check it')
        
        % Now sort through the "processed flags" to determine what we
        % should do and what we shouldn't do:
        % Produce a string array that goes '[lsb][lsb+1]...[msb-1][msb]'
        pf_bin = fliplr(dec2bin(hdr_procflags+2^32)); % Pad to make sure there are enough zeros
        pf_correct_freq = eval(pf_bin(6));  % Bit 2^5 -> entry 6
        
        dh.sn = hdr_sn;
        dh.ldat = hdr_ldat;
        dh.freq = hdr_fcenter;  %Commanded center, not necessarily actual
        dh.bps = hdr_bps;
        
        if ~pf_correct_freq
            % If we've not received a flag that frequencies are correctly
            % valued, then we should calculate them based on the bin select
            % algorithm.  
            [c_f0,c_fmax]=calc_bin_frange(hdr_fsky, hdr_fcenter, hdr_fbw);
        else
            % We've received a flag that frequencies are correct, so we
            % should *not* recalculate them based on the bin select.
            c_f0 = hdr_fcenter - hdr_fbw / 2;
            c_fmax = hdr_fcenter + hdr_fbw / 2;
        end

           
        dh.flow = c_f0;     %hdr_fcenter - hdr_fbw / 2;
        dh.fhigh = c_fmax;  %hdr_fcenter + hdr_fbw / 2;
        dh.fsky = hdr_fsky;     % Actual fsky tuning for DC
        dh.bw = hdr_fbw;        % Commanded bandwidth, not necessarily actual
        dh.tstart = hdr_timestamp; % Timestamp of the start of the data stream
        dh.tstarts = ntph; % Raw seconds
        dh.tstartns = ntpl * 1e9/2^32; % Nanoseconds, fractional part for better accuracy 
        dh.binver = hdr_version;
        dh.fps = 51200;      % Frames per second
        hdr_end = ftell(xf);
        dh.hdrbytes = hdr_end;
        assert(hdr_hdrlen == hdr_end,'ATATools:atatcpbinread','header length mismatch');
        dh.streams = hdr_savestreams;
        if dh.streams == 0
            disp('Warning: 0 passed for streams, likely 4');
            dh.streams = 4;
            hdr_savestreams = 4;
        end
        dh.framebytes = 2*hdr_savestreams*dh.ldat*dh.bps/8;  % Bytes per frame
        dh.procflags = hdr_procflags;
        dh.gain=hdr_gain;
        
        % Add new flags
        dh.nbins = hdr_nbins;
        dh.totbins = hdr_totalchans;
        dh.ds = [hdr_ds0, hdr_ds1, hdr_ds2, hdr_ds3];
        pol_bin = fliplr(dec2bin(hdr_polflags+2^32));
        pol0 = bin2dec(fliplr(pol_bin(1:2)));
        pol1 = bin2dec(fliplr(pol_bin(3:4)));
        pol2 = bin2dec(fliplr(pol_bin(5:6)));
        pol3 = bin2dec(fliplr(pol_bin(7:8)));
        dh.pol = [pol0, pol1, pol2, pol3];
        
        %TODO:FIXME: assert hdr_bps,hdr_pktype,hdr_hdrlen,hdr_version!
    else
        dh.sn = fn.sn;
        dh.ldat = fn.ldat;
        dh.freq = fn.freq;
        dh.bps = fn.bps;
        dh.flow = fn.flow;
        dh.fhigh = fn.fhigh;
        dh.fsky = fn.fsky;
        dh.bw = fn.bw;
        dh.tstart = fn.tstart;
        dh.tstarts = fn.tstarts;
        dh.tstartns = fn.tstartns;
        dh.binver = fn.binver;
        dh.framebytes = fn.framebytes;
        dh.fps = 51200;
        dh.hdrbytes = fn.hdrbytes;
        dh.streams = fn.streams;
        dh.procflags = fn.procflags;
        dh.gain = fn.gain;
        dh.nbins = fn.nbins;
        dh.totbins = fn.totbins;
        dh.ds = fn.ds;
        dh.pol = fn.pol;        
    end

    % Seek to the start row position relative to the start of data
    % Right now we're at the start of data since we read the headers
    xer = fseek(xf, (startrow*2*dh.streams)*dh.ldat*dh.bps/8, 0);
    if xer == -1
        ferror(xf)
        dh = -1;
        dataholder = dh;
        return
    end

    nstreams = dh.streams;
    if length(ifftmask) ~= nstreams
        %disp('Error! IFFT MASK not the same as nstreams preset!')
        ifftmask = ifftmask(1:nstreams);
    end
    % Perform the read
    fpos_1 = ftell(xf);
    switch dh.bps
        case 8 
            bof_data = fread(xf,maxrows*2*nstreams*dh.ldat,'int8');
        case 16
            bof_data = fread(xf,maxrows*2*nstreams*dh.ldat,'int16');
        case 32
            bof_data = fread(xf,maxrows*2*nstreams*dh.ldat,'int32');
        otherwise
            error('ATATools:atatcpbinread','unsuported bps value (%d)',dh.bps)
    end
    fpos_2 = ftell(xf);
    
    % Concatenate successive real and imaginary samples into complex
    % numbers.
    xvreal = bof_data(1:2:(length(bof_data)));
    xvimag = bof_data(2:2:(length(bof_data)));
    xval = xvreal + 1i*xvimag;

    % Now compute time series to go with this read:
    framestart = ((fpos_1 - dh.hdrbytes) / dh.framebytes);
    framestop = ((fpos_2 - dh.hdrbytes) / dh.framebytes);
    toffsetstart = framestart / dh.fps;
    toffsetstop = framestop / dh.fps;
    
    if framestart ~= framestop
        tsamplesrel = linspace(toffsetstart, toffsetstop, (framestop-framestart)*dh.ldat);
        tsamples = tsamplesrel + dh.tstart;
        tframes = linspace(dh.tstart + toffsetstart, dh.tstart + toffsetstop, (framestop-framestart));
        
        
        % Add the time values:
        dh.tsamp = tsamples;
        dh.tsamprel = tsamplesrel;
        dh.tframe = tframes;
        
    elseif maxrows ~= 0
        % Trap EOF another way - the file pointer didn't move
        dh = -1;
        dataholder = dh;
        return
    else
        dh.tsamp = zeros(1,0);
        dh.tsamprel = zeros(1,0);
        dh.tframe = zeros(1,0);
    end
    
    % Sort through the binary processed flags to come up with a "new" ifft
    % mask.  Data that are requested to be ifft'd but have not been ifft'd
    % will be ifft'd.  Data that were ifft'd but are requested *not* will
    % have an error.  Data that is in the same state as requested will be
    % left as is.
    pf_bin = fliplr(dec2bin(dh.procflags+2^32));
    pf_ifft_0 = eval(pf_bin(1));  % Bit 2^0 -> entry 1
    pf_ifft_1 = eval(pf_bin(2));  % Bit 2^1 -> entry 2
    pf_ifft_2 = eval(pf_bin(3));  % Bit 2^3 -> entry 3
    pf_ifft_3 = eval(pf_bin(4));  % Bit 2^4 -> entry 4
    pf_ifft = [pf_ifft_0, pf_ifft_1, pf_ifft_2, pf_ifft_3];
        

    for inc = 1:nstreams
        dcur = xval(inc:nstreams:length(xval));  % Pull out a stream
        if (ifftmask(inc) == 1) && (pf_ifft(inc) == 0)
            % If we're asked to IFFT this stream:
            dcur = bofifft(dcur, dh.ldat);
        elseif (ifftmask(inc) == 0) && (pf_ifft(inc) == 1)
            fprintf('Potential error! Channel %d requested to be delivered raw, but is saved ifftd',inc)
        end            
        dh.data(inc,:) = dcur.';
    end


    
    
    %dh.data = xval;
    dataholder = dh;
    dataholder.fh = xf;
    %fclose(xf);

end
    
function timeseries = bofifft(data,ldat)
    % Accept spectral data and produce time series data
    % First, remove the bias:
    bias = 0.5375;  % Changed from 0.499 on 2009-10-14 based on empirical results.
    warning('atatcpbinread:bofifft','This bias is different that bias used in fpga/C code. Be warned')
    %bias=0.0;
    % Note the .*(data~=0) addition is intended to catch dropped packets
    data = data + bias * ones(size(data)) + bias*1j*ones(size(data)).*(data~=0);
    tdm = reshape(data, ldat, length(data)/ldat);
    id1 = fftshift(conj(tdm),1);
    id2 = ifft(id1,[],1);
    timeseries=reshape(id2,size(tdm,1)*size(tdm,2),1);
    
end
    
function [f0,fmax]=calc_bin_frange(fsky, fcenter, fbw)
    % Calculates the bins that are enabled during the observation based on the
    % center frequency and the bandwidth.  This is the same as the Ruby predict
    % code, since enabled bins are not stored in the meta data.

    nchans = 2048;
    fullbw = 104.8576;

    warning('ATATools:calc_bin_frange','hardcoded or unused values, please check it manually!')
    
    %=======================================================================
    % Calculate channel offsets for the mask
    %=======================================================================

    % Note below that the order of subtraction results in the desired conjugation -
    % ie, frequencies above the sky frequency map to negative baseband freqs.
    foffset = (fsky - fcenter) / fullbw;	% Divide the MHz difference by MHz bandwidth.
    if (foffset < -0.5) || (foffset > 0.5)
        disp('Error, offset frequency not within band - check sky and observing frequencies')
    end

    if foffset < 0
        foffset = foffset + 1;	% Map to positive only
    end
    chancenter = floor(foffset * nchans);
    bwchans = ceil(fbw / fullbw * nchans);	%Determine total number of bins
    hbw = floor((bwchans+1) / 2);	        % Determine half-bandwidth

    chan0 = chancenter - hbw;	% First channel is the center minus half bandwidth
    bw = 2*hbw;		% Total number of channels is twice the half bandwidth
    %below : unused. Copy form ruby code. 
    %ldat = bw;		% We'll force LDAT to equal bandwidth channels
    
    chanmax = chan0+bw-1;
    if (chan0 < 0) || ((chan0 + bw - 1) >= nchans)
        fprintf('Error detected, calculated %d first channel, %d maximum channel (out of range)\n',chan0,chanmax)
        exit
    end

    fprintf('Calculated %d first channel, %d maximum channel, %d total channels passed\n',chan0,chanmax,bw)
    % Now calculate the TRUE fhigh and flow based on the bins:
    % Mapping bin 0 will map fsky
    % Each increase maps 1/2048*bandwidth to flow
    % Mapping 2047 is the same as -1, mapping 1 is the same as mapping +1.
    f_bin = fullbw / nchans;
    if chan0 > (nchans/2)
        chan0 = chan0 - nchans;
    end
    if chanmax > (nchans/2)
        chanmax = chanmax - nchans;
    end
    delta_f0 = -(chan0*f_bin);
    delta_fmax = -((chanmax + 1)*f_bin);     % Minus because of conjugated spectra, +1 because we go to the edge
    f0 = fsky + delta_f0;
    fmax = fsky + delta_fmax;
    % mapping bin 2047 will map 

    if fmax < f0
        ft = fmax;
        fmax = f0;
        f0 = ft;
    end

    fprintf('Found a frequency range from %.2f to %.2f\n',f0,fmax)
end