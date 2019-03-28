function y = makeGaussianNoise(len)
%makeGaussianNoise generates complex Gaussian noise signal
%y = makeGaussianNoise(len) creates len samples of the signal

y = 1/sqrt(2)*(randn(len,1) + 1i*randn(len,1));

end