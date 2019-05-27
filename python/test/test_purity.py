import unittest
import logging
import os
import functools
import json
import glob

from tqdm import tqdm
import numpy as np
import pfb.rational
import psr_formats
import comparator

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


def spurious(a):
    b = a.copy()
    b[np.argmax(b)] = 0.0
    return b


def dB(a):
    return 10.0*np.log10(np.abs(a.copy()) + 1e-13)


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


class TestPurity(unittest.TestCase):
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
    def setUpClass(cls):
        os_factor = pfb.rational.Rational.from_str(
            data_gen.config["os_factor"])
        normalize = data_gen.config["input_fft_length"] *\
            data_gen.config["channels"]
        block_size = (
            os_factor.normalize(data_gen.config["input_fft_length"]) *
            data_gen.config["channels"])
        n_samples = block_size * data_gen.config["blocks"]
        output_sample_shift = (
            os_factor.normalize(data_gen.config["input_overlap"]) *
            data_gen.config["channels"])
        total_sample_shift = (
            output_sample_shift +
            (data_gen.config["fir_filter_taps"] - 1) // 2)

        if n_test == 1:
            cls.time_domain_args["offset"] = [10 + total_sample_shift]
            cls.freq_domain_args["frequency"] = [1*data_gen.config["blocks"]]
        else:
            cls.time_domain_args["offset"] = (
                np.linspace(1, n_samples, n_test).astype(int))
            cls.freq_domain_args["frequency"] = (
                np.linspace(1, block_size, n_test).astype(int)
            ) * data_gen.config["blocks"]

        cls.block_size = block_size
        cls.fft_size = 2*block_size
        cls.os_factor = os_factor
        cls.normalize = normalize
        cls.n_samples = n_samples
        cls.output_sample_shift = output_sample_shift
        cls.total_sample_shift = total_sample_shift
        cls.generator = functools.partial(
            data_gen.generate_test_vector,
            backend=data_gen.config["backend"]["test_vectors"])
        cls.channelizer = data_gen.channelize(
            backend=data_gen.config["backend"]["channelize"])
        cls.pipeline = data_gen.pipeline(
            cls.generator,
            cls.channelizer,
            lambda a, **kwargs: a,
            output_dir=cls.output_dir
        )
        deripple_str = "-dr" if data_gen.config["deripple"] else ""
        cls.synthesizer = functools.partial(
            data_gen.run_dspsr_with_dump,
            dm=data_gen.config["dm"],
            period=data_gen.config["period"],
            output_dir=cls.output_dir,
            dump_stage=data_gen.config["dump_stage"],
            extra_args=(f"-IF 1:{data_gen.config['input_fft_length']}:"
                        f"{data_gen.config['input_overlap']} "
                        f"{deripple_str} "
                        f"-fft-window {data_gen.config['fft_window']} -V")
        )
        # synthesizer = functools.partial(
        #     data_gen.synthesize,
        #     deripple=data_gen.config["deripple"],
        #     backend=data_gen.config["backend"]["synthesize"],
        #     fft_window_str=data_gen.config["fft_window"])
        # cls.synthesizer = lambda a: [synthesizer(a)]
        comp = comparator.MultiDomainComparator(domains={
            "time": comparator.SingleDomainComparator("time"),
            "freq": comparator.FrequencyDomainComparator("freq")
        })
        comp.freq.domain = [0, cls.fft_size]
        comp.operators["this"] = lambda a: a
        comp.operators["diff"] = lambda a, b: a - b

        comp.products["mean"] = lambda a: np.mean(np.abs(a))
        comp.products["sum"] = lambda a: np.sum(np.abs(a))
        comp.products["max"] = lambda a: np.amax(np.abs(a))

        comp.products["total_spurious"] = total_spurious
        comp.products["mean_spurious"] = mean_spurious
        comp.products["max_spurious"] = max_spurious

        cls.comp = comp
        cls.report = {}
        cls.files = []

    def chop(self, input_dump_file, inverted_dump_file):
        input_dat = input_dump_file.data.flatten()
        inverted_dat = inverted_dump_file.data.flatten()
        inverted_dat /= self.normalize

        return input_dat, inverted_dat

    # class TestVectorGenerator:
    #
    #     def __call__(self,
    #                  method_name,
    #                  test_data_func,
    #                  test_args,
    #                  plot_func):
    #
    #         sub_report = []
    #
    #         for arg in tqdm(test_args, desc=method_name):
    #             dump_files = test_data_func(arg)
    #             dump_files = self.__class__.pipeline(
    #                 "freq", self.n_samples, freq, *args)
    #             inverted_dump = self.__class__.synthesizer(dump_files[1].file_path)
    #             inverted_dump = inverted_dump[0]
    #
    #             input_dat, inverted_dat = self.chop(
    #                 dump_files[0], inverted_dump)
    #             input_dat = input_dat[self.total_sample_shift:]
    #             res_op_time, res_prod_time = self.comp.time(
    #                 input_dat, inverted_dat
    #             )
    #
    #             res_op_freq, res_prod_freq = self.comp.freq(
    #                 input_dat/self.fft_size, inverted_dat/self.fft_size
    #             )
    #             if make_plots:
    #                 fig, axes = plot_func(res_op_time, res_op_freq)
    #                 yield (fig, axes)
    #                 # fig, axes = test_util.plot_freq_domain_comparison(
    #                 #     res_op_time, res_op_freq,
    #                 #     subplots_kwargs=dict(figsize=(10, 14)),
    #                 #     labels=["Input data", "InverseFilterbank"])
    #                 # hz = int(freq)
    #                 # fig.suptitle(f"Complex Sinusoid {hz} Hz")
    #                 # fig.tight_layout(rect=[0, 0.03, 1, 0.95])
    #                 # fig.savefig(os.path.join(products_dir, f"complex_sinuoid.{hz}.png"))
    #
    #             prod_diff = res_prod_time["diff"][1, 0]
    #             prod_this = res_prod_freq["this"][1]
    #
    #             sub_report.append({
    #                 "freq": freq,
    #                 "mean_diff": prod_diff["mean"],
    #                 "total_diff": prod_diff["sum"],
    #                 "max_spurious_power": prod_this["max_spurious"],
    #                 "total_spurious_power": prod_this["total_spurious"],
    #                 "mean_spurious_power": prod_this["mean_spurious"]
    #             })
    #             self.__class__.files.extend(dump_files)
    #             self.__class__.files.append(inverted_dump)
    #
    #             # print(res_prod_freq["this"])
    #             # print(sub_report[-1])
    #
    #         self.__class__.report[method_name] = sub_report

    # @unittest.skip("")
    def test_time_domain_impulse(self):
        sub_report = []
        args = (self.time_domain_args["width"], )
        for offset in tqdm(self.time_domain_args["offset"], desc="test_time_domain_impulse"):
            dump_files = self.__class__.pipeline(
                "time", self.n_samples, offset, *args)
            inverted_dump = self.__class__.synthesizer(dump_files[1].file_path)
            inverted_dump = inverted_dump[0]

            input_dat, inverted_dat = self.chop(
                dump_files[0], inverted_dump)
            input_dat = input_dat[self.total_sample_shift:]
            res_op, res_prod = self.comp.time(
                input_dat, inverted_dat
            )
            if make_plots:
                fig, axes = test_util.plot_time_domain_comparison(
                    res_op,
                    subplots_kwargs=dict(figsize=(10, 10)),
                    labels=["Input data", "InverseFilterbank"])
                pos = int(offset)
                fig.suptitle(f"Time domain impulse at {pos}")
                fig.tight_layout(rect=[0, 0.03, 1, 0.95])
                fig.savefig(os.path.join(products_dir,
                                         f"time_domain_impulse.{pos}.png"))

            prod_diff = res_prod["diff"][1, 0]
            prod_this = res_prod["this"][1]

            sub_report.append({
                "offset": offset,
                "mean_diff": prod_diff["mean"],
                "total_diff": prod_diff["sum"],
                "max_spurious_power": prod_this["max_spurious"],
                "total_spurious_power": prod_this["total_spurious"],
                "mean_spurious_power": prod_this["mean_spurious"]
            })
            self.__class__.files.extend(dump_files)
            self.__class__.files.append(inverted_dump)


        self.__class__.report["test_time_domain_impulse"] = sub_report

    # @unittest.skip("")
    def test_complex_sinusoid(self):
        sub_report = []

        args = (self.freq_domain_args["phase"],
                self.freq_domain_args["bin_offset"])

        for freq in tqdm(self.freq_domain_args["frequency"], desc="test_complex_sinusoid"):
            dump_files = self.__class__.pipeline(
                "freq", self.n_samples, freq, *args)
            inverted_dump = self.__class__.synthesizer(dump_files[1].file_path)
            inverted_dump = inverted_dump[0]

            input_dat, inverted_dat = self.chop(
                dump_files[0], inverted_dump)
            input_dat = input_dat[self.total_sample_shift:]
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
                hz = int(freq)
                fig.suptitle(f"Complex Sinusoid {hz} Hz")
                fig.tight_layout(rect=[0, 0.03, 1, 0.95])
                fig.savefig(os.path.join(products_dir, f"complex_sinuoid.{hz}.png"))

            prod_diff = res_prod_time["diff"][1, 0]
            prod_this = res_prod_freq["this"][1]

            sub_report.append({
                "freq": freq,
                "mean_diff": prod_diff["mean"],
                "total_diff": prod_diff["sum"],
                "max_spurious_power": prod_this["max_spurious"],
                "total_spurious_power": prod_this["total_spurious"],
                "mean_spurious_power": prod_this["mean_spurious"]
            })
            self.__class__.files.extend(dump_files)
            self.__class__.files.append(inverted_dump)

            # print(res_prod_freq["this"])
            # print(sub_report[-1])

        self.__class__.report["test_complex_sinusoid"] = sub_report

    @unittest.skip("")
    def test_simulated_pulsar(self):
        """
        Determine whether dspsr and matlab produce the same result when
        inverting simulated pulsar data.
        """
        sub_report = []
        sim_psr_pipeline = data_gen.pipeline(
            lambda a, **kwargs: psr_formats.DADAFile(a).load_data(),
            self.__class__.channelizer,
            self.__class__.synthesizer,
            output_dir=self.output_dir
        )

        dada_files = sim_psr_pipeline(self.simulated_pulsar_file_path)
        dspsr_dump = self.dspsr_dumper(dada_files[1].file_path)[0]
        res_op, res_prod, mean_diff, sum_diff = self.compare_dump_files(
            dada_files[-1], dspsr_dump
        )
        prod_str = f"{res_prod['isclose']:.6e}"
        module_logger.info((f"test_simulated_pulsar: \n"
                            f"{prod_str}"))
        sub_report.append({
            "mean": mean_diff,
            "sum": sum_diff,
            "str": prod_str
        })
        self.__class__.report["test_simulated_pulsar"] = sub_report

    @classmethod
    def tearDownClass(cls):
        with open(os.path.join(products_dir, "report.purity.json"), "w") as f:
            json.dump(cls.report, f, cls=comparator.NumpyEncoder)

        for file_path in cls.files:
            if hasattr(file_path, "file_path"):
                file_path = file_path.file_path
            if os.path.exists(file_path):
                os.remove(file_path)
        for file_path in glob.glob(os.path.join(data_dir, "channelized.*")):
            os.remove(file_path)


if __name__ == "__main__":
    logging.basicConfig(level=logging.ERROR)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    unittest.main()
