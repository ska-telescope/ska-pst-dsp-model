import unittest
import logging
import os
import sys

import numpy as np
import pfb.rational
import comparator

from data_gen import channelize, synthesize, generate_test_vector, util
from data_gen.config import load_config

test_dir = util.curdir(__file__)
test_data_dir = os.path.join(test_dir, "test_data")
base_dir = util.updir(test_dir, 2)
config_dir = os.path.join(base_dir, "config")
config = load_config()


def base_cls():

    class TestBackends(unittest.TestCase):

        thresh = 1e-5
        backends = ["python", "matlab"]

        @classmethod
        def setUpClass(cls):
            comp = comparator.SingleDomainComparator(name="time")
            comp.operators["diff"] = lambda a, b: a - b
            comp.operators["isclose"] = lambda a, b: np.isclose(
                a, b, atol=cls.thresh)
            comp.products["mean"] = np.mean

            cls.comp = comp
            cls.os_factor = pfb.rational.Rational.from_str(config["os_factor"])
            cls.n_samples = cls.os_factor.normalize(
                config["input_fft_length"]
            ) * config["channels"] * config["blocks"]
            cls.fir_filter_path = os.path.join(
                config_dir, config["fir_filter_coeff_file_path"])

    return TestBackends


# @unittest.skip("")
class TestSynthesizerBackends(base_cls()):

    @classmethod
    def setUpClass(cls):
        super(TestSynthesizerBackends, cls).setUpClass()

        input_file_paths = []
        channelized_file_paths = []

        input_file_path = generate_test_vector(
            "time", cls.n_samples,
            0.01, 1, backend="python").file_path

        file_name = (f"channelized.python."
                     f"{os.path.basename(input_file_path)}")

        channelized_file_path = channelize(
            input_file_path,
            config["channels"],
            cls.os_factor,
            fir_filter_path=cls.fir_filter_path,
            output_dir="./",
            output_file_name=file_name,
            backend="python"
        ).file_path

        input_file_paths.append(input_file_path)
        channelized_file_paths.append(channelized_file_path)

        cls.input_file_paths = input_file_paths
        cls.channelized_file_paths = channelized_file_paths
        cls.synthesizers = [synthesize(backend=b) for b in cls.backends]

    def test_synthesize(self):
        for channelized_file_path in self.channelized_file_paths:
            synthesized = []
            for i, b in enumerate(self.backends):
                file_name = f"synthesized.{b}.dump"
                synthesized.append(self.synthesizers[i](
                    channelized_file_path,
                    input_fft_length=config["input_fft_length"],
                    input_overlap=config["input_overlap"],
                    deripple=config["deripple"],
                    fft_window_str=config["fft_window"],
                    output_dir="./",
                    output_file_name=file_name
                ))
                synthesized[-1].load_data()

            res_op, res_prod = self.comp.cartesian(
                *[d.data.flatten() for d in synthesized])

            isclose = list(res_prod["isclose"]["mean"])[0][1][0]
            if not isclose:
                print(f"{res_prod:.6f}")
                import matplotlib.pyplot as plt
                comparator.plot_operator_result(res_op)
                plt.show()

            self.assertTrue(isclose == 1.0)


# @unittest.skip("")
class TestChannelizerBackends(base_cls()):
    """
    Test to ensure that backends are producing the same output.
    """
    @classmethod
    def setUpClass(cls):
        super(TestChannelizerBackends, cls).setUpClass()

        input_file_paths = []

        input_file_path = generate_test_vector(
            "time", cls.n_samples,
            0.01, 1, backend="python").file_path

        input_file_paths.append(input_file_path)

        input_file_path = generate_test_vector(
            "freq", cls.n_samples,
            0.001, np.pi/4, 0.1, backend="python").file_path

        input_file_paths.append(input_file_path)

        cls.input_file_paths = input_file_paths
        cls.channelizers = [channelize(backend=b) for b in cls.backends]

    def test_channelize(self):

        for input_file_path in self.input_file_paths:

            channelized = []
            for i in range(len(self.backends)):
                channelizer = self.channelizers[i]
                file_name = (f"channelized.{self.backends[i]}."
                             f"{os.path.basename(input_file_path)}")
                channelized.append(channelizer(
                    input_file_path,
                    channels=config["channels"],
                    os_factor_str=self.os_factor,
                    fir_filter_path=self.fir_filter_path,
                    output_dir="./",
                    output_file_name=file_name
                ))

            res_op, res_prod = self.comp.cartesian(
                *[d.data.flatten() for d in channelized])
            allclose = list(res_prod["isclose"]["mean"])[0][1][0]
            self.assertTrue(allclose == 1.0)


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    unittest.main()
