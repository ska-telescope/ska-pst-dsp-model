import numpy as np
import matplotlib.pyplot as plt


def dB(a):
    return 20.0*np.log10(np.abs(a) + 1e-12)


def recombine(r, i=None):
    if i is None:
        return r
    else:
        return r + 1j*i


def default_labels(labels):
    if labels is None:
        labels = [f"array {i+1}" for i in range(2)]
    return labels


def plot_freq_domain_comparison(time_operator_result,
                                freq_operator_result,
                                subplots_kwargs=None,
                                labels=None):
    """
    """
    labels = default_labels(labels)
    fig, axes = plt.subplots(4, 2, **subplots_kwargs)
    fig, axes = plot_freq_domain_comparison(
        time_operator_result, labels=labels)


def plot_time_domain_comparison(operator_result,
                                subplots_kwargs=None,
                                labels=None,
                                fig_axes=None):
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
    labels = default_labels(labels)
    if fig_axes is None:
        fig, axes = plt.subplots(2, 2, **subplots_kwargs)
    else:
        fig, axes = fig_axes
    for ax in axes.flatten():
        ax.grid(True)
        ax.set_xlabel("Time Samples")

    a, b = [recombine(*a) for a in operator_result["this"]]
    diff = recombine(*operator_result["diff"][0, 1])

    axes[0, 0].plot(np.abs(a))
    axes[0, 0].set_title(labels[0])
    axes[0, 0].set_ylabel("Signal level (Arbitrary Units)")

    axes[0, 1].plot(np.abs(b))
    axes[0, 1].set_title(labels[1])
    axes[0, 1].set_ylabel("Signal level (Arbitrary Units)")

    axes[1, 0].plot(np.abs(diff))
    axes[1, 0].set_title("Signal difference")
    axes[1, 0].set_ylabel("Signal level (Arbitrary Units)")

    axes[1, 1].plot(dB(diff))
    axes[1, 1].set_title("Power of Difference")
    # axes[1, 1].set_ylim([])
    axes[1, 1].set_ylabel("Power (dB)")

    return fig, axes
