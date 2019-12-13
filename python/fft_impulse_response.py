import numpy as np
import matplotlib.pyplot as plt

from data_gen.generate_test_vector import time_domain_impulse


def generate_data(nsamples, offsets, widths, channels):

    impulse = time_domain_impulse(nsamples, offsets, widths)
    nsamples_downsample = nsamples // channels

    fft_impulse = impulse.reshape((nsamples_downsample, channels))

    fft_impulse = np.fft.fft(fft_impulse, axis=1)

    return impulse, fft_impulse


def plot_data(impulse, fft_impulse):

    imshow_kwargs = dict(
        aspect="auto"
    )

    fig, axes = plt.subplots(2, 1)

    axes[0].plot(np.abs(impulse))
    axes[1].imshow(np.abs(fft_impulse.T), **imshow_kwargs)

    return fig, axes


def main():
    channels = 1024
    nsamples = 100*channels

    offsets = [int(0.5*nsamples)]
    widths = [1]

    dat = generate_data(nsamples, offsets, widths, channels)

    plot_data(*dat)

    plt.show()


if __name__ == "__main__":
    main()
