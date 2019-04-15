import unittest
import logging
import os

import numpy as np
import pfb.rational
import comparator

import util
from data_gen import generate_test_vector, channelize, synthesize
from run_dspsr_with_dump import run_dspsr_with_dump
from config import load_config

config = load_config()
test_dir = util.curdir(__file__)
base_dir = util.updir(test_dir, 2)
config_dir = os.path.join(base_dir, "config")
data_dir = os.path.join(base_dir, "data")


class TestMatlabDspsrPfbInversion(unittest.TestCase):
    """
    These tests attempt to determine whether the PFB inversion algorithm
    as implemented in the PST Matlab model and dspsr do the same thing,
    within the limits of 32-bit float point accuracy.

    Note that offsets and frequencies are expressed as fractions of total
    size of input array.
    """
    output_dir = data_dir
    time_domain_params = {
        # "offset": np.arange(0.01, 1, 0.05),
        "offset": [0.11],
        "width": [1]
    }

    freq_domain_params = {
        # "frequency": np.arange(0.01, 1, 0.05),
        "frequency": [0.11],
        "phase": [np.pi/4.],
        "bin_offset": [0.1]
    }

    @classmethod
    def setUpClass(cls):
        os_factor = pfb.rational.Rational(*config["os_factor"].split("/"))
        normalize = os_factor.normalize(config["input_fft_length"]) * \
            config["channels"]
        n_samples = normalize * config["blocks"]
        cls.normalize = normalize
        cls.n_samples = n_samples
        cls.generator = generate_test_vector(
            backend=config["backend"]["test_vectors"])
        cls.channelizer = channelize(
            backend=config["backend"]["channelize"])
        cls.synthesizer = synthesize(
            backend=config["backend"]["synthesize"])

        comp = comparator.SingleDomainComparator(name="time")
        comp.operators["diff"] = lambda a, b: np.abs(a - b)
        comp.operators["this"] = lambda a: a

        comp.products["sum"] = np.sum
        comp.products["mean"] = np.mean

        cls.comp = comp

    def test_time_domain_impulse(self):
        """
        Determine whether dspsr and matlab invert time domain impulses of
        varying offsets.
        """
        domain_name = "time"
        header_file_path = os.path.join(config_dir, config["header_file_path"])
        fir_filter_path = os.path.join(
            config_dir, config["fir_filter_coeff_file_path"])
        for o in self.time_domain_params["offset"]:
            test_vector_dada_file = self.__class__.generator(
                domain_name,
                self.n_samples,
                o, self.time_domain_params["width"][0],
                n_pol=config["n_pol"],
                header_template=header_file_path,
                output_dir=self.output_dir)
            channelized_file_name = "channelized." + \
                os.path.basename(test_vector_dada_file.file_path)
            synthesized_file_name = "synthesized." + \
                os.path.basename(test_vector_dada_file.file_path)

            channelized_dada_file = self.__class__.channelizer(
                test_vector_dada_file.file_path,
                config["channels"],
                config["os_factor"],
                fir_filter_path=fir_filter_path,
                output_file_name=channelized_file_name,
                output_dir=self.output_dir)
            synthesized_dada_file = self.__class__.synthesizer(
                channelized_dada_file.file_path,
                config["input_fft_length"],
                output_file_name=synthesized_file_name,
                output_dir=self.output_dir)

            ar, dump = run_dspsr_with_dump(
                channelized_dada_file.file_path,
                config["dm"],
                config["period"],
                output_dir=self.output_dir,
                dump_stage=config["dump_stage"],
                extra_args=f"-IF 1:{config['input_fft_length']} -V"
            )
            dump = pfb.formats.DADAFile(dump).load_data()
            res_op, res_prod = self.comp.cartesian(
                synthesized_dada_file.data.flatten(),
                dump.data.flatten() / self.normalize
            )

            print(list(res_prod["diff"]["mean"])[0][1])
            print("{:6e}".format(res_prod["diff"]))

    def test_complex_sinusoid(self):
        """
        Determine with dspsr and matlab invert complex sinsuoids of varying
        frequency.
        """
        pass

    def test_simulated_pulsar(self):
        """
        Determine whether dspsr and matlab produce the same result when
        inverting simulated pulsar data.
        """
        pass


if __name__ == "__main__":
    logging.basicConfig(level=logging.ERROR)
    unittest.main()
