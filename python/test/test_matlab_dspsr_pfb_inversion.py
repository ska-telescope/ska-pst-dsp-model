import unittest
import logging
import os
import functools
import json
# import sys
#
# sys.path.insert(0, "/home/SWIN/dshaff/ska/comparator")

import numpy as np
import pfb.rational
import psr_formats
import comparator

import data_gen
import data_gen.util
from data_gen.config import matplotlib_config

module_logger = logging.getLogger(__name__)

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")
products_dir = os.path.join(base_dir, "products")

matplotlib_config()


class TestMatlabDspsrPfbInversion(unittest.TestCase):
    """
    These tests attempt to determine whether the PFB inversion algorithm
    as implemented in the PST Matlab model and dspsr do the same thing,
    within the limits of 32-bit float point accuracy.
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
        n_samples = os_factor.normalize(data_gen.config["input_fft_length"]) *\
            data_gen.config["channels"] * data_gen.config["blocks"]

        output_sample_shift = (
            os_factor.normalize(data_gen.config["input_overlap"]) *
            data_gen.config["channels"])
        total_sample_shift = (
            output_sample_shift +
            (data_gen.config["fir_filter_taps"] - 1) // 2)

        cls.time_domain_args["offset"] = [total_sample_shift + 100]
        cls.freq_domain_args["frequency"] = [377475]

        cls.normalize = normalize
        cls.n_samples = n_samples
        cls.generator = functools.partial(
            data_gen.generate_test_vector,
            backend=data_gen.config["backend"]["test_vectors"])
        cls.channelizer = data_gen.channelize(
            backend=data_gen.config["backend"]["channelize"])
        cls.synthesizer = functools.partial(
            data_gen.synthesize,
            deripple=data_gen.config["deripple"],
            backend=data_gen.config["backend"]["synthesize"],
            fft_window_str=data_gen.config["fft_window"])
        cls.pipeline = data_gen.pipeline(
            cls.generator,
            cls.channelizer,
            cls.synthesizer,
            output_dir=cls.output_dir
        )
        deripple_str = "-dr" if data_gen.config["deripple"] else ""
        cls.dspsr_dumper = functools.partial(
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
        comp = comparator.SingleDomainComparator(name="time")
        comp.operators["this"] = lambda a: a
        comp.operators["diff"] = lambda a, b: a - b
        # isclose returns an array of booleans;
        # the imaginary component is always zero.
        comp.operators["isclose"] = lambda a, b: np.isclose(
            a, b, atol=cls.thresh)

        comp.products["sum"] = lambda a: np.sum(a)
        comp.products["mean"] = lambda a: np.mean(a)

        cls.comp = comp
        cls.report = {}

    def compare_dump_files(self, matlab_dump_file, dspsr_dump_file):
        matlab_dat = matlab_dump_file.data.flatten()
        dspsr_dat = dspsr_dump_file.data.flatten() / self.normalize

        self.assertTrue(matlab_dat.shape[0] == dspsr_dat.shape[0])

        res_op, res_prod = self.comp(matlab_dat, dspsr_dat)
        isclose_prod = res_prod["isclose"][0][1]
        mean_diff = isclose_prod["mean"]
        sum_diff = isclose_prod["sum"]
        return res_op, res_prod, mean_diff, sum_diff

    # @unittest.skip("")
    def test_time_domain_impulse(self):
        sub_report = []
        args = (self.time_domain_args["width"], )
        for offset in self.time_domain_args["offset"]:
            dada_files = self.__class__.pipeline(
                "time", self.n_samples, offset, *args)
            dspsr_dump = self.__class__.dspsr_dumper(
                dada_files[1].file_path)
            dspsr_dump = dspsr_dump[0]

            res_op, res_prod, mean_diff, sum_diff = self.compare_dump_files(
                dada_files[-1], dspsr_dump)

            figs, axes = comparator.plot_operator_result(
                res_op, figsize=(10, 10), corner_plot=True)
            for op in ["this", "diff"]:
                figs[op].suptitle(
                    f"{op}: Time offset {int(offset)}")
                figs[op].savefig(
                    os.path.join(products_dir, f"matlab_dspsr.time.{op}.{offset}.png"))

            prod_str = f"{res_prod['isclose']:.6e}"

            sub_report.append({
                "offset": offset,
                "mean": mean_diff,
                "sum": sum_diff,
                "str": prod_str
            })

            module_logger.info((f"test_time_domain_impulse: "
                                f"offset={offset}\n"
                                f"{prod_str}"))

            self.assertTrue(mean_diff == 1.0)
        self.__class__.report["test_time_domain_impulse"] = sub_report

    def test_complex_sinusoid(self):
        sub_report = []
        args = (self.freq_domain_args["phase"],
                self.freq_domain_args["bin_offset"])
        for freq in self.freq_domain_args["frequency"]:
            dada_files = self.__class__.pipeline(
                "freq", self.n_samples, freq, *args)
            dspsr_dump = self.__class__.dspsr_dumper(
                dada_files[1].file_path)[0]

            res_op, res_prod, mean_diff, sum_diff = self.compare_dump_files(
                dada_files[-1], dspsr_dump)

            figs, axes = comparator.plot_operator_result(
                res_op, figsize=(10, 10), corner_plot=True)
            for op in ["this", "diff"]:
                figs[op].suptitle(
                    f"{op}: Frequency {int(freq)} Hz")
                figs[op].savefig(
                    os.path.join(products_dir, f"matlab_dspsr.freq.{op}.{freq}.png"))

            prod_str = f"{res_prod['isclose']:.6e}"

            sub_report.append({
                "freq": freq,
                "mean": mean_diff,
                "sum": sum_diff,
                "str": prod_str
            })
            module_logger.info((f"test_complex_sinusoid: "
                                f"freq={freq}\n"
                                f"{prod_str}"))
            self.assertTrue(mean_diff == 1.0)

        self.__class__.report["test_complex_sinusoid"] = sub_report

    # @unittest.skip("")
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

        figs, axes = comparator.plot_operator_result(
            res_op, figsize=(10, 10), corner_plot=True)

        for op in ["this", "diff"]:
            figs[op].suptitle(
                f"{op}: Simulated Pulsar")
            figs[op].savefig(
                os.path.join(products_dir, f"matlab_dspsr.simulated_pulsar.{op}.png"))

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
        with open(os.path.join(products_dir, "report.matlab_dspsr.json"),
                  "w") as f:
            json.dump(cls.report, f, cls=comparator.NumpyEncoder)


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    unittest.main()
