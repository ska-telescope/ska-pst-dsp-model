import argparse
import typing
import logging
# import sys
# import os

# sys.path.insert(0, os.path.join(os.path.expanduser("~"), "ska/comparator"))
import matplotlib.pyplot as plt
import numpy as np

import pfb.formats
import comparator


def _process_dim(dim) -> slice:
    if dim is None:
        dim = slice(0, None, None)
    elif hasattr(dim, "__add__") and hasattr(dim, "__iter__"):
        dim = slice(*dim)
    return dim


def _parse_dim(dim_info: str) -> list:
    """
    parse pol, chan, or dat information coming from the command line
    """
    if dim_info == "":
        dim = None
    else:
        dim = [int(s) for s in dim_info.split(',')]
        if len(dim) == 1:
            dim = dim[0]
    return dim


def compare_dump_files(
    *file_paths: typing.Tuple[str],
    pol: list = None,
    chan: list = None,
    dat: list = None,
    fft_size: int = None,
    normalize: bool = False,
):
    dada_files = [pfb.formats.DADAFile(f).load_data() for f in file_paths]
    pol = _process_dim(pol)
    chan = _process_dim(chan)
    dat = _process_dim(dat)

    print(f"Comparing pol={pol}, chan={chan}, dat={dat}")

    min_dat = np.amin([d.ndat for d in dada_files])
    data = [d.data[:min_dat, :, :] for d in dada_files]
    data_slice = [d[dat, chan, pol].flatten() for d in data]

    if normalize:
        data_slice = [d/np.amax(d) for d in data_slice]

    if fft_size is None:
        fft_size = len(data_slice[0])

    comp = comparator.TimeFreqDomainComparator()
    comp.freq.domain = [0, fft_size]
    # comp.time.domain = [0, 100]  # for plotting speed

    comp.operators["this"] = lambda a: a
    comp.operators["diff"] = lambda a, b: np.abs(a - b)

    comp.products["argmax"] = lambda a: np.argmax(a)

    # res_op, res_prod = comp.freq.cartesian(*data_slice)
    # print(res_prod["this"])
    # comparator.util.plot_operator_result(res_op)
    print(np.iscomplexobj(data_slice[0]))
    print(data_slice)
    res_op, res_prod = comp.time.cartesian(*data_slice)
    print(res_prod["this"])
    comparator.util.plot_operator_result(res_op)

    plt.show()


def create_parser():

    parser = argparse.ArgumentParser(
        description="compare the contents of two dump files")

    parser.add_argument("-i", "--input-files",
                        dest="input_file_paths",
                        nargs="+", type=str,
                        required=True)

    parser.add_argument("-fft", "--fft_size",
                        dest="fft_size", type=int, required=False)

    parser.add_argument("-p", "--pol",
                        dest="pol", type=str, required=False, default="")

    parser.add_argument("-c", "--chan",
                        dest="chan", type=str, required=False, default="")

    parser.add_argument("-d", "--dat",
                        dest="dat", type=str, required=False, default="")

    parser.add_argument("-n", "--normalize",
                        dest="normalize", action="store_true")

    parser.add_argument("-v", "--verbose",
                        dest="verbose", action="store_true")

    return parser


def main():
    parsed = create_parser().parse_args()
    level = logging.INFO
    if parsed.verbose:
        level = logging.DEBUG
    logging.basicConfig(level=level)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    compare_dump_files(
        *parsed.input_file_paths,
        pol=_parse_dim(parsed.pol),
        chan=_parse_dim(parsed.chan),
        dat=_parse_dim(parsed.dat),
        fft_size=parsed.fft_size,
        normalize=parsed.normalize
    )


if __name__ == "__main__":
    main()
