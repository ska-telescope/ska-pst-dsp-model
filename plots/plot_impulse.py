#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
import math
import sys
import pathlib
from typing import Any

def plot_impulse(filename: pathlib.Path, index: int, **kwargs: Any) -> None:
    print(f"plotting pulse at {index} in {filename}")

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

    xbuf = 10000
    xmin = index - xbuf
    if xmin < 0:
        xmin = 0

    xmax = index + xbuf
    if xmax > ndat:
        xmax = ndat

    data = data[xmin:xmax]
    data = np.real(data * np.conj(data))
    maxval = np.max(data)
    data /= maxval

    dB_min = -100
    power_min = pow(10.0,dB_min/10.0)
    dB = np.log10(data+power_min)*10

    xval = np.arange(xmin,xmax)
    plt.plot(xval, dB)
    plt.ylabel("Power (dB)")
    plt.xlabel("Sample Index")

    plot_file = f'impulse_{index}.png'
    plt.savefig(plot_file)


def main() -> None:
    """Parse command line arguments and then call plot_impulse."""
    import argparse

    # do arg parsing here
    p = argparse.ArgumentParser()
    p.add_argument(
        "filename",
        type=pathlib.Path,
        help="the file to process",
    )
    p.add_argument("index", type=int, help="Index of impulse to plot.")

    args = vars(p.parse_args())
    plot_impulse(**args)


if __name__ == "__main__":
  main()
