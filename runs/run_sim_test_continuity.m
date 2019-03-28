close all
clearvars

delete SimResults\*bin

xmlFile = 'xml\simTestContinuityChirp.xml';
%xmlFile = 'xml\simTestContinuityQAM.xml';
%xmlFile = 'xml\simTestNoiseBand.xml';
%%

sim = ATASim.Simulator(xmlFile);

sim.simulateAll();

%%

DD = ATATools.IO.atatcpbinread('SimResults\data1.bin',100000);
ATATools.IO.atatcpfileclose(DD);

%%
blockLen = 1203200;

dataChunk = -50:50;

figure(1)
subplot(2,1,1)
plot(real(DD.data(blockLen+dataChunk))/real(DD.data(blockLen)))
subplot(2,1,2)
plot(imag(DD.data(blockLen+dataChunk))/imag(DD.data(blockLen)))

figure(2)

subplot(2,1,1)
plot(real(DD.data(2*blockLen+dataChunk))/real(DD.data(2*blockLen)))
subplot(2,1,2)
plot(imag(DD.data(2*blockLen+dataChunk))/imag(DD.data(2*blockLen)))

tvec = (0:length(DD.data)-1)/DD.bw/1e6;

figure(3)
subplot(2,1,1)
plot(tvec,real(DD.data))
hold on
plot([blockLen blockLen]/DD.bw/1e6 ,[1.1*max(real(DD.data)),1.1*min(real(DD.data))],'k--')
plot([2*blockLen 2*blockLen]/DD.bw/1e6 ,[1.1*max(real(DD.data)),1.1*min(real(DD.data))],'k--')
hold off
ax(1) = gca;
subplot(2,1,2)
plot(tvec,imag(DD.data))
hold on
plot([blockLen blockLen]/DD.bw/1e6 ,[1.1*max(real(DD.data)),1.1*min(real(DD.data))],'k--')
plot([2*blockLen 2*blockLen]/DD.bw/1e6 ,[1.1*max(real(DD.data)),1.1*min(real(DD.data))],'k--')
hold off
ax(2) = gca;
linkaxes(ax,'x')

figure(4)
spectrogram(DD.data,boxcar(1024),512)