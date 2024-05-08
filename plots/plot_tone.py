#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
from scipy.fft import fft, fftshift
import math
import sys

import pathlib
from typing import Any

def plot_tone(filename: pathlib.Path, iblock: int, index: int, **kwargs: Any) -> None:

    print(f"plotting pulse at bin={index} of block={iblock} in {filename}")

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

    with open(filename, 'rb') as f:
        data = np.fromfile(f, dtype=np.csingle)

    # drop the 4096 byte header
    data = data[512:]

    ndat = data.shape[0]
    print(f"ndat={ndat}")

    Nifft = 196608
    Nstep = 24576
    Nblock = 344064

    inverted = True
    # inverted Low.CBF data are downsampled by 27/32 wrt to input
    if inverted:
        Nifft = (Nifft * 27) // 32
        Nstep = (Nstep * 27) // 32
        Nblock = (Nblock * 27) // 32

    xmin = iblock * Nblock
    if xmin < 0:
        xmin = 0

    xmax = xmin + Nifft
    if xmax > ndat:
        sys.exit(f"error: xmax={xmax} > ndat={ndat}")
        
    print(f'block xmin={xmin} xmax={xmax}')

    data = data[xmin:xmax]
    data = fft(data)

    if inverted:
        data = fftshift(data)

    data = np.real(data * np.conj(data))
    maxval = np.max(data)
    # index = np.argmax(data)

    data /= maxval

    dB_min = -100
    power_min = pow(10.0,dB_min/10.0)
    dB = np.log10(data+power_min)*10

    xval = np.arange(0,Nifft)

    fig, axs = plt.subplots(2)

    axs[0].plot(xval, dB)
    axs[0].set(ylabel="Power (dB)") #, xlabel="Frequency Index")

    xbuf = 20
    xmin = index - xbuf
    xmax = index + xbuf

    print(f'bin xmin={xmin} xmax={xmax}')

    zoom_dB = dB[xmin:xmax]
    zoom_xval = xval[xmin:xmax]

    axs[1].plot(zoom_xval, zoom_dB)
    axs[1].set(ylabel="Power (dB)", xlabel="Frequency Index")

    plot_file = f'tone_{index}.png'
    plt.savefig(plot_file)



def main() -> None:
    """Parse command line arguments and then call plot_tone."""
    import argparse

    # do arg parsing here
    p = argparse.ArgumentParser()
    p.add_argument(
        "filename",
        type=pathlib.Path,
        help="the file to process",
    )
    p.add_argument("iblock", type=int, help="index of data block to analyse.")
    p.add_argument("index", type=int, help="index of FFT bin of expected signal.")

    args = vars(p.parse_args())
    plot_tone(**args)


if __name__ == "__main__":
  main()
