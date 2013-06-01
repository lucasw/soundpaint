
filename = "cur_1369971678529.csv";

data = dlmread(filename, ",");
%data = data - mode(data); %mean(data);
figure(1);
subplot(2,1,1);
plot(data);
ld = length(data);
t = [0:ld-1]/ld;

di2 = [];

%for i = [1:3:ld]
%fmod = abs(data(i)) + 100;
%fmod = 100;

for i = [1:200]

ti = [0:1.0/(480.0): 1.0];
di = interp1(t, data, ti, 'cubic');

% oscillating low pass filter
bf = 0.08 * (sin(i * 0.41) + 1.0)/2.0; %
[b,a] = butter(2, bf);
dif = filter(b,a, di); 

di2 = [di2, dif];

end

di2(isnan(di2))= 0;

% add some reverb
el = 100
f2a = [1.0 ]; % zeros(1, el) 0.99];
f2b = [1.0 zeros(1,el) 0.9 zeros(1,el) 0.8];
di2f = filter(b, a, di2);
%di2 = conv(di2, f2b)/sum(f2b);

di2f = di2f - min(di2f);
di2f = di2f/max(di2f);
di2f = di2f*2 - 1;
%di2 = di2*5;

ldf = length(di2f);
t = [1:ldf]/ldf;
di2f = di2f .* sin(pi*t*2);

lt = [1:1000];
di2f(ldf-1000+1:ldf) = di2f(ldf-1000+1:ldf) .* cos(pi * lt);
%di2f = di2f .* (exp(max(t) -t) - 1);


len = length(di2f) 
len = length(di2) 
%figure(2);
subplot(2,1,2);
plot(di2f);

figure(2);
plot(di2f(ldf/2+2000:ldf/2+5000));


sound(di2f', 48000);
wavwrite(di2f', 48000,  "test.wav");

