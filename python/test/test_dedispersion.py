# test_dedispersion.py
import unittest
import logging
import functools
import os

import numpy as np
import comparator

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

    @classmethod
    def setUpClass(cls):
        comp = comparator.SingleDomainComparator(name="time")
        comp.operators["this"] = lambda a: a
        comp.operators["diff"] = lambda a, b: a - b

        comp.products["mean"] = np.mean
        comp.products["sum"] = np.sum

        cls.comp = comp

    def test_simulated_pulsar(self):
        channelizer = data_gen.channelize(backend="python")
        with data_gen.dispose(channelizer(
                              self.simulated_pulsar_file_path)) as dump_file:

            f_sim = functools.partial(
                data_gen.run_dspsr_with_dump,
                self.simulated_pulsar_file_path,
                output_dir=test_dir,
                dump_stage="Fold"
            )

            f_inv = functools.partial(
                data_gen.run_dspsr_with_dump,
                dump_file.file_path,
                extra_args="-IF 1:D -V",
                output_dir=test_dir,
                dump_stage="Fold"
            )

            with data_gen.dispose(f_sim, f_inv, dispose=False) as res:
                sim_dump_data = res[0][0].data
                inv_dump_data = res[1][0].data
                # inv_dump_data /=
                res_op, res_prod = self.comp.cartesian(
                    sim_dump_data.flatten(), inv_dump_data.flatten())

            figs, axes = comparator.util.plot_operator_result(res_op)

            for i, fig in enumerate(figs):
                fig.savefig(os.path.join(
                    products_dir, f"test_simulated_pulsar.{i}.png"))


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    unittest.main()
