# data_gen.py
# generate impulses, and complex sinusoids.
# Channelize data, and synthesize channelized data.
import os
import typing
import subprocess
import shlex
import json
import logging

import numpy as np
import pfb.formats

from config import load_config

__all__ = [
    "generate_test_vector",
    "channelize",
    "synthesize",
    "meta_data_file_name",
    "complex_sinusoid",
    "time_domain_impulse",
    "find_existing_test_data"
]

module_logger = logging.getLogger(__name__)
cur_dir = os.path.dirname(os.path.abspath(__file__))
build_dir = os.path.join(os.path.dirname(cur_dir), "build")
config_dir = os.path.join(os.path.dirname(cur_dir), "config")
config = load_config()

matlab_dtype_lookup = {
    np.float32: "single",
    np.float64: "double",
    np.complex64: "single",
    np.complex128: "double"
}

meta_data_file_name = "meta.json"


def _run_cmd(cmd_str: str, log_file_path: str = None):

    cmd_split = shlex.split(cmd_str)
    if log_file_path is not None:
        with open(log_file_path, "w") as log_file:
            cmd = subprocess.run(cmd_split,
                                 stdout=log_file,
                                 stderr=log_file)
    else:
        cmd = subprocess.run(cmd_split)

    if cmd.returncode != 0:
        raise RuntimeError("Exited with non zero status")

    return cmd


def _create_output_file_names(output_file_name, default_base):
    if output_file_name is None:
        output_base = default_base
        output_file_name = output_base + ".dump"
    else:
        output_base = os.path.splitext(output_file_name)[0]
    log_file_name = output_base + ".log"

    return output_base, log_file_name, output_file_name


def complex_sinusoid(n: int,
                     freqs: typing.List[float],
                     phases: typing.List[float],
                     bin_offset: float = 0.0,
                     dtype: np.dtype = np.complex64):
    """
    Generate a complex sinusoid of length n.
    The sinusoid will be comprised of len(freq) frequencies. Each composite
    sinusoid will have a corresponding phase shift from phasesself.
    Frequencies should be expressed as a fraction of `n`
    """
    if not hasattr(freqs, "__iter__"):
        freqs = [freqs]
        phases = [phases]

    t = np.arange(n)
    sig = np.zeros(n, dtype=dtype)
    for i in range(len(freqs)):
        sig += np.exp(
            1j*(2*np.pi*(int(n*freqs[i]) + bin_offset)/n*t + phases[i]))
    return sig


def time_domain_impulse(n: int,
                        offsets: typing.List[float],
                        widths: typing.List[int],
                        dtype: np.dtype = np.complex64):
    """
    Offsets should be expressed as a fraction of `n`
    """
    if not hasattr(offsets, "__iter__"):
        offsets = [offsets]
        widths = [widths]

    sig = np.zeros(n, dtype=dtype)
    for i in range(len(offsets)):
        offset = int(offsets[i]*n)
        width = widths[i]
        sig[offset: offset+width] = 1.0
    return sig


def generate_test_vector(backend="matlab"):
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

    def _generate_test_vector(domain_name,
                              n_bins,
                              *args,
                              header_template: str = None,
                              output_file_name: str = None,
                              output_dir: str = "./",
                              n_pol: int = 1,
                              dtype: np.dtype = np.complex64):

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

        matlab_dtype_str = matlab_dtype_lookup[dtype]

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
                _create_output_file_names(output_file_name, output_base)

            cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                       f"{matlab_handler_name} {n_bins} "
                       f"{args_str_comma_sep} {matlab_dtype_str} {n_pol} "
                       f"{header_template} {output_file_name} {output_dir} 1")

            module_logger.debug((f"_generate_test_vector: backend={backend} "
                                 f"cmd_str={cmd_str}"))

            _run_cmd(cmd_str, log_file_path=os.path.join(
                output_dir, log_file_name))

            return pfb.formats.DADAFile(
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
                _create_output_file_names(output_file_name, output_base)

            dada_file = pfb.formats.DADAFile(
                os.path.join(output_dir, output_file_name))

            dada_file.data = output_data
            dada_file.dump_data()
            return dada_file

    return _generate_test_vector


def channelize(backend="matlab"):
    """
    Sample Matlab command line call
    ./build/channelize single_channel.dump 8 8/7 \
        config/OS_Prototype_FIR_8.mat channelized_data.dump ./ 1
    """

    def _channelize(input_data_file_path: str,
                    channels: int,
                    os_factor_str: str,
                    fir_filter_path: str = None,
                    output_file_name: str = None,
                    output_dir: str = "./",):

        if fir_filter_path is None:
            fir_filter_path = os.path.join(
                config_dir, config["fir_filter_coeff_file_path"])

        matlab_cmd_str = "channelize"

        output_base = (f"{matlab_cmd_str}.{channels}."
                       f"{'-'.join(os_factor_str.split('/'))}")

        output_base, log_file_name, output_file_name = \
            _create_output_file_names(output_file_name, output_base)

        if backend == "matlab":

            cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                       f"{input_data_file_path} "
                       f"{channels} {os_factor_str} {fir_filter_path} "
                       f"{output_file_name} {output_dir} 1")

            module_logger.debug(f"_synthesize: cmd_str={cmd_str}")

            _run_cmd(cmd_str, log_file_path=os.path.join(
                output_dir, log_file_name))

            return pfb.formats.DADAFile(
                os.path.join(output_dir, output_file_name)).load_data()

        elif backend == "python":
            raise NotImplementedError(("channelize not "
                                       "implemented in Python"))

    return _channelize


def synthesize(backend="matlab"):
    """
    Sample Matlab command:

    .. code-block:: bash
        ./build/synthesize \
            channelized_data.dump \
            16384 test_synthesis.dump ./ 1
    """
    def _synthesize(input_data_file_path,
                    input_fft_length,
                    output_file_name: str = None,
                    output_dir: str = "./",):
        """

        """
        matlab_cmd_str = "synthesize"
        output_base = (f"{matlab_cmd_str}.{input_fft_length}")

        output_base, log_file_name, output_file_name = \
            _create_output_file_names(output_file_name, output_base)

        if backend == "matlab":

            cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                       f"{input_data_file_path} "
                       f"{input_fft_length} "
                       f"{output_file_name} {output_dir} 1")

            module_logger.debug(f"_synthesize: cmd_str={cmd_str}")

            _run_cmd(cmd_str, log_file_path=os.path.join(
                output_dir, log_file_name))
            return pfb.formats.DADAFile(
                os.path.join(output_dir, output_file_name)).load_data()

        elif backend == "python":
            raise NotImplementedError(("synthesize not "
                                       "implemented in Python"))

    return _synthesize


def find_existing_test_data(base_dir, domain_name, params):
    """
    Determine if any existing test data exist in given base_dir

    Args:
        base_dir (str): The base directory from where search will begin
        domain_name (str): "time" or "freq"
        params (tuple or dict): Dictionary or tuple of arguments for
            test vector creation
    """

    arg_order = {
        "time": ("offset", "width"),
        "freq": ("frequency", "phase", "bin_offset")
    }

    sub_dir_format_map = {
        "time": "o-{offset:.3f}_w-{width:.3f}",
        "freq": "f-{frequency:.3f}_b-{bin_offset:.3f}_p-{phase:.3f}"
    }

    sub_dir_formatter = sub_dir_format_map[domain_name]

    if not hasattr(params, "keys"):
        params_dict = {
            arg_name: params[i]
            for i, arg_name in enumerate(arg_order[domain_name])
        }
    else:
        params_dict = params

    sub_dir = sub_dir_formatter.format(**params_dict)

    sub_dir_full = os.path.join(base_dir, domain_name, sub_dir)
    meta_data = None
    if os.path.exists(sub_dir_full):
        meta_data_file_path = os.path.join(sub_dir, meta_data_file_name)
        with open(meta_data_file_path, 'r') as f:
            meta_data = json.load(f)

    return meta_data
