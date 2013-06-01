
filename = "cur_1369971678529.csv"

a = nargin
%arg_list = argv();
for i = [1:nargin]
  filename = argv(){i} %argv(i)
end
%return

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

for i = [1:1500]

base_freq = 100.0;
freq = base_freq + 50.0 * sin(i * 0.07);
ti = [0:1.0/freq:1.0];
di = interp1(t, data, ti, 'linear');

if true
  % oscillating low pass filter
  %bf = 0.08 * (sin(i * 0.41) + 0.05*sin(i*0.91) + 1.2)/2.4; %
  bf = 0.08 * (sin(i * 0.312) + 1.0)/2.0; 
  [b,a] = butter(2, bf);
  dif = filter(b,a, di); 
else
  dif = di;
end

di2 = [di2, dif];

  if (i == 1) 
    figure(10)
    plot(ti,di);
  end
end

di2(isnan(di2))= 0;

% add some reverb
if true
el = 30
b=[0.6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
a=[1.0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.6];
di2f = filter(b, a, di2);
%f2a = [0.6 zeros(1,el) 1.0]; %zeros(1, el) -0.8];
%f2b = [1.0 zeros(1,el+1) 0.9];
%di2f = filter(f2b, f2a, di2);
else
  di2f = di2;
end
%di2 = conv(di2, f2b)/sum(f2b);

di2f = di2f - min(di2f);
di2f = di2f/max(di2f);
di2f = di2f*2 - 1;
%di2 = di2*5;

ldf = length(di2f);
if false
t = [1:ldf]/ldf;
di2f = di2f .* sin(pi*t*2);
end

decay_len = 20000;
lt = [1:decay_len];
mod =  (cos(pi * lt/decay_len) + 1.0)/2.0;
di2f(ldf - decay_len + 1:ldf) = di2f(ldf - decay_len + 1:ldf) .* mod;
%di2f = di2f .* (exp(max(t) -t) - 1);


len = length(di2f) 
len = length(di2) 
%figure(2);
subplot(2,1,2);
plot(di2f);

figure(2);
plot(di2f(floor(ldf/2)+2000:floor(ldf/2)+5000));
%pause;

sound(di2f', 48000);
%f = filename, ".wav";
wavwrite(di2f', 48000,  [filename, ".wav"]);

