function writeSignal( obj, nOfZeros )
%writeSignal saves the RecieverRecorder signal to the file
%   Detailed explanation goes here

if(nOfZeros)
    switch(obj.bps_)
        case 8
            localZero = int8(zeros(nOfZeros,1));
            fwrite(obj.fd_,localZero,'int8'); %real
            fwrite(obj.fd_,localZero,'int8'); %imag
        case 16
            localZero = int16(zeros(nOfZeros,1));
            fwrite(obj.fd_,localZero,'int16'); %real
            fwrite(obj.fd_,localZero,'int16'); %imag
        case 32
            localZero = int32(zeros(nOfZeros,1));
            fwrite(obj.fd_,localZero,'int32'); %real
            fwrite(obj.fd_,localZero,'int32'); %imag
        otherwise
            error('ReceiverRecorder:writeSignal','unknown bit rate %d',obj.bps_);
    end
end

if(~isfinite(obj.saveGain_))
    %gain not set, we need to set it up in the header
    maxAbsVal = (2^(obj.bps_-1) - 1)/obj.firstBatchGainMargin_;
    %we will compute max(abs(complex_number)) because we assume that the
    %signal phase may be different and we do not want it to influcence the
    %firstBathGainMargin_ value.
    maxVal = max(abs(obj.dataVect_));
    obj.saveGain_ = maxAbsVal/maxVal;
    
    %and now saving this value to the header
    cPos = ftell(obj.fd_);
    fseek(obj.fd_,4+2+2+8+8+8,'bof');
    fwrite(obj.fd_, obj.saveGain_, 'float64', 0, 'ieee-le');
    fseek(obj.fd_,cPos,'bof'); %we could probably do (obj.fd_,0,'eof')
end

%we may add indicator of overflow(saturation) if needed

switch(obj.bps_)
    case 8
        dataToSave = int8(zeros(2*obj.dataVectSize_,1));
        dataToSave(1:2:end) = int8(real(obj.dataVect_)*obj.saveGain_);
        dataToSave(2:2:end) = int8(imag(obj.dataVect_)*obj.saveGain_);
        fwrite(obj.fd_, dataToSave, 'int8', 0, 'ieee-le');
    case 16
        dataToSave = int16(zeros(2*obj.dataVectSize_,1));
        dataToSave(1:2:end) = int16(real(obj.dataVect_)*obj.saveGain_);
        dataToSave(2:2:end) = int16(imag(obj.dataVect_)*obj.saveGain_);
        fwrite(obj.fd_, dataToSave, 'int16', 0, 'ieee-le');
    case 32
        dataToSave = int32(zeros(2*obj.dataVectSize_,1));
        dataToSave(1:2:end) = int32(real(obj.dataVect_)*obj.saveGain_);
        dataToSave(2:2:end) = int32(imag(obj.dataVect_)*obj.saveGain_);
        fwrite(obj.fd_, dataToSave, 'int32', 0, 'ieee-le');
    otherwise
        error('ReceiverRecorder:writeSignal','unknown bit rate %d',obj.bps_);
end

end

