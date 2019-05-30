import unittest
import logging
import os
import functools
import json
import glob
import typing

import numpy as np
import comparator
import partialize
from pfb.rational import Rational
from tqdm import tqdm

import data_gen
import data_gen.util
from data_gen.config import matplotlib_config

from . import util as test_util

matplotlib_config()

module_logger = logging.getLogger(__name__)

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")
products_dir = os.path.join(base_dir, "products")

make_plots = False
n_test = 100
if n_test == 1:
    make_plots = True


@partialize.partialize
def purity_test_case_factory(
    test_case_name: str = "TestPurity",
    *,
    os_factor: typing.Union[Rational, str],
    input_fft_length: int,
    input_overlap: int,
    fft_window: str,
    deripple: bool,
    channels: int,
    fir_filter_taps: int,
    fir_filter_coeff_file_path: str,
    blocks: int,
    backend: dict,
    dump_stage: str,
    dm: float,
    period: float
) -> unittest.TestCase:
    """
    Create a test case for a given set of PFB inversion parameters.
    """
    os_factor = Rational.from_str(os_factor)

    class _TestPurity(unittest.TestCase):
        """
        These tests attempt to determine whether the PFB inversion algorithm
        as implemented in the PST Matlab model and dspsr do the same thing,
        within the limits of 32-bit float point accuracy.

        Note that offsets and frequencies are expressed as fractions of total
        size of input array.
        """
        thresh = 1e-7
        output_dir = data_dir

        simulated_pulsar_file_path = os.path.join(
            data_dir, "simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump"
        )

        time_domain_args = {
            "width": 1
        }

        freq_domain_args = {
            "phase": np.pi/4,
            "bin_offset": 0.0
        }

        @classmethod
        def init(cls):
            normalize = input_fft_length * channels
            block_size = os_factor.normalize(input_fft_length) * channels

            fft_size = 2*block_size
            n_samples = block_size * blocks
            output_sample_shift = os_factor.normalize(input_overlap) * channels
            total_sample_shift = (
                output_sample_shift + (fir_filter_taps - 1) // 2)

            if n_test == 1:
                cls.time_domain_args["offset"] = [10 + total_sample_shift]
                # cls.freq_domain_args["frequency"] = [1*blocks]
                cls.freq_domain_args["frequency"] = [137859]
            else:
                cls.time_domain_args["offset"] = (
                    np.linspace(1, n_samples, n_test).astype(int))
                # cls.freq_domain_args["frequency"] = (
                #     np.arange(1, block_size, int(block_size/n_test)) *
                #     blocks).astype(int)
                cls.freq_domain_args["frequency"] = (
                    np.linspace(1, block_size, n_test).astype(int) *
                    blocks
                )

            cls.block_size = block_size
            cls.fft_size = fft_size
            cls.os_factor = os_factor
            cls.normalize = normalize
            cls.n_samples = n_samples
            cls.output_sample_shift = output_sample_shift
            cls.total_sample_shift = total_sample_shift
            cls.generator = data_gen.generate_test_vector(
                backend=backend["test_vectors"],
                n_bins=cls.n_samples
            )
            cls.channelizer = data_gen.channelize(
                backend=backend["channelize"])
            cls.pipeline = data_gen.pipeline(
                cls.generator,
                cls.channelizer,
                lambda a, **kwargs: a,
                output_dir=cls.output_dir
            )
            deripple_str = "-dr" if deripple else ""
            cls.synthesizer = functools.partial(
                data_gen.run_dspsr_with_dump,
                dm=dm,
                period=period,
                output_dir=cls.output_dir,
                dump_stage=dump_stage,
                extra_args=(f"-IF 1:{input_fft_length}:"
                            f"{input_overlap} "
                            f"{deripple_str} "
                            f"-fft-window {fft_window} -V")
            )
            synthesizer = functools.partial(
                data_gen.synthesize,
                deripple=deripple,
                backend=backend["synthesize"],
                fft_window_str=fft_window)
            cls.synthesizer = lambda a: [synthesizer(a)]
            comp = comparator.MultiDomainComparator(domains={
                "time": comparator.SingleDomainComparator("time"),
                "freq": comparator.FrequencyDomainComparator("freq")
            })
            # comp.time.domain = [99000, 130000]
            comp.freq.domain = [0, cls.fft_size]
            comp.operators["this"] = lambda a: a
            comp.operators["diff"] = lambda a, b: a - b

            comp.products["mean"] = lambda a: np.mean(np.abs(a))
            comp.products["sum"] = lambda a: np.sum(np.abs(a))
            comp.products["max"] = lambda a: np.amax(np.abs(a))

            comp.products["total_spurious"] = test_util.total_spurious
            comp.products["mean_spurious"] = test_util.mean_spurious
            comp.products["max_spurious"] = test_util.max_spurious

            cls.comp = comp
            cls.report = {}

            cls.register_test_methods()

        @classmethod
        def register_test_methods(cls):

            def test_method_factory(
                *,
                test_vector_func: callable,
                test_vector_args: typing.Union[tuple, list],
                test_method_name: str,
                report_func: callable,
            ):

                def _test_method(self):

                    method_report = []
                    for arg in tqdm(test_vector_args, desc=test_method_name):
                        dump_files = test_vector_func(arg)
                        inverted_dump = self.__class__.synthesizer(
                            dump_files[1].file_path)
                        inverted_dump = inverted_dump[0]

                        input_dat, inverted_dat = self.chop(
                            dump_files[0], inverted_dump)
                        res_op_time, res_prod_time = self.comp.time(
                            input_dat, inverted_dat
                        )

                        res_op_freq, res_prod_freq = self.comp.freq(
                            input_dat/self.fft_size, inverted_dat/self.fft_size
                        )

                        if make_plots:
                            fig, axes = test_util.plot_freq_domain_comparison(
                                res_op_time, res_op_freq,
                                subplots_kwargs=dict(figsize=(10, 14)),
                                labels=["Input data", "InverseFilterbank"])
                            fig.suptitle(f"{test_method_name} {arg}")
                            fig.tight_layout(rect=[0, 0.03, 1, 0.95])
                            fig.savefig(os.path.join(
                                products_dir, f"{test_method_name}.{arg}.png"))

                        sub_report = report_func(res_prod_time, res_prod_freq)
                        sub_report["arg"] = arg
                        method_report.append(sub_report)

                        self.files.extend(dump_files)
                        self.files.append(inverted_dump)
                        self.dispose()
                        self.__class__.report[test_method_name] = method_report

                _test_method.__name__ = test_method_name
                return _test_method

            time_domain_args = (cls.time_domain_args["width"],)
            time_domain_test_vector_func = data_gen.util.rpartial(
                functools.partial(cls.pipeline, domain_name="time"),
                *time_domain_args)
            time_domain_test_method_name = "test_time_domain_impulse"

            def time_domain_report_func(res_prod_time, res_prod_freq):
                prod_diff = res_prod_time["diff"][1, 0]
                prod_this = res_prod_time["this"][1]

                return {
                    "mean_diff": prod_diff["mean"],
                    "total_diff": prod_diff["sum"],
                    "max_spurious_power": prod_this["max_spurious"],
                    "total_spurious_power": prod_this["total_spurious"],
                    "mean_spurious_power": prod_this["mean_spurious"]
                }

            setattr(cls, time_domain_test_method_name, test_method_factory(
                test_vector_func=time_domain_test_vector_func,
                test_vector_args=cls.time_domain_args["offset"],
                test_method_name=time_domain_test_method_name,
                report_func=time_domain_report_func
            ))

            freq_domain_args = (cls.freq_domain_args["phase"],
                                cls.freq_domain_args["bin_offset"])
            freq_domain_test_vector_func = data_gen.util.rpartial(
                functools.partial(cls.pipeline, domain_name="freq"),
                *freq_domain_args)
            freq_domain_test_method_name = "test_complex_sinusoid"

            def freq_domain_report_func(res_prod_time, res_prod_freq):
                prod_diff = res_prod_time["diff"][1, 0]
                prod_this = res_prod_freq["this"][1]

                return {
                    "mean_diff": prod_diff["mean"],
                    "total_diff": prod_diff["sum"],
                    "max_spurious_power": prod_this["max_spurious"],
                    "total_spurious_power": prod_this["total_spurious"],
                    "mean_spurious_power": prod_this["mean_spurious"]
                }

            setattr(cls, freq_domain_test_method_name, test_method_factory(
                test_vector_func=freq_domain_test_vector_func,
                test_vector_args=cls.freq_domain_args["frequency"],
                test_method_name=freq_domain_test_method_name,
                report_func=freq_domain_report_func
            ))

        def setUp(self):
            self.files = []

        def dispose(self):
            for file_path in self.files:
                if hasattr(file_path, "file_path"):
                    file_path = file_path.file_path
                if os.path.exists(file_path):
                    os.remove(file_path)
            for file_path in glob.glob(
                os.path.join(data_dir, "channelized.*")
            ):
                os.remove(file_path)

        def chop(self, input_dump_file, inverted_dump_file):
            input_dat = (input_dump_file.data[self.total_sample_shift:, 0, :]
                         .flatten())
            inverted_dat = inverted_dump_file.data.flatten()
            # inverted_dat /= self.normalize

            return input_dat, inverted_dat

        @classmethod
        def tearDownClass(cls):
            param_str = ".".join([
                f"fft_length-{input_fft_length}",
                f"deripple-{1 if deripple else 0}",
                f"fft_window-{fft_window}",
                f"input_overlap-{input_overlap}"
            ])
            param_path = os.path.join(
                products_dir, f"report.purity.{param_str}.json")
            with open(param_path, "w") as f:
                json.dump(cls.report, f, cls=comparator.NumpyEncoder)

    _TestPurity.__name__ = test_case_name
    _TestPurity.init()
    return _TestPurity


TestPurity = purity_test_case_factory(
    test_case_name="TestPurity",
    os_factor=data_gen.config["os_factor"],
    input_fft_length=data_gen.config["input_fft_length"],
    input_overlap=data_gen.config["input_overlap"],
    fft_window=data_gen.config["fft_window"],
    deripple=data_gen.config["deripple"],
    channels=data_gen.config["channels"],
    fir_filter_taps=data_gen.config["fir_filter_taps"],
    fir_filter_coeff_file_path=data_gen.config["fir_filter_coeff_file_path"],
    blocks=data_gen.config["blocks"],
    backend=data_gen.config["backend"],
    dump_stage=data_gen.config["dump_stage"],
    dm=data_gen.config["dm"],
    period=data_gen.config["period"]
)

if __name__ == "__main__":
    logging.basicConfig(level=logging.ERROR)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    unittest.main()
