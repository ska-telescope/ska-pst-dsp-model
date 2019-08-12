import logging
import os
import functools
import json
import glob
import typing
import argparse

import numpy as np
import comparator
import pfb.rational
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


class TestPurity:

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

    def __init__(self,
                 n_test: int,
                 dspsr_bin: str,
                 os_factor: typing.Union[pfb.rational.Rational, str],
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
                 period: float):

        make_plots = False
        if n_test == 1:
            make_plots = True

        self.make_plots = make_plots
        self.input_fft_length = input_fft_length
        self.input_overlap = input_overlap
        self.deripple = deripple
        self.fft_window = fft_window

        os_factor = pfb.rational.Rational.from_str(os_factor)
        normalize = input_fft_length * channels
        block_size = os_factor.normalize(input_fft_length) * channels

        fft_size = 2*block_size
        n_samples = block_size * blocks
        output_sample_shift = os_factor.normalize(input_overlap) * channels
        total_sample_shift = (
            output_sample_shift + (fir_filter_taps - 1) // 2)

        if n_test == 1:
            self.time_domain_args["offset"] = [10 + total_sample_shift]
            self.freq_domain_args["frequency"] = [1*blocks]
        else:
            self.time_domain_args["offset"] = (
                np.linspace(1, n_samples, n_test).astype(int))
            self.freq_domain_args["frequency"] = (
                np.linspace(1, block_size, n_test).astype(int) *
                blocks
            )

        self.block_size = block_size
        self.fft_size = fft_size
        self.os_factor = os_factor
        self.normalize = normalize
        self.n_samples = n_samples
        self.output_sample_shift = output_sample_shift
        self.total_sample_shift = total_sample_shift
        self.generator = data_gen.generate_test_vector(
            backend=backend["test_vectors"],
            n_bins=self.n_samples
        )
        self.channelizer = data_gen.channelize(
            backend=backend["channelize"])
        self.pipeline = data_gen.pipeline(
            self.generator,
            self.channelizer,
            lambda a, **kwargs: a,
            output_dir=self.output_dir
        )
        deripple_str = "-dr" if deripple else ""

        if dspsr_bin is None:
            synthesizer = functools.partial(
                data_gen.synthesize,
                deripple=deripple,
                backend=backend["synthesize"],
                fft_window_str=fft_window)
            self.synthesizer = lambda a: [synthesizer(a)]
        else:
            self.synthesizer = functools.partial(
                data_gen.run_dspsr_with_dump,
                dspsr_bin=dspsr_bin,
                dm=dm,
                period=period,
                output_dir=self.output_dir,
                dump_stage=dump_stage,
                extra_args=(f"-IF 1:{self.input_fft_length}:"
                            f"{self.input_overlap} "
                            f"{deripple_str} "
                            f"-fft-window {self.fft_window} -V")
            )

        comp = comparator.MultiDomainComparator(domains={
            "time": comparator.SingleDomainComparator("time"),
            "freq": comparator.FrequencyDomainComparator("freq")
        })

        comp.freq.domain = [0, self.fft_size]
        comp.operators["this"] = lambda a: a
        comp.operators["diff"] = lambda a, b: a - b

        comp.products["mean"] = lambda a: np.mean(np.abs(a))
        comp.products["sum"] = lambda a: np.sum(np.abs(a))
        comp.products["max"] = lambda a: np.amax(np.abs(a))

        comp.products["total_spurious"] = test_util.total_spurious
        comp.products["mean_spurious"] = test_util.mean_spurious
        comp.products["max_spurious"] = test_util.max_spurious

        self.comp = comp
        self.report = {}

    def _test(self, *,
              test_vector_func: callable,
              test_vector_args: typing.Union[tuple, list],
              test_method_name: str,
              report_func: callable):

        self.files = []
        method_report = []
        for arg in tqdm(test_vector_args, desc=test_method_name):
            dump_files = test_vector_func(arg)
            inverted_dump = self.synthesizer(
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

            if self.make_plots:
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
            self.report[test_method_name] = method_report

    def temporal_purity(self):
        module_logger.debug("temporal_purity")
        time_domain_args = (self.time_domain_args["width"],)
        time_domain_test_vector_func = data_gen.util.rpartial(
            functools.partial(self.pipeline, domain_name="time"),
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

        self._test(
            test_vector_func=time_domain_test_vector_func,
            test_vector_args=self.time_domain_args["offset"],
            test_method_name=time_domain_test_method_name,
            report_func=time_domain_report_func
        )

    def spectral_purity(self):
        module_logger.debug("temporal_purity")

        freq_domain_args = (self.freq_domain_args["phase"],
                            self.freq_domain_args["bin_offset"])
        freq_domain_test_vector_func = data_gen.util.rpartial(
            functools.partial(self.pipeline, domain_name="freq"),
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

        self._test(
            test_vector_func=freq_domain_test_vector_func,
            test_vector_args=self.freq_domain_args["frequency"],
            test_method_name=freq_domain_test_method_name,
            report_func=freq_domain_report_func
        )

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

    def finish(self):
        param_str = ".".join([
            f"fft_length-{self.input_fft_length}",
            f"deripple-{1 if self.deripple else 0}",
            f"fft_window-{self.fft_window}",
            f"input_overlap-{self.input_overlap}"
        ])
        param_path = os.path.join(
            products_dir, f"report.purity.{param_str}.json")
        with open(param_path, "w") as f:
            json.dump(self.report, f, cls=comparator.NumpyEncoder)


def create_parser():

    parser = argparse.ArgumentParser(
        description="DSPSR PFB inversion purity")

    parser.add_argument("-t", "--do-time",
                        dest="do_time", action="store_true")

    parser.add_argument("-f", "--do-freq",
                        dest="do_freq", action="store_true")

    parser.add_argument("-n", "--n-test",
                        dest="n_test", action="store",
                        default=100, type=int,
                        help="Specify the number of test vectors to use")

    parser.add_argument("-v", "--verbose",
                        dest="verbose", action="store_true")

    return parser


if __name__ == "__main__":

    parsed = create_parser().parse_args()

    level = logging.INFO
    if parsed.verbose:
        level = logging.DEBUG

    logging.basicConfig(level=level)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    logging.getLogger("partialize").setLevel(logging.ERROR)
    logging.getLogger("comparator").setLevel(logging.ERROR)
    logging.getLogger("pfb").setLevel(logging.ERROR)
    logging.getLogger("psr_formats").setLevel(logging.ERROR)

    config = data_gen.config

    purity_test = TestPurity(
        dspsr_bin=config["dspsr_bin"],
        os_factor=config["os_factor"],
        input_fft_length=config["input_fft_length"],
        input_overlap=config["input_overlap"],
        fft_window=config["fft_window"],
        deripple=config["deripple"],
        channels=config["channels"],
        fir_filter_taps=config["fir_filter_taps"],
        fir_filter_coeff_file_path=config["fir_filter_coeff_file_path"],
        blocks=config["blocks"],
        backend=config["backend"],
        dump_stage=config["dump_stage"],
        dm=config["dm"],
        period=config["period"],
        n_test=parsed.n_test
    )

    if parsed.do_time:
        purity_test.temporal_purity()
    if parsed.do_freq:
        purity_test.spectral_purity()
