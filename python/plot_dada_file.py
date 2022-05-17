import sys

import psr_formats
import numpy as np

import matplotlib.pyplot as plt


def plot_dada_file(file_path: str):
    dada_file = psr_formats.DADAFile(file_path).load_data()
    nchan = dada_file.nchan
    npol = dada_file.npol

    fig, axes = plt.subplots(npol, 1)
    if not hasattr(axes, "__getitem__"):
        axes = [axes]

    for ipol in range(npol):
        axes[ipol].set_title(f"Polarization {ipol}")
        axes[ipol].set_xlabel("Samples")

    if nchan == 1:
        for ipol in range(npol):
            axes[ipol].plot(np.abs(dada_file.data[:, 0, ipol]))
            axes[ipol].set_ylabel("Amplitude")
    else:
        imshow_kwargs = dict(
            aspect="auto"
        )
        for ipol in range(npol):
            axes[ipol].imshow(np.abs(dada_file.data[:, :, ipol].T), **imshow_kwargs)
            axes[ipol].set_ylabel("Channels")

    plt.show()

if __name__ == "__main__":
    plot_dada_file(sys.argv[1])
