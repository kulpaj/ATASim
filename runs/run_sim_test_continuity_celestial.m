close all
clearvars

delete SimResults\*bin

%xmlFile = 'xml/sim1.xml';
xmlFile = 'xml\simTestContinuityCelestial.xml';
%%

sim = ATASim.Simulator(xmlFile);

sim.simulateAll();

%%

DD = ATATools.IO.atatcpbinread('SimResults\contcel\data1.bin',100000);

figure(1)
subplot(2,1,1)
plot(real(DD.data(1203150:1203250)))
subplot(2,1,2)
plot(imag(DD.data(1203150:1203250)))

figure(2)

subplot(2,1,1)
plot(real(DD.data(2406350:2406450)))
subplot(2,1,2)
plot(imag(DD.data(1203200+1203150:1203250+1203200)))

figure(3)
plot(real(DD.data))

ATATools.IO.atatcpfileclose(DD);