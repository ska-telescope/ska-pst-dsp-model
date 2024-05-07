import numpy as np
import matplotlib.pyplot as plt
from scipy.fft import fft
import math
import sys

SMALL_SIZE = 8
MEDIUM_SIZE = 12
BIGGER_SIZE = 16

plt.rc('font', size=SMALL_SIZE)          # controls default text sizes
plt.rc('axes', titlesize=SMALL_SIZE)     # fontsize of the axes title
plt.rc('axes', labelsize=MEDIUM_SIZE)    # fontsize of the x and y labels
plt.rc('xtick', labelsize=SMALL_SIZE)    # fontsize of the tick labels
plt.rc('ytick', labelsize=SMALL_SIZE)    # fontsize of the tick labels
plt.rc('legend', fontsize=SMALL_SIZE)    # legend fontsize
plt.rc('figure', titlesize=BIGGER_SIZE)  # fontsize of the figure title

inputArgs = sys.argv
filename = inputArgs[1]
iblock = int(inputArgs[2])
index = int(inputArgs[3])

print(f"plotting pulse at {index} in {filename}")

with open(filename, 'rb') as f:
  data = np.fromfile(f, dtype=np.csingle)

# drop the 4096 byte header
data = data[512:]

ndat = data.shape[0]
print(f"ndat={ndat}")

Nifft = 165888
Nblock = 282624

xmin = iblock * Nblock
if xmin < 0:
    xmin = 0

xmax = xmin + Nifft - 1
if xmax > ndat:
    sys.exit(f"error: xmax={xmax} > ndat={ndat}")
    
print(f'xmin={xmin} xmax={xmax}')

data = data[xmin:xmax]
data = fft(data)
data = np.real(data * np.conj(data))
maxval = np.max(data)
data /= maxval

dB_min = -100
power_min = pow(10.0,dB_min/10.0)
dB = np.log10(data+power_min)*10

xval = np.arange(xmin,xmax)
plt.plot(xval, dB)
plt.ylabel("Power (dB)")
plt.xlabel("Frequency Index")

plot_file = f'tone_{index}.png'
plt.savefig(plot_file)

