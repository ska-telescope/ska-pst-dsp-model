# test_dedispersion.py
import unittest
import logging
import functools
import os

import data_gen
import data_gen.util

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")
products_dir = os.path.join(base_dir, "products")


class TestDedispersion(unittest.TestCase):
    """
    Run psrdiff on the output of running data through dspsr with no parameters
    (simple dedispersion) and on the output of the InverseFilterbank, operating
    on channelized data
    """

    simulated_pulsar_file_path = os.path.join(
        data_dir, "simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump"
    )

    def test_simulated_pulsar(self):
        channelizer = data_gen.channelize(backend="python")
        with data_gen.dispose(channelizer(
                              self.simulated_pulsar_file_path)) as dump_file:

            f_sim = functools.partial(
                data_gen.run_dspsr,
                self.simulated_pulsar_file_path,
                output_dir=test_dir
            )

            f_inv = functools.partial(
                data_gen.run_dspsr,
                dump_file.file_path,
                extra_args="-IF 1:D -V",
                output_dir=test_dir
            )

            f_sim()
            f_inv()
            # with data_gen.dispose(f_sim, f_inv) as res:
            #     pass



if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    unittest.main()
