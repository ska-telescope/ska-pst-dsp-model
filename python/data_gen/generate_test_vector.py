import typing
import logging
import os

import partialize
import numpy as np
import psr_formats

from . import util
from .config import config, config_dir, build_dir

__all__ = [
    "complex_sinusoid",
    "time_domain_impulse",
    "generate_test_vector"
]

module_logger = logging.getLogger(__name__)


def complex_sinusoid(n: int,
                     freqs: typing.List[float],
                     phases: typing.List[float],
                     bin_offset: float = 0.0,
                     dtype: np.dtype = np.complex64):
    """
    Generate a complex sinusoid of length n.
    The sinusoid will be comprised of len(freq) frequencies. Each composite
    sinusoid will have a corresponding phase shift from phases.
    """
    module_logger.debug((f"complex_sinusoid: n={n}, freqs={freqs}, "
                         f"phases={phases}, bin_offset={bin_offset}"))
    if not hasattr(freqs, "__iter__"):
        freqs = [freqs]
        phases = [phases]

    t = np.arange(n)
    sig = np.zeros(n, dtype=dtype)
    for i in range(len(freqs)):
        freq = freqs[i]
        if freq < 1.0:
            freq = int(n*freqs[i])
        sig += np.exp(
            1j*(2*np.pi*(freq + bin_offset)/n*t + phases[i]))
    return sig


def time_domain_impulse(n: int,
                        offsets: typing.List[float],
                        widths: typing.List[int],
                        dtype: np.dtype = np.complex64):
    """
    """
    module_logger.debug((f"time_domain_impulse: n={n}, offsets={offsets}, "
                         f"widths={widths}"))

    if not hasattr(offsets, "__iter__"):
        offsets = [offsets]
        widths = [widths]

    sig = np.zeros(n, dtype=dtype)
    for i in range(len(offsets)):
        offset = offsets[i]
        if offset < 1.0:
            offset = int(offsets[i]*n)
        width = widths[i]
        sig[offset: offset+width] = 1.0
    return sig


def generate_test_vector(domain_name,
                         n_bins,
                         *args,
                         header_template: str = None,
                         output_file_name: str = None,
                         output_dir: str = "./",
                         n_pol: int = 1,
                         dtype: np.dtype = np.complex64,
                         backend: str = "matlab"):
    """
    Sample Matlab command line call:

    .. code-block:: bash

        generate_test_vector complex_sinusoid 1000 0.01,0.5,0.1 single 1 \
            config/default_header.json single_channel.dump ./ 1


    Usage:

    .. code-block:: python

        generator = generate_test_vector("matlab")
        dada_file = generator("freq", 1000, [10], [np.pi/4], 0.1, n_pol=2,
                              output_dir="./",
                              output_file_name="complex_sinusoid.dump",
                              dtype=np.complex64)

        generator = generate_test_vector("python")
        dada_file = generator("freq", 1000, [10], [np.pi/4], 0.1, n_pol=2,
                              output_dir="./",
                              output_file_name="complex_sinusoid.dump",
                              dtype=np.complex64)

    Args:
        backend (str): Whether use Matlab or Python
    """

    module_logger.debug((f"_generate_test_vector: "
                         f"domain_name={domain_name}, "
                         f"n_bins={n_bins}, "
                         f"args={args}, "
                         f"header_template={header_template}, "
                         f"output_file_name={output_file_name}, "
                         f"output_dir={output_dir}, "
                         f"n_pol={n_pol}, "
                         f"dtype={dtype}"))

    if header_template is None:
        header_template = os.path.join(
            config_dir, config["header_file_path"])

    output_base_template = ("{{func_name}}.{n_bins}.{args}."
                            "{n_pol}.{dtype}.{backend}")

    if len(args) > 0:
        args_str = "-".join([f"{f:.3f}" for f in args])
        args_str_comma_sep = ",".join([f"{f:.3f}" for f in args])
    else:
        args_str = ""
        args_str_comma_sep = ""

    matlab_dtype_str = util.matlab_dtype_lookup[dtype]

    output_base = output_base_template.format(
        n_bins=n_bins,
        args=args_str,
        n_pol=n_pol,
        dtype=matlab_dtype_str,
        backend=backend
    )
    args_str = ",".join([f"{f:.3f}" for f in args])

    if backend == "matlab":
        matlab_domain_name_map = {
            "time": "time_domain_impulse",
            "freq": "complex_sinusoid"
        }
        matlab_cmd_str = "generate_test_vector"
        matlab_handler_name = matlab_domain_name_map[domain_name]

        output_base = output_base.format(func_name=matlab_handler_name)

        output_base, log_file_name, output_file_name = \
            util.create_output_file_names(output_file_name, output_base)

        cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                   f"{matlab_handler_name} {n_bins} "
                   f"{args_str_comma_sep} {matlab_dtype_str} {n_pol} "
                   f"{header_template} {output_file_name} {output_dir} 1")

        module_logger.debug((f"_generate_test_vector: backend={backend} "
                             f"cmd_str={cmd_str}"))

        util.run_cmd(cmd_str, log_file_path=os.path.join(
            output_dir, log_file_name))

        return psr_formats.DADAFile(
            os.path.join(output_dir, output_file_name)).load_data()

    elif backend == "python":
        func_lookup = {
            "time": time_domain_impulse,
            "freq": complex_sinusoid,
            "noise": lambda n, dtype=np.float32: (
                np.random.rand(n) +
                1j*np.random.rand(n)).astype(dtype)
        }
        sig = func_lookup[domain_name](n_bins, *args, dtype=dtype)
        output_data = np.zeros((sig.shape[0], 1, n_pol), dtype=dtype)
        for i_pol in range(n_pol):
            output_data[:, 0, i_pol] = sig

        output_base = output_base.format(
            func_name=func_lookup[domain_name].__name__)

        output_base, log_file_name, output_file_name = \
            util.create_output_file_names(output_file_name, output_base)

        dada_file = psr_formats.DADAFile(
            os.path.join(output_dir, output_file_name))

        dada_file.data = output_data
        dada_file.dump_data()
        return dada_file
