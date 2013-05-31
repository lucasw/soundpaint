
data = dlmread("cur_1369971678529.csv", ",");
ld = length(data);
t = [0:ld-1]/ld;

di2 = [];

for i = [1:3:ld]

%fsam = 8000;
%fnyq = fsam/2;


%fmod = abs(data(i)) + 100;
%fmod = 100;
ti = [0:1.0/(480.0): 1.0];
di = interp1(t, data, ti, 'cubic');

% oscillating low pass filter
bf = 0.01 * (sin(i/5.0)+ 1.0)/2.0; %
[b,a] = butter(2, bf);
dif = filter(b,a, di); 

%dif = dif * (sin(i/ld * pi)+1.0)/2.0;

di2 = [di2, dif];

end


di2(isnan(di2))= 0;
di2 = di2 - min(di2);
di2 = di2/max(di2);
di2 = di2*2 - 1;
di2 = di2*5;

t = [1:length(di2)]/length(di2);
%di2 = di2 .* sin(pi*t);
di2 = di2 .* (exp(max(t) -t) - 1);

% add some reverb
el = 20
f2a = [1.0 zeros(1, el) -0.9];
f2b = [1.0 ]; %zeros(1,el) 0.9 zeros(1,el) 0.8];
di2f = filter(b, a, di2);
%di2 = conv(di2, f2b)/sum(f2b);

len = length(di2f) 
len = length(di2) 
figure(1);
plot(di2f);

wavwrite(di2f', 48000,  "test.wav");
