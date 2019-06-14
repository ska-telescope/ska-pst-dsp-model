# Verify that dspsr's InverseFilterbankEngineCPU works for a variety of
# inputs.
import unittest
import logging
import os

import data_gen

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")
products_dir = os.path.join(base_dir, "products")


class VerifyDSPSRPFBInversion(unittest.TestCase):

    simulated_pulsar_file_path = os.path.join(
        data_dir, "simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump"
    )

    @classmethod
    def init(cls):
        """
        Channelize simulated pulsar data
        """
        channelizer = data_gen.channelize(
            backend="python",
            output_dir=data_dir)
        cls.channelized_file_path = channelizer(
            cls.simulated_pulsar_file_path)
        deripple_str = "-dr" if data_gen.config["deripple"] else ""
        cls.input_fft_length = data_gen.config['input_fft_length']
        cls.inversion_extra_args = (
            f"-IF {{}}:{{}}"
            f":{data_gen.config['input_overlap']} "
            f"{deripple_str} "
            f"-fft-window {data_gen.config['fft_window']} -V")
        cls.dspsr_kwargs = dict(
            dm=data_gen.config["dm"],
            period=data_gen.config["period"]
        )

    def test_vanilla(self):

        data_gen.run_dspsr(
            self.simulated_pulsar_file_path,
            output_dir=products_dir,
            output_file_name="test_vanilla",
            **self.dspsr_kwargs
        )

    @classmethod
    def build_test_cases(cls, skips=None):
        if skips is None:
            skips = []
        test_method_names = [
            "test_single_channel_after_dedispersion",
            "test_multi_channel_after_dedispersion",
            "test_single_channel_during_dedispersion",
            "test_multi_channel_during_dedispersion"
        ]

        test_method_args = [
            ("1", cls.input_fft_length),
            ("16", cls.input_fft_length),
            ("1", "D"),
            ("16", "D")
        ]

        def test_method_factory(method_name, args):
            def test_method(self):
                data_gen.run_dspsr(
                    self.channelized_file_path.file_path,
                    extra_args=self.inversion_extra_args.format(*args),
                    output_dir=products_dir,
                    output_file_name=method_name,
                    **self.dspsr_kwargs
                )
            test_method.__name__ = method_name
            return test_method

        def _build_cases(names, args):
            if len(names) == 0:
                return
            else:
                name, arg = names.pop(0), args.pop(0)
                method = test_method_factory(name, arg)
                if name in skips:
                    method = unittest.skip("")(method)
                setattr(cls, name, method)
                _build_cases(names, args)

        _build_cases(test_method_names, test_method_args)


if __name__ == "__main__":
    VerifyDSPSRPFBInversion.init()
    VerifyDSPSRPFBInversion.build_test_cases(skips=[
        # "test_single_channel_after_dedispersion",
        # "test_multi_channel_after_dedispersion",
        # "test_single_channel_during_dedispersion"
        # "test_multi_channel_during_dedispersion"
    ])
    logging.basicConfig(level=logging.ERROR)
    unittest.main()
