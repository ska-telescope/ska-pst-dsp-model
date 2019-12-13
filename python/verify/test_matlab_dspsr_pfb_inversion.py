import typing
import logging
import os
import functools
import json

import numpy as np
import pfb.rational
import psr_formats
import comparator

import data_gen
import data_gen.util
from data_gen.config import matplotlib_config, load_config

from .common import create_parser

module_logger = logging.getLogger(__name__)

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")
products_dir = os.path.join(base_dir, "products")

matplotlib_config()


class TestMatlabDspsrPfbInversion:
    """
    These tests attempt to determine whether the PFB inversion algorithm
    as implemented in the PST Matlab model and dspsr do the same thing,
    within the limits of 32-bit float point accuracy.
    """
    thresh = 1e-7
    output_dir = data_dir

    simulated_pulsar_file_path = os.path.join(
        data_dir, "simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump"
    )

    time_domain_args = {
        "width": 1
    }

    freq_domain_args = {
        "phase": np.pi/4,
        "bin_offset": 0.0
    }

    def __init__(
        self,
        n_test: int,
        dspsr_bin: str,
        os_factor: typing.Union[pfb.rational.Rational, str],
        input_fft_length: int,
        input_overlap: int,
        fft_window: str,
        deripple: bool,
        channels: int,
        fir_filter_taps: int,
        fir_filter_coeff_file_path: str,
        blocks: int,
        backend: dict,
        dump_stage: str,
        dm: float,
        period: float,
        extra_dspsr_args: str = "",
        save_output: bool = False
    ):

        make_plots = False
        if n_test == 1:
            make_plots = True

        self.make_plots = make_plots
        self.input_fft_length = input_fft_length
        self.input_overlap = input_overlap
        self.deripple = deripple
        self.fft_window = fft_window
        self.save_output = save_output

        os_factor = pfb.rational.Rational.from_str(os_factor)
        # normalize = os_factor.normalize(input_fft_length * channels)
        normalize = input_fft_length * channels
        block_size = os_factor.normalize(input_fft_length) * channels

        fft_size = 2*block_size
        n_samples = block_size * blocks
        output_sample_shift = os_factor.normalize(input_overlap) * channels
        total_sample_shift = (
            output_sample_shift + (fir_filter_taps - 1) // 2)

        if n_test == 1:
            self.time_domain_args["offset"] = [10 + total_sample_shift]
            self.freq_domain_args["frequency"] = [1*blocks]
        else:
            self.time_domain_args["offset"] = (
                np.linspace(1, n_samples, n_test).astype(int))
            self.freq_domain_args["frequency"] = (
                np.linspace(1, block_size, n_test).astype(int) *
                blocks
            )

        self.block_size = block_size
        self.fft_size = fft_size
        self.os_factor = os_factor
        self.normalize = normalize
        self.n_samples = n_samples
        self.output_sample_shift = output_sample_shift
        self.total_sample_shift = total_sample_shift

        self.generator = functools.partial(
            data_gen.generate_test_vector,
            n_bins=self.n_samples,
            backend=backend["test_vectors"])
        self.channelizer = data_gen.channelize(
            backend=backend["channelize"])
        self.synthesizer = functools.partial(
            data_gen.synthesize,
            deripple=deripple,
            backend=backend["synthesize"],
            fft_window_str=fft_window)
        self.pipeline = data_gen.pipeline(
            self.generator,
            self.channelizer,
            self.synthesizer,
            output_dir=self.output_dir
        )
        deripple_str = "-dr" if deripple else ""
        self.dspsr_dumper = functools.partial(
            data_gen.run_dspsr_with_dump,
            dspsr_bin=dspsr_bin,
            dm=dm,
            period=period,
            output_dir=self.output_dir,
            dump_stage=dump_stage,
            extra_args=(f"-IF 1:{input_fft_length}:"
                        f"{input_overlap} "
                        f"{deripple_str} "
                        f"-fft-window {fft_window} "
                        f"{extra_dspsr_args} -V")
        )
        self.extra_dspsr_args = extra_dspsr_args
        self.dspsr_bin = dspsr_bin
        comp = comparator.SingleDomainComparator(name="time")
        comp.operators["this"] = lambda a: a
        comp.operators["diff"] = lambda a, b: a - b
        # isclose returns an array of booleans;
        # the imaginary component is always zero.
        comp.operators["isclose"] = lambda a, b: np.isclose(
            a, b, atol=self.thresh)

        comp.products["sum"] = lambda a: np.sum(a)
        comp.products["mean"] = lambda a: np.mean(a)

        self.comp = comp
        self.report = {}


    def test_time_domain_impulse(self):
        sub_report = []
        for offset in self.time_domain_args["offset"]:
            dada_files = self.pipeline(
                [offset], [self.time_domain_args["width"]],
                domain_name="time")
            dspsr_dump = self.dspsr_dumper(
                dada_files[1].file_path)
            dspsr_dump = dspsr_dump[0]

            res_op, res_prod, mean_diff, sum_diff = self.compare_dump_files(
                dada_files[-1], dspsr_dump)

            figs, axes = comparator.plot_operator_result(
                res_op, figsize=(10, 10), corner_plot=True)
            for op in ["this", "diff"]:
                figs[op].suptitle(
                    f"{op}: Time offset {int(offset)}")
                figs[op].savefig(
                    os.path.join(products_dir, f"matlab_dspsr.time.{op}.{offset}.png"))

            prod_str = f"{res_prod['isclose']:.6e}"

            sub_report.append({
                "offset": offset,
                "mean": mean_diff,
                "sum": sum_diff,
                "str": prod_str
            })

            module_logger.debug((f"test_time_domain_impulse: "
                                 f"offset={offset}\n"
                                 f"{prod_str}"))

            if mean_diff != 1.0:
                err_msg = ("time_domain_impulse: mean_diff is not 1.0")
                module_logger.error(err_msg)

        self.report["test_time_domain_impulse"] = sub_report

    def test_complex_sinusoid(self):
        sub_report = []
        args = ([self.freq_domain_args["phase"]],
                self.freq_domain_args["bin_offset"])
        for freq in self.freq_domain_args["frequency"]:
            dada_files = self.pipeline([freq], *args, domain_name="freq")
            dspsr_dump = self.dspsr_dumper(
                dada_files[1].file_path)[0]

            res_op, res_prod, mean_diff, sum_diff = self.compare_dump_files(
                dada_files[-1], dspsr_dump)

            figs, axes = comparator.plot_operator_result(
                res_op, figsize=(10, 10), corner_plot=True)
            for op in ["this", "diff"]:
                figs[op].suptitle(
                    f"{op}: Frequency {int(freq)} Hz")
                figs[op].savefig(
                    os.path.join(products_dir, f"matlab_dspsr.freq.{op}.{freq}.png"))

            prod_str = f"{res_prod['isclose']:.6e}"

            sub_report.append({
                "freq": freq,
                "mean": mean_diff,
                "sum": sum_diff,
                "str": prod_str
            })
            module_logger.debug((f"test_complex_sinusoid: "
                                 f"freq={freq}\n"
                                 f"{prod_str}"))
            if mean_diff != 1.0:
                err_msg = ("test_complex_sinusoid: mean_diff is not 1.0")
                module_logger.error(err_msg)

        self.report["test_complex_sinusoid"] = sub_report

    def test_simulated_pulsar(self):
        """
        Determine whether dspsr and matlab produce the same result when
        inverting simulated pulsar data.
        """
        sub_report = []
        sim_psr_pipeline = data_gen.pipeline(
            lambda a, **kwargs: psr_formats.DADAFile(a).load_data(),
            self.channelizer,
            self.synthesizer,
            output_dir=self.output_dir
        )

        dada_files = sim_psr_pipeline(self.simulated_pulsar_file_path)
        dspsr_dump = self.dspsr_dumper(dada_files[1].file_path)[0]
        res_op, res_prod, mean_diff, sum_diff = self.compare_dump_files(
            dada_files[-1], dspsr_dump
        )

        figs, axes = comparator.plot_operator_result(
            res_op, figsize=(10, 10), corner_plot=True)

        for op in ["this", "diff"]:
            figs[op].suptitle(
                f"{op}: Simulated Pulsar")
            figs[op].savefig(
                os.path.join(products_dir, f"matlab_dspsr.simulated_pulsar.{op}.png"))

        prod_str = f"{res_prod['isclose']:.6e}"
        module_logger.debug((f"test_simulated_pulsar: \n"
                             f"{prod_str}"))
        sub_report.append({
            "mean": mean_diff,
            "sum": sum_diff,
            "str": prod_str
        })
        self.report["test_simulated_pulsar"] = sub_report

    def compare_dump_files(self, matlab_dump_file, dspsr_dump_file):
        matlab_dat = matlab_dump_file.data.flatten()
        dspsr_dat = dspsr_dump_file.data.flatten() / self.normalize

        shape_same = matlab_dat.shape[0] == dspsr_dat.shape[0]
        if not shape_same:
            err_msg = ("compare_dump_files: Shapes are not the same: "
                       f"matlab_dat.shape[0] = {matlab_dat.shape[0]}, "
                       f"dspsr_dat.shape[0] = {dspsr_dat.shape[0]}")
            module_logger.error(err_msg)

        res_op, res_prod = self.comp(matlab_dat, dspsr_dat)
        isclose_prod = res_prod["isclose"][0][1]
        mean_diff = isclose_prod["mean"]
        sum_diff = isclose_prod["sum"]
        if mean_diff != 1.0:
            err_msg = "compare_dump_files: Data are not equal "
            module_logger.error(err_msg)

        return res_op, res_prod, mean_diff, sum_diff

    def finish(self):
        report_file_path = os.path.join(products_dir, "report.matlab_dspsr.json")
        with open(report_file_path, "w") as f:
            json.dump(self.report, f, cls=comparator.NumpyEncoder)


if __name__ == "__main__":

    parser = create_parser(
        description="Test DSPSR and Matlab PFB Inversion Implementations")

    parser.add_argument("-s", "--do-simulated-pulsar",
                        dest="do_simulated_pulsar", action="store_true")

    parsed = parser.parse_args()

    level = logging.DEBUG
    if not parsed.verbose:
        level = logging.INFO

    logging.basicConfig(level=level)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    logging.getLogger("partialize").setLevel(logging.ERROR)
    logging.getLogger("pfb").setLevel(logging.ERROR)
    logging.getLogger("psr_formats").setLevel(logging.ERROR)

    config = load_config(parsed.sub_config_name)

    test = TestMatlabDspsrPfbInversion(
        dspsr_bin=config["dspsr_bin"],
        os_factor=config["os_factor"],
        input_fft_length=config["input_fft_length"],
        input_overlap=config["input_overlap"],
        fft_window=config["fft_window"],
        deripple=config["deripple"],
        channels=config["channels"],
        fir_filter_taps=config["fir_filter_taps"],
        fir_filter_coeff_file_path=config["fir_filter_coeff_file_path"],
        blocks=config["blocks"],
        backend=config["backend"],
        dump_stage=config["dump_stage"],
        dm=config["dm"],
        period=config["period"],
        n_test=parsed.n_test,
        extra_dspsr_args=parsed.extra_args,
        save_output=parsed.save_output
    )

    if parsed.do_time:
        test.test_time_domain_impulse()
    if parsed.do_freq:
        test.test_complex_sinusoid()
    if parsed.do_simulated_pulsar:
        test.test_simulated_pulsar()

    test.finish()
