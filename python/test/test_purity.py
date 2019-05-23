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

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")
products_dir = os.path.join(base_dir, "products")

# plt.ion()

# fig, axes = plt.subplots(2, 1)


def spurious(a):
    b = a.copy()
    b[np.argmax(np.abs(b))] = 0.0
    # axes[0].plot(a)
    # axes[1].plot(b)
    # input(">>> ")
    # axes[0].cla()
    # axes[1].cla()
    return b


def dB(a):
    return 10*np.log10(np.abs(a.copy()) + 1e-12)


class TestPurity(unittest.TestCase):
    """
    These tests attempt to determine whether the PFB inversion algorithm
    as implemented in the PST Matlab model and dspsr do the same thing,
    within the limits of 32-bit float point accuracy.

    Note that offsets and frequencies are expressed as fractions of total
    size of input array.
    """
    thresh = 1e-7
    output_dir = data_dir

    simulated_pulsar_file_path = os.path.join(
        data_dir, "simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump"
    )

    time_domain_args = {
        # "offset": [0.11],
        # "offset": [random.random()],
        "offset": np.arange(1, 200)/200,
        "width": 1
    }

    freq_domain_args = {
        # "frequency": [0.4],
        # "frequency": [random.random()],
        "frequency": np.arange(1, 200)/200,
        "phase": np.pi/4,
        "bin_offset": 0.0
    }

    @classmethod
    def setUpClass(cls):
        os_factor = pfb.rational.Rational.from_str(
            data_gen.config["os_factor"])
        normalize = data_gen.config["input_fft_length"] *\
            data_gen.config["channels"]
        block_size = os_factor.normalize(data_gen.config["input_fft_length"]) *\
            data_gen.config["channels"]
        n_samples = block_size * data_gen.config["blocks"]
        output_sample_shift = (
            os_factor.normalize(data_gen.config["input_overlap"]) *
            data_gen.config["channels"])
        cls.block_size = block_size
        cls.fft_size = 2*block_size
        cls.os_factor = os_factor
        cls.normalize = normalize
        cls.n_samples = n_samples
        cls.output_sample_shift = output_sample_shift
        cls.generator = functools.partial(
            data_gen.generate_test_vector,
            backend=data_gen.config["backend"]["test_vectors"])
        cls.channelizer = data_gen.channelize(
            backend=data_gen.config["backend"]["channelize"])
        cls.pipeline = data_gen.pipeline(
            cls.generator,
            cls.channelizer,
            lambda a, **kwargs: a,
            output_dir=cls.output_dir
        )
        deripple_str = "-dr" if data_gen.config["deripple"] else ""
        cls.synthesizer = functools.partial(
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
        # synthesizer = functools.partial(
        #     data_gen.synthesize,
        #     deripple=data_gen.config["deripple"],
        #     backend=data_gen.config["backend"]["synthesize"],
        #     fft_window_str=data_gen.config["fft_window"])
        # cls.synthesizer = lambda a: [synthesizer(a)]
        comp = comparator.MultiDomainComparator(domains={
            "time": comparator.SingleDomainComparator("time"),
            "freq": comparator.FrequencyDomainComparator("freq")
        })
        comp.freq.domain = [0, cls.fft_size]

        comp.operators["this"] = lambda a: a
        comp.operators["abs_diff"] = lambda a, b: np.abs(a - b)
        # comp.operators["mag"] = lambda a: np.abs(a)
        comp.operators["power"] = lambda a: np.abs(a)**2
        # comp.operators["diff"] = lambda a, b: a - b
        # comp.operators["power_diff"] = lambda a, b: dB(a - b)
        # isclose returns an array of booleans;
        # the imaginary component is always zero.
        # comp.operators["isclose"] = lambda a, b: np.isclose(
        #     a, b, atol=cls.thresh)

        comp.products["mean"] = np.mean
        comp.products["sum"] = np.sum

        comp.products["mean_spurious"] = lambda a: dB(np.mean(spurious(a)))
        comp.products["max_spurious"] = lambda a: dB(np.amax(spurious(a)))
        comp.products["total_spurious"] = lambda a: dB(np.sum(spurious(a)))

        cls.comp = comp
        cls.report = {}

    def chop(self, input_dump_file, inverted_dump_file):

        input_dat = input_dump_file.data.flatten()
        inverted_dat = inverted_dump_file.data.flatten()
        inverted_dat /= self.normalize

        return input_dat, inverted_dat

    # @unittest.skip("")
    def test_time_domain_impulse(self):
        sub_report = []
        args = (self.time_domain_args["width"], )
        for offset in self.time_domain_args["offset"]:
            dump_files = self.__class__.pipeline(
                "time", self.n_samples, offset, *args)
            inverted_dump = self.__class__.synthesizer(dump_files[1].file_path)
            inverted_dump = inverted_dump[0]

            sample_shift = int((int(dump_files[1]["NTAP_0"]) - 1) / 2)
            sample_shift += self.output_sample_shift

            input_dat, inverted_dat = self.chop(
                dump_files[0], inverted_dump)
            input_dat = input_dat[sample_shift:]
            res_op, res_prod = self.comp.time.cartesian(
                input_dat, inverted_dat
            )

            sub_report.append({
                "offset": offset,
                "mean_diff": list(res_prod["abs_diff"]["mean"])[1][0],
                "total_diff": list(res_prod["abs_diff"]["sum"])[1][0],
                "max_spurious_power": list(res_prod["power"]["max_spurious"])[1][0],
                "total_spurious_power": list(res_prod["power"]["total_spurious"])[1][0],
                "mean_spurious_power": list(res_prod["power"]["mean_spurious"])[1][0]
            })

            # figs, axes = comparator.plot_operator_result(res_op,
            #                                              figsize=(10, 10))
            # for op in ["this", "diff", "power"]:
            #     figs[op].suptitle(
            #         f"{op}: Time offset {int(self.n_samples*offset)}")
            #     figs[op].savefig(
            #         os.path.join(products_dir,
            #                      f"time.purity.{op}.{offset:.2f}.png"))



        self.__class__.report["test_time_domain_impulse"] = sub_report

    # @unittest.skip("")
    def test_complex_sinusoid(self):
        sub_report = []

        args = (self.freq_domain_args["phase"],
                self.freq_domain_args["bin_offset"])

        for freq in self.freq_domain_args["frequency"]:
            dump_files = self.__class__.pipeline(
                "freq", self.n_samples, freq, *args)
            inverted_dump = self.__class__.synthesizer(dump_files[1].file_path)
            inverted_dump = inverted_dump[0]

            sample_shift = int((int(dump_files[1]["NTAP_0"]) - 1) / 2)
            sample_shift += self.output_sample_shift

            input_dat, inverted_dat = self.chop(
                dump_files[0], inverted_dump)
            input_dat = input_dat[sample_shift:]

            res_op, res_prod = self.comp.freq.cartesian(
                input_dat/self.fft_size, inverted_dat/self.fft_size
            )

            sub_report.append({
                "freq": freq,
                "mean_diff": list(res_prod["abs_diff"]["mean"])[1][0],
                "total_diff": list(res_prod["abs_diff"]["sum"])[1][0],
                "max_spurious_power": list(res_prod["power"]["max_spurious"])[1][0],
                "total_spurious_power": list(res_prod["power"]["total_spurious"])[1][0],
                "mean_spurious_power": list(res_prod["power"]["mean_spurious"])[1][0]
            })



        self.__class__.report["test_complex_sinusoid"] = sub_report

    @unittest.skip("")
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
        with open(os.path.join(products_dir, "report.purity.json"), "w") as f:
            json.dump(cls.report, f, cls=comparator.NumpyEncoder)


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    unittest.main()
