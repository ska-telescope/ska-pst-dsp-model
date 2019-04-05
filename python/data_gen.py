# data_gen.py
# generate impulses, and complex sinusoids. Channelize data, and synthesized
# chanenlized data.
import os
import typing
import subprocess
import shlex
import json
import logging

import numpy as np

__all__ = [
    "generate_test_vector",
    "channelize",
    "synthesize",
    "meta_data_file_name"
]

module_logger = logging.getLogger(__name__)
cur_dir = os.path.dirname(os.path.abspath(__file__))
build_dir = os.path.join(os.path.dirname(cur_dir), "build")
config_dir = os.path.join(os.path.dirname(cur_dir), "config")

matlab_domain_name_map = {
    "time": "time_domain_impulse",
    "freq": "complex_sinusoid"
}

matlab_dtype_lookup = {
    np.float32: "single",
    np.float64: "double"
}

meta_data_file_name = "meta.json"


def _run_cmd(cmd_str, log_file_path=None):

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


def generate_test_vector(domain_name,
                         header_template: str = None,
                         output_file_name: str = None,
                         output_dir: str = "./",
                         n_pol: int = 1,
                         backend="matlab") -> typing.Callable:


    if header_template is None:
        header_template = os.path.join(config_dir, "default_header.json")

    if backend == "matlab":
        matlab_handler_name = matlab_domain_name_map[domain_name]
        matlab_cmd_str = "generate_test_vector"

        def _generate_test_vector(n_bins, *args):
            """
            Sample command line use of Matlab `generate_test_vector`:
            ```
            generate_test_vector complex_sinusoid 1000 0.01,0.5,0.1 single 1 \
                config/default_header.json single_channel.dump ./ 1
            ```
            """
            _output_file_name = output_file_name
            list_args = list(args)
            dtype = matlab_dtype_lookup[list_args.pop(-1)]
            args_str = ",".join([f"{f:.3f}" for f in list_args])
            output_base = (f"{matlab_handler_name}.{n_bins}"
                           f".{'-'.join(args_str.split(','))}.{dtype}")
            output_base, log_file_name, _output_file_name = \
                _create_output_file_names(_output_file_name, output_base)
            cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                       f"{matlab_handler_name} {n_bins} "
                       f"{args_str} {dtype} {n_pol} "
                       f"{header_template} {_output_file_name} {output_dir} 1")

            module_logger.debug(f"_generate_test_vector: cmd_str={cmd_str}")

            _run_cmd(cmd_str, log_file_path=os.path.join(
                output_dir, log_file_name))

            return os.path.join(output_dir, output_file_name)

    elif backend == "python":
        def _generate_test_vector(n_bins, *args):
            raise NotImplementedError(("generate_test_vector not "
                                       "implemented in Python"))

    return _generate_test_vector


def channelize(output_file_name: str = None,
               output_dir: str = "./",
               backend="matlab"):

    if backend == "matlab":
        matlab_cmd_str = "channelize"

        def _channelize(input_data_file_path,
                        channels, os_factor_str, fir_filter_path):
            """
            ./build/channelize single_channel.dump 8 8/7 \
                config/OS_Prototype_FIR_8.mat channelized_data.dump ./ 1
            """
            _output_file_name = output_file_name
            output_base = (f"{matlab_cmd_str}.{channels}."
                           f"{'-'.join(os_factor_str.split('/'))}")

            output_base, log_file_name, _output_file_name = \
                _create_output_file_names(_output_file_name, output_base)

            cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                       f"{input_data_file_path} "
                       f"{channels} {os_factor_str} {fir_filter_path}"
                       f"{_output_file_name} {output_dir} 1")
            module_logger.debug(f"_synthesize: cmd_str={cmd_str}")

            _run_cmd(cmd_str, log_file_path=os.path.join(
                output_dir, log_file_name))
            return os.path.join(output_dir, output_file_name)

    elif backend == "python":
        def _channelize(channels, os_factor_str, fir_filter_path):
            raise NotImplementedError(("channelize not "
                                       "implemented in Python"))

    return _channelize


def synthesize(output_file_name: str = None,
               output_dir: str = "./",
               backend="matlab"):
    if backend == "matlab":
        matlab_cmd_str = "synthesize"

        def _synthesize(input_data_file_path, input_fft_length):
            """
            ./build/synthesize \
                channelized_data.dump \
                16384 test_synthesis.dump ./ 1
            """
            _output_file_name = output_file_name
            output_base = (f"{matlab_cmd_str}.{input_fft_length}."
                           f"{'-'.join(os_factor_str.split('/'))}")

            output_base, log_file_name, output_file_name = \
                _create_output_file_names(_output_file_name, output_base)

            cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                       f"{input_data_file_path} "
                       f"{input_fft_length}"
                       f"{_output_file_name} {output_dir} 1")
            module_logger.debug(f"_synthesize: cmd_str={cmd_str}")

            _run_cmd(cmd_str, log_file_path=os.path.join(
                output_dir, log_file_name))
            return os.path.join(output_dir, output_file_name)

    elif backend == "python":
        def _synthesize(input_fft_length):
            raise NotImplementedError(("synthesize not "
                                       "implemented in Python"))

    return _synthesize


def coro(fn):

    def _coro(*args, **kwargs):
        ret = fn(*args, **kwargs)
        next(ret)
        return ret

    return _coro


class DataVectorProducer:

    """
    Usage:

    .. code-block:: python

        prod = DataVectorProducer(
            "./../data/test_vectors", "time", {"offset": 1.0, "width": 1.0})
        if prod.meta_data is None:
            # two polarizations, 1000 data points, single precision
            # note that the other params are already provided!
            prod.send(2, 1000, np.float32)
            # 8 channel channelization, 8/7 oversampling, FIR coefficient file
            prod.send(8, "8/7", "./../config/OS_Prototype_FIR_8.mat")
            # size of forward fft for inverse PFB
            prod.send(1024)
        meta_data = prod.meta_data

    """

    sub_dir_format_map = {
        "time": "o-{offset:.3f}_w-{width:.3f}",
        "freq": "f-{frequency:.3f}_b-{bin_offset:.3f}_p-{phase:.3f}"
    }

    domain_param_order = {
        "time": ("offset", "width"),
        "freq": ("frequency", "phase", "bin_offset")
    }

    def __init__(self, base_dir, domain_name, params):

        self.meta_data = None
        self.base_dir = base_dir
        self.domain_name = domain_name
        self.params = params
        self.sink = self.data_vector_producer()

    @coro
    def data_vector_producer(self):
        """
        """
        sub_dir_formatter = self.sub_dir_format_map[self.domain_name]
        sub_dir = sub_dir_formatter.format(**self.params)

        sub_dir_full = os.path.join(self.base_dir, self.domain_name, sub_dir)

        if os.path.exists(sub_dir_full):
            meta_data_file_path = os.path.join(sub_dir, meta_data_file_name)
            with open(meta_data_file_path, 'r') as f:
                meta_data = json.load(f)
            self.meta_data = meta_data
        else:
            # we have to create the requested data files
            os.makedirs(sub_dir_full)
            output_dir = sub_dir_full

            meta_data = self.params.copy()

            test_vector_args = (yield)
            f = generate_test_vector(
                self.domain_name, output_dir=output_dir,
                n_pol=test_vector_args[0])
            vector_params = [self.params[p] for
                             p in self.domain_param_order[self.domain_name]]
            test_vector_args = list(test_vector_args)
            test_vector_args.pop(0)
            for i, v in enumerate(vector_params):
                test_vector_args.insert(i+1, v)

            input_file_path = f(*test_vector_args)

            f = channelize(output_dir=output_dir)
            channelized_args = (yield)
            synthesized_args = (input_file_path, ) + channelized_args
            channelized_file_path = f(*channelized_args)

            synthesized_args = (yield)
            synthesized_args = (channelized_file_path, ) + synthesized_args
            synthesized_file_path = f(*synthesized_args)

            meta_data["input_file"] = os.path.basename(
                input_file_path)
            meta_data["channelized_file"] = os.path.basename(
                channelized_file_path)
            meta_data["inverted_file"] = os.path.basename(
                synthesized_file_path)

            self.meta_data = meta_data

    def send(self, *args):
        self.sink.send(args)
