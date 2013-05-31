
data = dlmread("cur_1369971678529.csv", ",");
ld = length(data);
t = [0:ld-1]/ld;

di2 = []

for i = [1:10:ld]

fmod = abs(data(i)) + 100
ti = [0:(fmod)/(5000.0): 1];
di = interp1(t, data, ti, 'cubic');

di2 = [di2, di];


end

figure(1);
plot(di2);

wavwrite(di2', "test.wav");
