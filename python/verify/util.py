import numpy as np
import matplotlib.pyplot as plt

__all__ = [
    "spurious",
    "total_spurious",
    "mean_spurious",
    "max_spurious",
    "dB",
    "plot_time_domain_comparison",
    "plot_freq_domain_comparison"
]


def spurious(a):
    b = a.copy()
    b[np.argmax(b)] = 0.0
    return b


def total_spurious(a):
    ret = spurious(np.abs(a)**2)
    val = dB(np.sum(ret))
    return val


def mean_spurious(a):
    ret = spurious(np.abs(a)**2)
    val = dB(np.mean(ret))
    return val


def max_spurious(a):
    ret = spurious(np.abs(a)**2)
    val = dB(np.amax(ret))
    return val


def dB(a):
    """
    Assumes a is already in "power" space
    """
    return 10.0*np.log10(np.abs(a.copy()) + 1e-13)


def _default_labels(labels):
    if labels is None:
        labels = [f"array {i+1}" for i in range(2)]
    return labels


def plot_freq_domain_comparison(time_operator_result,
                                freq_operator_result,
                                subplots_kwargs=None,
                                labels=None):
    """
    """
    def time_series_plotter(ax, a):
        ax.plot(np.real(a))
        ax.plot(np.imag(a))

    labels = _default_labels(labels)
    if subplots_kwargs is None:
        subplots_kwargs = {}
    fig, axes = plt.subplots(4, 2, **subplots_kwargs)
    fig, axes = plot_time_domain_comparison(
        time_operator_result, labels=labels,
        fig_axes=(fig, axes), time_series_plotter=time_series_plotter)

    idx = 2
    a, b = freq_operator_result["this"]
    diff = freq_operator_result["diff"][1, 0]

    arr = [a, b]
    for i in range(2):
        axes[idx, i].plot(dB(arr[i]))
        axes[idx, i].set_xlabel("Frequency Bin")
        axes[idx, i].set_ylabel("Power (dB)")
        axes[idx, i].set_title(labels[i] + " Power Spectrum")

    # axes[idx + 1, 0].plot(np.abs(diff))
    axes[idx + 1, 0].plot(dB(diff))
    axes[idx + 1, 0].set_xlabel("Frequency Bin")
    axes[idx + 1, 0].set_ylabel("Power (dB)")
    axes[idx + 1, 0].set_title("Power Spectrum of Difference")
    axes[idx + 1, 0].change_geometry(4, 1, 4)
    axes[idx + 1, 1].remove()
    # axes[idx + 1, 1].plot(np.angle(diff))
    # axes[idx + 1, 1].set_xlabel("Frequency Bin")
    # axes[idx + 1, 1].set_ylabel("Radians")
    # axes[idx + 1, 1].set_title("Phase Difference")

    return fig, axes


def plot_time_domain_comparison(operator_result,
                                subplots_kwargs=None,
                                labels=None,
                                fig_axes=None,
                                time_series_plotter=None):
    """
    Create an array of plots for comparing two time series in the time domain.
    operator_result should have "this" and "diff" fields.

    First row contains the original time series.

    The second row contains the difference between the time series, and the
    power of the difference between the two time series.

    Args:
        operator_result (comparator.OperatorResult)

    """
    if subplots_kwargs is None:
        subplots_kwargs = {}
    labels = _default_labels(labels)
    if fig_axes is None:
        fig, axes = plt.subplots(2, 2, **subplots_kwargs)
    else:
        fig, axes = fig_axes
    if time_series_plotter is None:
        def time_series_plotter(ax, a):
            ax.plot(dB(np.abs(a)))

    for ax in axes.flatten():
        ax.grid(True)
        ax.set_xlabel("Time Samples")

    a, b = operator_result["this"]
    diff = operator_result["diff"][1, 0]

    arr = [a, b]
    for i in range(len(arr)):
        time_series_plotter(axes[0, i], arr[i])
        axes[0, i].set_title(labels[i])
        axes[0, i].set_ylabel("Power level (dB)")

    axes[1, 0].plot(dB(diff))
    axes[1, 0].set_title("Power of Difference")
    # axes[1, 1].set_ylim([])
    axes[1, 0].set_ylabel("Power (dB)")
    axes[1, 0].change_geometry(len(axes), 1, 2)
    axes[1, 1].remove()

    return fig, axes
