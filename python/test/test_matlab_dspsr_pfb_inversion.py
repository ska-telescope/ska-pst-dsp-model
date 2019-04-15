import unittest
import logging
import os

import numpy as np
import matplotlib.pyplot as plt
import pfb.rational
import comparator

import util
from data_gen import generate_test_vector, channelize, synthesize
from run_dspsr_with_dump import run_dspsr_with_dump
from config import load_config


module_logger = logging.getLogger(__name__)

plt.ion()

config = load_config()
test_dir = util.curdir(__file__)
base_dir = util.updir(test_dir, 2)
config_dir = os.path.join(base_dir, "config")
data_dir = os.path.join(base_dir, "data")


def default_comparison(
    domain_name: str,
    domain_args: tuple,
    output_dir: str,
    test_vector_generator: callable,
    channelizer: callable,
    synthesizer: callable
):
    header_file_path = os.path.join(
        config_dir, config["header_file_path"])
    fir_filter_path = os.path.join(
        config_dir, config["fir_filter_coeff_file_path"])
    test_vector_dada_file = test_vector_generator(
        domain_name,
        *domain_args,
        n_pol=config["n_pol"],
        header_template=header_file_path,
        output_dir=output_dir)
    channelized_file_name = "channelized." + \
        os.path.basename(test_vector_dada_file.file_path)
    synthesized_file_name = "synthesized." + \
        os.path.basename(test_vector_dada_file.file_path)

    channelized_dada_file = channelizer(
        test_vector_dada_file.file_path,
        config["channels"],
        config["os_factor"],
        fir_filter_path=fir_filter_path,
        output_file_name=channelized_file_name,
        output_dir=output_dir)
    synthesized_dada_file = synthesizer(
        channelized_dada_file.file_path,
        config["input_fft_length"],
        output_file_name=synthesized_file_name,
        output_dir=output_dir)

    ar, dump = run_dspsr_with_dump(
        channelized_dada_file.file_path,
        config["dm"],
        config["period"],
        output_dir=output_dir,
        dump_stage=config["dump_stage"],
        extra_args=f"-IF 1:{config['input_fft_length']} -V"
    )
    dump = pfb.formats.DADAFile(dump).load_data()
    return synthesized_dada_file, dump


def multi_domain_comparison(
    domain_names,
    test_method_names,
    domain_test_parameters,
    domain_args
):

    def test_method_factory(domain_name, domain_test_parameters,
                            domain_args, test_method_name):
        def _test_method(self):
            for test_param in domain_test_parameters:
                args = [self.n_samples, test_param]
                args.extend(domain_args)
                matlab_dump, dspsr_dump = default_comparison(
                    domain_name,
                    args,
                    self.output_dir,
                    self.__class__.generator,
                    self.__class__.channelizer,
                    self.__class__.synthesizer
                )
                res_op, res_prod = self.comp.cartesian(
                    matlab_dump.data.flatten(),
                    dspsr_dump.data.flatten() / self.normalize
                )
                # comparator.plot_operator_result(res_op)
                # input(">>> ")
                mean_diff = list(res_prod["diff"]["mean"])[0][1]
                self.assertTrue(all([d < self.thresh for d in mean_diff]))
                module_logger.info((f"{test_method_name}: "
                                    f"param={test_param}\n"
                                    f"{res_prod['diff']:.6e}"))
        return _test_method

    def _multi_domain_comparison(cls):
        for i in range(len(domain_names)):
            test_method = test_method_factory(
                domain_names[i],
                domain_test_parameters[i],
                domain_args[i],
                test_method_names[i])
            setattr(cls, test_method_names[i], test_method)
        return cls
    return _multi_domain_comparison


@multi_domain_comparison(
    ["time", "freq"],
    ["test_time_domain_impulse", "test_complex_sinusoid"],
    [[0.11], [0.11]],
    [[1], [np.pi/4, 0.1]]
)
class TestMatlabDspsrPfbInversion(unittest.TestCase):
    """
    These tests attempt to determine whether the PFB inversion algorithm
    as implemented in the PST Matlab model and dspsr do the same thing,
    within the limits of 32-bit float point accuracy.

    Note that offsets and frequencies are expressed as fractions of total
    size of input array.
    """
    thresh = 1e-5
    output_dir = data_dir
    # time_domain_params = {
    #     # "offset": np.arange(0.01, 1, 0.05),
    #     "offset": [0.11],
    #     "width": [1]
    # }
    #
    # freq_domain_params = {
    #     # "frequency": np.arange(0.01, 1, 0.05),
    #     "frequency": [0.11],
    #     "phase": [np.pi/4.],
    #     "bin_offset": [0.1]
    # }

    @classmethod
    def setUpClass(cls):
        os_factor = pfb.rational.Rational(*config["os_factor"].split("/"))
        normalize = config["input_fft_length"] * config["channels"]
        n_samples = os_factor.normalize(config["input_fft_length"]) * \
            config["channels"] * config["blocks"]
        cls.normalize = normalize
        cls.n_samples = n_samples
        cls.generator = generate_test_vector(
            backend=config["backend"]["test_vectors"])
        cls.channelizer = channelize(
            backend=config["backend"]["channelize"])
        cls.synthesizer = synthesize(
            backend=config["backend"]["synthesize"])

        comp = comparator.SingleDomainComparator(name="time")
        comp.operators["diff"] = lambda a, b: a - b
        comp.operators["this"] = lambda a: a

        comp.products["sum"] = np.sum
        comp.products["mean"] = np.mean

        cls.comp = comp

    def test_simulated_pulsar(self):
        """
        Determine whether dspsr and matlab produce the same result when
        inverting simulated pulsar data.
        """
        pass


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    unittest.main()
