
load('../config/Prototype_FIR.new.4-3.256.3072.mat')

os_num = 4;
os_den = 3;

n_step = n_chan * os_den / os_num;

hsize=size(h);
length=hsize(2);

steps = 1:n_step:length;

plot(h)
xlim([0 length])
xline(steps)
xline(steps(1:end-1)+n_step/2,'--')
xlabel("Array Index")
ylabel("Prototype Impulse Response")