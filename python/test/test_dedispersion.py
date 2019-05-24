# test_dedispersion.py
import json
import unittest
import logging
import functools
import os

import matplotlib.pyplot as plt
import numpy as np
import comparator
import psr_formats
import pfb.rational

import data_gen
import data_gen.util

from . import util as test_util

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")
products_dir = os.path.join(base_dir, "products")


def correlate(a, b):
    # print(f"a.dtype={a.dtype}")
    # print(f"b.dtype={b.dtype}")
    f_a = np.fft.fft(a)
    f_b = np.fft.fft(b)
    # return f_a*np.conj(f_b)
    return np.abs(np.fft.ifft(f_a*np.conj(f_b)))


def add_offset(file_path, offset, end=None):
    dada_file = psr_formats.DADAFile(file_path).load_data()
    header = dada_file.header
    data = dada_file.data
    data_slice = slice(offset, end)
    dada_file.file_path = dada_file.file_path + ".shifted"
    dada_file.data = data[data_slice, :, :]
    dada_file.header = header
    dada_file["OBS_OFFSET"] = str(4 * 4 * offset)
    dada_file.dump_data()
    return dada_file.file_path


class TestDedispersion(unittest.TestCase):
    """
    Run psrdiff on the output of running data through dspsr with no parameters
    (simple dedispersion) and on the output of the InverseFilterbank, operating
    on channelized data
    """

    simulated_pulsar_file_path = os.path.join(
        data_dir, "simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump"
    )
    kernel_size = 131072
    kernel_size = 16384

    @classmethod
    def setUpClass(cls):
        comp = comparator.SingleDomainComparator(name="time")
        comp.operators["this"] = lambda a: a
        comp.operators["diff"] = lambda a, b: a - b
        # comp.operators["xcorr"] = correlate

        comp.products["mean"] = np.mean
        comp.products["sum"] = np.sum
        comp.products["max"] = np.amax

        cls.comp = comp
        channelizer = data_gen.channelize(
            backend="python",
            output_dir=data_dir)
        cls.channelized_dump_file = channelizer(
            cls.simulated_pulsar_file_path)

        deripple_str = "-dr" if data_gen.config["deripple"] else ""
        cls.inversion_extra_args = (
            f"-IF 1:{data_gen.config['input_fft_length']}"
            f":{data_gen.config['input_overlap']} "
            f"{deripple_str} "
            f"-fft-window {data_gen.config['fft_window']} -V")
        cls.os_factor = pfb.rational.Rational.from_str(
            data_gen.config["os_factor"])

        channelized_samples = int(cls.os_factor.normalize(functools.reduce(
            lambda x, y: x * y, cls.channelized_dump_file.data.shape[:-1])))
        # cls.inversion_extra_args = (
        #     f"-IF 1:D:{data_gen.config['input_overlap']} "
        #     f"{deripple_str} "
        #     f"-fft-window {data_gen.config['fft_window']} -V")

        sample_shift = int((int(cls.channelized_dump_file["NTAP_0"]) - 1) / 2)
        sample_shift += (cls.os_factor.normalize(
                            data_gen.config["input_overlap"])
                         * data_gen.config["channels"])
        cls.simulated_pulsar_file_path_shifted = add_offset(
            cls.simulated_pulsar_file_path, sample_shift)

        cls.report = {}

    # @unittest.skip("")
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
            self.simulated_pulsar_file_path_shifted,
            extra_args=f"-x {self.kernel_size} -V",
            output_dir=data_dir
        )

        f_inv = functools.partial(
            data_gen.run_dspsr,
            self.channelized_dump_file.file_path,
            extra_args=self.inversion_extra_args + f" -x {self.kernel_size}",
            output_dir=data_dir
        )

        with data_gen.dispose(f_sim, f_inv, dispose=False) as res:
            sim_ar = res[0][0]
            inv_ar = res[1][0]
            print(sim_ar, inv_ar)

            diff_chain = data_gen.BaseRunner.chain(
                functools.partial(data_gen.run_psrdiff, output_dir=test_dir),
                functools.partial(data_gen.run_psrtxt, output_dir=test_dir),
                data_gen.load_psrtxt_data
            )
            txt_chain = data_gen.BaseRunner.chain(
                functools.partial(
                    data_gen.run_psrtxt, output_dir=test_dir),
                data_gen.load_psrtxt_data
            )
            data_diff = diff_chain(sim_ar, inv_ar)[-1][2:, :]
            data_sim = txt_chain(sim_ar)[-1][2:, :]
            data_inv = txt_chain(inv_ar)[-1][2:, :]
            fig, axes = plt.subplots(2, 2, figsize=(10, 10))
            x = data_diff[0, :]

            report = []

            for i in range(2):
                for j in range(2):
                    axes[i, j].grid(True)
                    # axes[i, j].plot(x, data_diff[j+2*i + 1, :], alpha=0.8)
                    datum_sim = data_sim[j+2*i + 1, :].copy()
                    datum_sim /= max_val(datum_sim)
                    datum_inv = data_inv[j+2*i + 1, :].copy()
                    datum_inv /= max_val(datum_inv)

                    offset = np.argmax(correlate(datum_sim, datum_inv))
                    print(offset)
                    datum_sim = np.roll(datum_sim, -offset)
                    diff = datum_sim - datum_inv
                    abs_diff = np.abs(diff)
                    report.append({
                        "mean": np.mean(abs_diff),
                        "total": np.sum(abs_diff),
                        "max": np.amax(abs_diff)
                    })
                    axes[i, j].plot(x, abs_diff, alpha=0.8)
                    axes[i, j].set_title((f"mean diff: {np.mean(abs_diff):.4e} "
                                          f"sum diff: {np.sum(abs_diff):.4e}"))
                    # axes[i, j].plot(x, data_sim[j+2*i + 1, :])
                    # axes[i, j].plot(x, data_inv[j+2*i + 1, :])
                    axes[i, j].plot(x, datum_sim, alpha=0.8)
                    axes[i, j].plot(x, datum_inv, alpha=0.8)

            fig.suptitle("test_simulated_pulsar_folded")
            fig.tight_layout(rect=[0, 0.03, 1, 0.95])
            plt.show()
            fig.savefig(os.path.join(
                products_dir, "test_simulated_pulsar_folded.png"))

            self.report["folded"] = report

    @unittest.skip("")
    def test_simulated_pulsar_no_fold(self):
        dump_stage = "Fold"
        os_factor = pfb.rational.Rational.from_str(
            data_gen.config["os_factor"])

        f_sim = functools.partial(
            data_gen.run_dspsr_with_dump,
            self.simulated_pulsar_file_path_shifted,
            # dada_file.file_path,
            # self.simulated_pulsar_file_path,
            extra_args=f"-x {self.kernel_size} -V",
            output_dir=test_dir,
            dump_stage=dump_stage
        )

        f_inv = functools.partial(
            data_gen.run_dspsr_with_dump,
            self.channelized_dump_file.file_path,
            extra_args=self.inversion_extra_args + f" -x {self.kernel_size}",
            output_dir=test_dir,
            dump_stage=dump_stage
        )
        sample_shift = 0
        stokes_param = 0

        report = []

        with data_gen.dispose(f_sim, f_inv, dispose=False) as res:

            output_fft_length = int(data_gen.find_in_log(
                res[1][-1], "output_fft_length"))
            sim_dump_data = res[0][0].data[sample_shift:, -1]
            inv_dump_data = res[1][0].data[:, -1]
            print(sim_dump_data.shape)
            print(inv_dump_data.shape)


        for stokes_param in range(sim_dump_data.shape[-1]):
            sim_dump_datum = sim_dump_data[:, 0, stokes_param]
            inv_dump_datum = inv_dump_data[:, 0, stokes_param]

            inv_dump_data /= (output_fft_length * float(os_factor))**2
            sim_dump_datum /= np.amax(sim_dump_datum)
            inv_dump_datum /= np.amax(inv_dump_datum)

            res_op, res_prod = self.comp.cartesian(
                sim_dump_datum, inv_dump_datum)

            print(f"{res_prod['diff']:.6e}")
            report.append({
                "mean": list(res_prod["diff"]["mean"])[1][0],
                "max": list(res_prod["diff"]["max"])[1][0],
                "total": list(res_prod["diff"]["sum"])[1][0]
            })
            fig, axes = test_util.plot_time_domain_comparison(
                res_op,
                subplots_kwargs=dict(figsize=(14, 10)),
                labels=["Vanilla DSPSR", "InverseFilterbank"])
            fig.suptitle((f"test_simulated_pulsar_no_fold: dump stage "
                          f"{dump_stage}, coherence stage {stokes_param}"))
            fig.tight_layout(rect=[0, 0.03, 1, 0.95])
            fig.savefig(os.path.join(
                products_dir,
                (f"test_simulated_pulsar_no_fold."
                 f"{stokes_param}.{dump_stage}.png")))

        self.report["no_fold"] = report

    @classmethod
    def tearDownClass(cls):
        with open(
            os.path.join(products_dir, "report.dedispersion.json"), "w"
        ) as f:
            json.dump(cls.report, f, cls=comparator.NumpyEncoder)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    unittest.main()
