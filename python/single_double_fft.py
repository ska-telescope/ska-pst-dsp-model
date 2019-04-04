import os

import matplotlib.pyplot as plt
import numpy as np
import scipy.fftpack

cur_dir = os.path.dirname(os.path.abspath(__file__))
product_dir = os.path.join(os.path.dirname(cur_dir), "products")


def single_double_fft(fft_fn):

    size = 1024

    x_single = np.random.rand(size).astype(np.float32)
    x_double = x_single.astype(np.float64)
    x_diff = np.abs(x_single.astype(np.float64) - x_double)

    fig, axes = plt.subplots(2, 1, figsize=(16, 9))

    axes[0].plot(x_diff)
    axes[0].grid(True)
    axes[0].set_title("Difference between input")

    f_single = fft_fn(x_single)
    f_double = fft_fn(x_double)

    print((f"Data type after applying FFT to single"
           f" precision array: {f_single.dtype}"))
    print((f"Data type after applying FFT to double"
           f" precision array: {f_double.dtype}"))

    f_diff = abs(f_single.astype(np.complex128) - f_double)

    axes[1].plot(f_diff)
    axes[1].grid(True)
    axes[1].set_title("Difference between FFT output")

    func_module = f"{fft_fn.__module__}.{fft_fn.__name__}"

    fig.suptitle(f"Single vs Double precision FFT for {func_module}")
    fig.tight_layout(rect=[0, 0.03, 1, 0.95])
    fig.savefig(
        os.path.join(product_dir, f"single_double_fft.{func_module}.png"))


if __name__ == "__main__":
    single_double_fft(np.fft.fft)
    single_double_fft(scipy.fftpack.fft)
    plt.show()
