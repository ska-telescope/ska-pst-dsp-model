import argparse
import typing
import logging
import os

import matplotlib.pyplot as plt
import numpy as np
import scipy.signal

import psr_formats
import comparator

__all__ = [
    "load_n_chop",
    "compare_dump_files"
]

cur_dir = os.path.dirname(os.path.abspath(__file__))
products_dir = os.path.join(os.path.dirname(cur_dir), "products")

module_logger = logging.getLogger(__name__)


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


dtype_map = {
    "f32": np.float32,
    "f64": np.float64,
    "c64": np.complex64,
    "c128": np.complex128
}


def load_binary_data(file_path: str,
                     dtype: np.dtype, offset: int = 0) -> np.ndarray:
    with open(file_path, "rb") as f:
        buffer = f.read()
    data = np.frombuffer(buffer, dtype=dtype, offset=offset)
    return data


def load_n_chop_binary(
    *file_paths: typing.Tuple[str],
    dtype: np.dtype = None,
    offset: int = 0
):
    module_logger.debug((f"load_n_chop_binary: loading data from "
                         f"{len(file_paths)} files"))
    data = []

    for file_path in file_paths:
        data.append(
            load_binary_data(file_path, dtype=dtype, offset=offset))

    min_dat = np.amin([d.shape[0] for d in data])
    data = [d[:min_dat] for d in data]
    return data


def load_n_chop_npy(
    *file_paths,
    chan: list = None,
    dat: list = None,
    arrangement: str = None
):

    if arrangement is None:
        arrangement = {'dat': 0, 'chan': 1}

    module_logger.debug((f"load_n_chop: loading data from "
                         f"{len(file_paths)} files"))
    chan = _process_dim(chan)
    dat = _process_dim(dat)
    data = []
    for f in file_paths:
        arr = np.load(f)
        if arr.ndim == 2:
            s = [slice(None) for i in range(2)]
            s[arrangement['dat']] = dat
            s[arrangement['chan']] = chan
            arr = arr[s].flatten()
        data.append(arr)

    return data


def load_n_chop_dada(
    *file_paths: typing.Tuple[str],
    pol: list = None,
    chan: list = None,
    dat: list = None
):
    module_logger.debug((f"load_n_chop: loading data from "
                         f"{len(file_paths)} files"))
    dada_files = [psr_formats.DADAFile(f).load_data() for f in file_paths]
    pol = _process_dim(pol)
    chan = _process_dim(chan)
    dat = _process_dim(dat)

    module_logger.debug((f"load_n_chop: comparing pol={pol},"
                         f" chan={chan}, dat={dat}"))

    min_dat = np.amin([d.ndat for d in dada_files])
    data = [d.data[:min_dat, :, :] for d in dada_files]
    data = [d[dat, chan, pol].flatten() for d in data]
    return data, dada_files


def correlate(a, b):
    # print(a.shape, a.dtype)
    # print(b.shape, b.dtype)
    f_a = np.fft.fft(a)
    f_b = np.fft.fft(b)
    return f_a*np.conj(f_b)


def compare_dump_files(
    *file_paths: typing.Tuple[str],
    pol: list = None,
    chan: list = None,
    dat: list = None,
    fft_size: int = None,
    fft_offset: int = 0,
    normalize: bool = False,
    freq_domain: bool = True,
    time_domain: list = None,
    comp: comparator.MultiDomainComparator = None,
    dtype: np.dtype = None,
    offset: int = 0,
    save_plots: bool = False,
    plot_file_name_base: str = "",
    plot_output_dir: str = None
):
    module_logger.debug((f"compare_dump_files: time_domain: {time_domain}, "
                         f"freq_domain: {freq_domain}"))

    if plot_output_dir is None:
        plot_output_dir = products_dir

    if dtype is not None:
        data_slice = load_n_chop_binary(
            *file_paths, dtype=dtype, offset=offset)
    else:
        if file_paths[0].endswith(".dump"):
            data_slice = load_n_chop_dada(
                *file_paths, pol=pol, chan=chan, dat=dat)[0]
        else:
            data_slice = load_n_chop_npy(*file_paths, chan=chan, dat=dat)

    if normalize:
        module_logger.debug("compare_dump_files: normalizing data")
        data_slice = [d/np.amax(np.abs(d)) for d in data_slice]

    if fft_size is None:
        fft_size = len(data_slice[0])
        fft_offset = 0

    if comp is None:
        module_logger.debug("compare_dump_files: creating default comparator")
        # comp = comparator.TimeFreqDomainComparator()
        comp = comparator.MultiDomainComparator(domains={
            "time": comparator.SingleDomainComparator("time"),
            "freq": comparator.FrequencyDomainComparator()
        })
        comp.freq.domain = [fft_offset, fft_size+fft_offset]
        print(comp.freq._operation_domain)
        if time_domain is not None:
            comp.time.domain = time_domain

        comp.operators["this"] = lambda a: a

        if len(data_slice) > 1:
            pass
            # comp.operators["diff"] = lambda a, b: a - b
            # comp.operators["scipy.signal.fftconvolve"] = lambda a, b: \
            #     scipy.signal.fftconvolve(a, b[::-1], mode="full")
            # comp.operators["scipy.signal.correlate"] = lambda a, b: \
            #     np.fft.ifft(scipy.signal.correlate(a, b, mode="same", method="fft"))

            # comp.operators["xcorr"] = lambda a, b: np.correlate(a, b, mode="full")
            # comp.operators["correlate"] = correlate

        comp.products["argmax"] = lambda a: np.argmax(a)
        comp.products["mean"] = lambda a: np.mean(a)
        comp.products["sum"] = lambda a: np.sum(a)

    file_names = [os.path.basename(f) for f in file_paths]
    figs = []
    if freq_domain:
        module_logger.info(
            "compare_dump_files: doing frequency domain comparison")
        res_op, res_prod = comp.freq.cartesian(*data_slice, labels=file_names)
        # print(res_prod["this"])
        # print(res_prod["diff"])
        f, a = comparator.util.plot_operator_result(res_op, figsize=(16, 9))
        figs.extend(f)

    if time_domain is not None:
        module_logger.info(
            "compare_dump_files: doing time domain comparison")
        # res_op, res_prod = comp.time.polar(*data_slice, labels=file_names)
        res_op, res_prod = comp.time.cartesian(*data_slice, labels=file_names)
        # print(res_prod["this"])
        print(res_prod["this"])
        print(res_op["this"].result[0])
        # print(res_prod["diff"])
        f, a = comparator.util.plot_operator_result(res_op, figsize=(16, 9))
        figs.extend(f)

        # res_op, res_prod = comp.time.cartesian(*data_slice, labels=file_names)
        # print(res_prod["this"])
        # # print(res_prod["diff"])
        # f, a = comparator.util.plot_operator_result(res_op, figsize=(16, 9))
        # figs.extend(f)


    if time_domain or freq_domain:
        if save_plots:
            if plot_file_name_base != "":
                plot_file_name_base = f"{plot_file_name_base}."
            for i in range(len(figs)):
                file_name = f"compare_dump_files.{plot_file_name_base}{i}.png"
                file_path = os.path.join(plot_output_dir, file_name)
                figs[i].savefig(file_path)
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

    parser.add_argument("--fft_offset",
                        dest="fft_offset", type=int, required=False)

    parser.add_argument("-t", "--time_domain",
                        nargs="*",
                        type=str, required=False,
                        default=None,
                        dest="time_domain")

    parser.add_argument("-f", "--freq_domain",
                        dest="freq_domain", action="store_true")

    parser.add_argument("-p", "--pol",
                        dest="pol", type=str, required=False, default="")

    parser.add_argument("-c", "--chan",
                        dest="chan", type=str, required=False, default="")

    parser.add_argument("-d", "--dat",
                        dest="dat", type=str, required=False, default="")

    parser.add_argument("-n", "--normalize",
                        dest="normalize", action="store_true")

    parser.add_argument("-dt", "--dtype",
                        dest="dtype", type=str, required=False,
                        default=None,
                        help=("Specify the data type of the binary file. "
                              f"Available types are {list(dtype_map.keys())}"))

    parser.add_argument("--offset",
                        dest="offset", type=int, required=False,
                        default=0,
                        help=("Specify the data location (in bytes) in "
                              "the binary file."))

    parser.add_argument("-v", "--verbose",
                        dest="verbose", action="store_true")

    parser.add_argument("-sp", "--save_plots",
                        dest="save_plots", action="store_true")

    parser.add_argument("--plot_file_name_base",
                        dest="plot_file_name_base", type=str, required=False,
                        default="",
                        help="Specify the plot file base name")

    return parser


def main():
    parsed = create_parser().parse_args()
    level = logging.INFO
    if parsed.verbose:
        level = logging.DEBUG
    logging.basicConfig(level=level)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)

    time_domain = parsed.time_domain
    if time_domain is not None:
        if len(time_domain) == 0:
            time_domain = slice(0, None)
        elif len(time_domain) == 1:
            time_domain = [int(s) for s in time_domain[0].split(",")]
        else:
            time_domain = [int(i) for i in time_domain]

    dtype = parsed.dtype
    if dtype is not None:
        dtype = dtype_map[dtype]

    compare_dump_files(
        *parsed.input_file_paths,
        pol=_parse_dim(parsed.pol),
        chan=_parse_dim(parsed.chan),
        dat=_parse_dim(parsed.dat),
        fft_size=parsed.fft_size,
        fft_offset=parsed.fft_offset,
        normalize=parsed.normalize,
        freq_domain=parsed.freq_domain,
        time_domain=time_domain,
        dtype=dtype,
        offset=parsed.offset,
        save_plots=parsed.save_plots,
        plot_file_name_base=parsed.plot_file_name_base
    )


if __name__ == "__main__":
    main()
