import unittest
import logging
import os

import numpy as np
import comparator

from data_gen import channelize, synthesize, util
from data_gen.config import load_config

test_dir = util.curdir(__file__)
test_data_dir = os.path.join(test_dir, "test_data")
base_dir = util.updir(test_dir, 2)
config_dir = os.path.join(base_dir, "config")
config = load_config()


class TestBackends(unittest.TestCase):

    thresh = 1e-9

    test_vectors = [os.path.join(test_data_dir, f) for f in [
        "complex_sinusoid.dump", "time_domain_impulse.dump"
    ]]

    # channelized_vectors = [os.path.join(test_data_dir, f) for f in [
    #
    # ]]

    backends = ["python", "matlab"]

    @classmethod
    def setUpClass(cls):
        comp = comparator.SingleDomainComparator(name="time")

        comp.operators["isclose"] = lambda a, b: np.isclose(a, b, atol=1e-5)
        comp.operators["this"] = lambda a: a

        comp.products["mean"] = np.mean
        comp.products["sum"] = np.sum

        cls.comp = comp

        cls.channelizers = [channelize(backend=b) for b in cls.backends]

    def test_channelize(self):
        fir_filter_path = os.path.join(
            config_dir, config["fir_filter_coeff_file_path"])

        for input_file_path in self.test_vectors:
            channelized = []
            for i in range(len(self.backends)):
                channelizer = self.channelizers[i]
                file_name = (f"channelized.{self.backends[i]}."
                             f"{os.path.basename(input_file_path)}")
                channelized.append(channelizer(
                    input_file_path,
                    config["channels"],
                    config["os_factor"],
                    fir_filter_path=fir_filter_path,
                    output_dir="./",
                    output_file_name=file_name
                ))

            res_op, res_prod = self.comp.cartesian(
                *[d.data.flatten() for d in channelized])
            allclose = list(res_prod["isclose"]["mean"])[0][1][0]
            self.assertTrue(allclose == 1.0)

    # @unittest.skip("")
    # def test_synthesize(self):
    #     synthesizers = []
    #     synthesized = []
    #     for b in self.backends:
    #         synthesizers.append(synthesize(backend=b))
    #         file_name = f"synthesized.{b}.dump"
    #         synthesized.append(synthesizers[-1](
    #             self.sinusoid_channelized,
    #             config["input_fft_length"],
    #             output_dir="./",
    #             output_file_name=file_name
    #         ))
    #
    #     res_op, res_prod = self.comp.cartesian(
    #         *[d.data.flatten() for d in synthesized])
    #     mean_diff = list(res_prod["diff"]["mean"])[0][1]
    #     # self.assertTrue(all([d < self.thresh for d in mean_diff]))
    #     print(f"{res_prod['diff']:.7e}")



if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    unittest.main()
