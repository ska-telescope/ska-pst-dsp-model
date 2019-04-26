import argparse
import os
import logging

import numpy as np
import matplotlib.pyplot as plt

from compare_dump_files import load_binary_data, dtype_map

module_logger = logging.getLogger(__name__)


def plot_binary_files(*file_paths: str, dtype=None, offset=0):

    if dtype is None:
        raise RuntimeError("Have to specify a data type")
    data = []
    for f in file_paths:
        if f.endswith(".npy"):
            data.append(np.load(f).flatten())
        else:
            data.append(load_binary_data(f, dtype=dtype, offset=offset))

    iscomplex = np.iscomplexobj(data[0])
    n_z = 2 if iscomplex else 1
    n_z_fn = [np.real, np.imag]

    fig, axes = plt.subplots(len(file_paths), n_z)
    if not hasattr(axes, "__getitem__"):
        axes = [[axes]]
    if not hasattr(axes[0], "__getitem__"):
        axes = [axes]

    for i in range(len(file_paths)):
        for z in range(n_z):
            ax = axes[i][z]
            ax.grid(True)
            ax.set_title(os.path.basename(file_paths[i]))
            ax.plot(n_z_fn[z](data[i]))
            # ax.set_xlim([10000, 10050])

    plt.show()


def create_parser():
    parser = argparse.ArgumentParser(
        description="Plot the contents of binary file(s)")

    parser.add_argument("-v", "--verbose",
                        dest="verbose", action="store_true")

    parser.add_argument("-i", "--input-files",
                        dest="input_file_paths",
                        nargs="+", type=str,
                        required=True)

    parser.add_argument("-dt", "--dtype",
                        dest="dtype", type=str, required=True,
                        help=("Specify the data type of the binary file. "
                              f"Available types are {list(dtype_map.keys())}"))

    parser.add_argument("--offset",
                        dest="offset", type=int, required=False,
                        default=0,
                        help=("Specify the data location (in bytes) in "
                              "the binary file."))
    return parser


def main():
    parsed = create_parser().parse_args()
    level = logging.INFO
    if parsed.verbose:
        level = logging.DEBUG
    logging.basicConfig(level=level)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    plot_binary_files(
        *parsed.input_file_paths,
        dtype=dtype_map[parsed.dtype],
        offset=parsed.offset
    )


if __name__ == "__main__":
    main()
