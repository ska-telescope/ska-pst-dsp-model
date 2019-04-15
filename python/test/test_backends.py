import unittest
import os

import numpy as np
import comparator

from config import load_config
import util
from data_gen import channelize, synthesize

test_dir = util.curdir(__file__)
test_data_dir = os.path.join(test_dir, "test_data")
base_dir = util.updir(test_dir, 2)
config_dir = os.path.join(base_dir, "config")
config = load_config()


class TestBackends(unittest.TestCase):

    thresh = 1e-9

    sinusoid = os.path.join(
        test_data_dir, ("complex_sinusoid.229376.0.110-0.785-0.100.2."
                        "single.python.dump"))
    sinusoid_channelized = os.path.join(
        test_data_dir, ("channelized.complex_sinusoid.229376."
                        "0.110-0.785-0.100.2."
                        "single.python.dump"))

    impulse = os.path.join(
        test_data_dir, ("time_domain_impulse.229376.0.110-1.000.2."
                        "single.python.dump"))
    impulse_channelized = os.path.join(
        test_data_dir, ("channelized.time_domain_impulse.229376.0.110-1.000.2."
                        "single.python.dump"))

    backends = ["python", "matlab"]

    @classmethod
    def setUpClass(cls):
        comp = comparator.SingleDomainComparator(name="time")

        comp.operators["diff"] = lambda a, b: a - b
        comp.operators["this"] = lambda a: a

        comp.products["mean"] = np.mean
        comp.products["sum"] = np.sum

        cls.comp = comp

    def test_channelize(self):
        channelizers = []
        channelized = []
        fir_filter_path = os.path.join(
            config_dir, config["fir_filter_coeff_file_path"])
        for b in self.backends:
            channelizers.append(channelize(backend=b))
            file_name = f"channelized.{b}.dump"
            channelized.append(channelizers[-1](
                self.sinusoid,
                config["channels"],
                config["os_factor"],
                fir_filter_path=fir_filter_path,
                output_dir="./",
                output_file_name=file_name
            ))

        res_op, res_prod = self.comp.cartesian(
            *[d.data.flatten() for d in channelized])
        mean_diff = list(res_prod["diff"]["mean"])[0][1]
        self.assertTrue(all([d < self.thresh for d in mean_diff]))

        print(f"{res_prod['diff']:.7e}")

    @unittest.skip("")
    def test_synthesize(self):
        synthesizers = []
        synthesized = []
        for b in self.backends:
            synthesizers.append(synthesize(backend=b))
            file_name = f"synthesized.{b}.dump"
            synthesized.append(synthesizers[-1](
                self.sinusoid_channelized,
                config["input_fft_length"],
                output_dir="./",
                output_file_name=file_name
            ))

        res_op, res_prod = self.comp.cartesian(
            *[d.data.flatten() for d in synthesized])
        mean_diff = list(res_prod["diff"]["mean"])[0][1]
        # self.assertTrue(all([d < self.thresh for d in mean_diff]))
        print(f"{res_prod['diff']:.7e}")



if __name__ == "__main__":
    unittest.main()
