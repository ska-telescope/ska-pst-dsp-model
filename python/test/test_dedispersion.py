# test_dedispersion.py
import unittest
import logging
import functools
import os

import matplotlib.pyplot as plt
import numpy as np
import comparator

import data_gen
import data_gen.util

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")
products_dir = os.path.join(base_dir, "products")


def correlate(a, b):
    # print(f"a.dtype={a.dtype}")
    # print(f"b.dtype={b.dtype}")
    f_a = np.fft.fft(a)
    f_b = np.fft.fft(b)
    return f_a*np.conj(f_b)


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
        comp.operators["xcorr"] = correlate

        comp.products["mean"] = np.mean
        comp.products["sum"] = np.sum

        comp.domain = [0, 4*262144]

        cls.comp = comp
        channelizer = data_gen.channelize(backend="python")
        cls.channelized_dump_file = channelizer(
            cls.simulated_pulsar_file_path)

    def test_simulated_pulsar_folded(self):

        def max_val(a):
            """
            Get most positive or most negative value
            """
            ma = abs(np.amax(a))
            mi = abs(np.amin(a))
            if ma > mi:
                return ma
            else:
                return mi

        f_sim = functools.partial(
            data_gen.run_dspsr,
            self.simulated_pulsar_file_path,
            output_dir=test_dir
        )

        f_inv = functools.partial(
            data_gen.run_dspsr,
            self.channelized_dump_file.file_path,
            extra_args="-IF 1:D -V",
            output_dir=test_dir
        )

        with data_gen.dispose(f_sim, f_inv, dispose=False) as res:
            sim_ar = res[0][0]
            inv_ar = res[1][0]

            diff_chain = data_gen.BaseRunner.chain(
                data_gen.run_psrdiff,
                data_gen.run_psrtxt,
                data_gen.load_psrtxt_data
            )
            txt_chain = data_gen.BaseRunner.chain(
                data_gen.run_psrtxt,
                data_gen.load_psrtxt_data
            )
            data_diff = diff_chain(sim_ar, inv_ar)[-1][2:, :]
            data_sim = txt_chain(sim_ar)[-1][2:, :]
            data_inv = txt_chain(inv_ar)[-1][2:, :]
            # report = []
            fig, axes = plt.subplots(2, 2, figsize=(10, 10))
            x = data_diff[0, :]
            for i in range(2):
                for j in range(2):
                    axes[i, j].grid(True)
                    # axes[i, j].plot(x, data_diff[j+2*i + 1, :], alpha=0.8)
                    datum_sim = data_sim[j+2*i + 1, :].copy()
                    datum_sim /= max_val(datum_sim)
                    datum_inv = data_inv[j+2*i + 1, :].copy()
                    datum_inv /= max_val(datum_inv)

                    diff = datum_sim - datum_inv
                    abs_diff = np.abs(diff)
                    # report.append(np.mean(diff))
                    # report.append(np.sum(diff))
                    axes[i, j].plot(x, diff, alpha=0.8)
                    axes[i, j].set_title((f"mean diff: {np.mean(abs_diff):.4e} "
                                          f"sum diff: {np.sum(abs_diff):.4e}"))
                    # axes[i, j].plot(x, data_sim[j+2*i + 1, :])
                    # axes[i, j].plot(x, data_inv[j+2*i + 1, :])
                    # axes[i, j].plot(x, datum_sim, alpha=0.8)
                    # axes[i, j].plot(x, datum_inv, alpha=0.8)
            fig.tight_layout()
            fig.savefig(os.path.join(
                products_dir, "test_simulated_pulsar_folded.png"))
            # report_file_path = os.path.join(
            #     products_dir, "test_simulated_pulsar_folded.report.json"
            # )


    @unittest.skip("")
    def test_simulated_pulsar_no_fold(self):

        f_sim = functools.partial(
            data_gen.run_dspsr_with_dump,
            self.simulated_pulsar_file_path,
            output_dir=test_dir,
            dump_stage="Fold"
        )

        f_inv = functools.partial(
            data_gen.run_dspsr_with_dump,
            self.channelized_dump_file.file_path,
            extra_args="-IF 1:D -V",
            output_dir=test_dir,
            dump_stage="Fold"
        )

        with data_gen.dispose(f_sim, f_inv, dispose=False) as res:
            output_fft_length = int(data_gen.find_in_log(
                res[1][-1], "output_fft_length"))
            sim_dump_data = res[0][0].data
            inv_dump_data = res[1][0].data
            inv_dump_data /= output_fft_length**2
            res_op, res_prod = self.comp.cartesian(
                sim_dump_data.flatten(), inv_dump_data.flatten())

        figs, axes = comparator.util.plot_operator_result(res_op)

        for i, fig in enumerate(figs):
            fig.savefig(os.path.join(
                products_dir, f"test_simulated_pulsar_no_fold.{i}.png"))


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    unittest.main()
