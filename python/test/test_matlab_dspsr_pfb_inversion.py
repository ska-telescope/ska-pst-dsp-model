import unittest
import logging
import os
import functools
import json

import numpy as np
import matplotlib.pyplot as plt
import pfb.rational
import psr_formats
import comparator

import data_gen
import data_gen.util

module_logger = logging.getLogger(__name__)

plt.ion()

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")
products_dir = os.path.join(base_dir, "products")


class TestMatlabDspsrPfbInversion(unittest.TestCase):
    """
    These tests attempt to determine whether the PFB inversion algorithm
    as implemented in the PST Matlab model and dspsr do the same thing,
    within the limits of 32-bit float point accuracy.

    Note that offsets and frequencies are expressed as fractions of total
    size of input array.
    """
    thresh = 1e-5
    output_dir = data_dir

    simulated_pulsar_file_path = os.path.join(
        data_dir, "simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump"
    )

    time_domain_args = {
        "offset": [0.11],
        # "offset": np.arange(1, 20)/20,
        "width": 1
    }

    freq_domain_args = {
        "frequency": [0.11],
        # "frequency": np.arange(1, 20)/20,
        "phase": np.pi/4,
        "bin_offset": 0.1
    }

    @classmethod
    def setUpClass(cls):
        os_factor = pfb.rational.Rational(
            *data_gen.config["os_factor"].split("/"))
        normalize = data_gen.config["input_fft_length"] *\
            data_gen.config["channels"]
        n_samples = os_factor.normalize(data_gen.config["input_fft_length"]) *\
            data_gen.config["channels"] * data_gen.config["blocks"]
        cls.normalize = normalize
        cls.n_samples = n_samples
        cls.generator = data_gen.generate_test_vector(
            backend=data_gen.config["backend"]["test_vectors"])
        cls.channelizer = data_gen.channelize(
            backend=data_gen.config["backend"]["channelize"])
        cls.synthesizer = data_gen.synthesize(
            backend=data_gen.config["backend"]["synthesize"])
        cls.pipeline = data_gen.pipeline(
            cls.generator,
            cls.channelizer,
            cls.synthesizer,
            output_dir=cls.output_dir
        )
        cls.dspsr_dumper = functools.partial(
            data_gen.run_dspsr_with_dump,
            dm=data_gen.config["dm"],
            period=data_gen.config["period"],
            output_dir=cls.output_dir,
            dump_stage=data_gen.config["dump_stage"],
            extra_args=f"-IF 1:{data_gen.config['input_fft_length']} -V"
        )
        comp = comparator.SingleDomainComparator(name="time")
        comp.operators["diff"] = lambda a, b: a - b
        comp.operators["this"] = lambda a: a

        comp.products["sum"] = lambda a: np.sum(np.abs(a))
        comp.products["mean"] = lambda a: np.mean(np.abs(a))

        cls.comp = comp
        cls.report = {}

    def compare_dump_files(self, matlab_dump_file, dspsr_dump_file):

        res_op, res_prod = self.comp.cartesian(
            matlab_dump_file.data.flatten(),
            dspsr_dump_file.data.flatten() / self.normalize
        )
        mean_diff = list(res_prod["diff"]["mean"])[0][1]
        sum_diff = list(res_prod["diff"]["sum"])[0][1]
        self.assertTrue(all([d < self.thresh for d in mean_diff]))
        return res_op, res_prod, mean_diff, sum_diff

    def test_time_domain_impulse(self):
        sub_report = []
        args = (self.time_domain_args["width"], )
        for offset in self.time_domain_args["offset"]:
            dada_files = self.__class__.pipeline(
                "time", self.n_samples, offset, *args)
            dspsr_dump = self.__class__.dspsr_dumper(
                dada_files[1].file_path)[0]

            res_op, res_prod, mean_diff, sum_diff = self.compare_dump_files(
                dada_files[-1], dspsr_dump)

            prod_str = f"{res_prod['diff']:.6e}"

            sub_report.append({
                "offset": offset,
                "mean": mean_diff,
                "sum": sum_diff,
                "str": prod_str
            })

            module_logger.info((f"test_time_domain_impulse: "
                                f"offset={offset}\n"
                                f"{prod_str}"))

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

            prod_str = f"{res_prod['diff']:.6e}"

            sub_report.append({
                "freq": freq,
                "mean": mean_diff,
                "sum": sum_diff,
                "str": prod_str
            })
            module_logger.info((f"test_complex_sinusoid: "
                                f"freq={freq}\n"
                                f"{prod_str}"))

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
        prod_str = f"{res_prod['diff']:.6e}"
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
        with open(os.path.join(products_dir, "report.json"), "w") as f:
            json.dump(cls.report, f)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    unittest.main()
