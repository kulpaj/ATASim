function y = timeShift(x,shift)
%timeShift shifts the signal in time
%y = timeShift(x,shift) shifts signal x by shift samples

if abs(shift) < ATASim.Signals.SourceSignal.sampleShiftAcc_
    y = x;
    return
end

%TODO: this extension is done to eliminate a (circular) bias.
%Consider if this is important or not
xnew = [x;zeros(length(x),1)];

N = length(xnew);

%
%mod = linspace(-pi,pi-2*pi/N,N);
%X = fftshift(fft(xnew));
%Y = X.*exp(1j*mod.'*shift);
%ynew = ifft(fftshift(Y));

mod = fftshift(linspace(-pi,pi-2*pi/N,N));
X = fft(xnew);
Y = X.*exp(1j*mod.'*shift);
ynew = ifft(Y);

y = ynew(1:length(x));

end