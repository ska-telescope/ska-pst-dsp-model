import unittest
import logging
import os
import glob
import time

import numpy as np

from data_gen import generate_test_vector, channelize, synthesize

test_dir = os.path.dirname(os.path.abspath(__file__))
test_data_dir = os.path.join(test_dir, "test_data")

module_logger = logging.getLogger(__name__)


class TestDataGen(unittest.TestCase):

    time_domain_args = ("time", 1000, 0.1, 1)
    time_domain_kwargs = dict(n_pol=2,
                              output_dir="./",
                              output_file_name="time_domain_impulse.dump",
                              dtype=np.complex64)

    freq_domain_args = ("freq", 1000, 0.1, np.pi/4, 0.1)
    freq_domain_kwargs = dict(n_pol=2,
                              output_dir="./",
                              output_file_name="complex_sinusoid.dump",
                              dtype=np.complex64)

    channelized_data_file_path = os.path.join(
        test_data_dir, "polyphase_analysis_alt.complex_sinusoid.dump")
    channelizer_input_data_file_path = os.path.join(
        test_data_dir, "complex_sinusoid.dump")

    @unittest.skip("")
    def test_generate_test_vectors_matlab(self):
        generator = generate_test_vector(backend="matlab")
        dada_file = generator(*self.time_domain_args,
                              **self.time_domain_kwargs)

        self.assertTrue(self.time_domain_kwargs["output_file_name"]
                        in dada_file.file_path)
        dada_file = generator(*self.freq_domain_args,
                              **self.freq_domain_kwargs)
        self.assertTrue(self.freq_domain_kwargs["output_file_name"]
                        in dada_file.file_path)

    @unittest.skip("")
    def test_generate_test_vectors_python(self):
        generator = generate_test_vector(backend="python")
        dada_file = generator(*self.time_domain_args,
                              **self.time_domain_kwargs)
        self.assertTrue(self.time_domain_kwargs["output_file_name"]
                        in dada_file.file_path)

        dada_file = generator(*self.freq_domain_args,
                              **self.freq_domain_kwargs)

        self.assertTrue(self.freq_domain_kwargs["output_file_name"]
                        in dada_file.file_path)

        dada_file = generator("noise", 35840, output_file_name="noise.dump",
                              output_dir="./", n_pol=2)

    @unittest.skip("")
    def test_generate_test_vectors_default_name(self):
        original_val = self.time_domain_kwargs["output_file_name"]

        self.time_domain_kwargs["output_file_name"] = None
        generator = generate_test_vector(backend="python")
        dada_file = generator(*self.time_domain_args,
                              **self.time_domain_kwargs)
        expected_file_name = ("time_domain_impulse.1000."
                              "0.100-1.000.2.single.python.dump")

        self.assertTrue((os.path.basename(dada_file.file_path) ==
                         expected_file_name))

        self.time_domain_kwargs["output_file_name"] = original_val

    # @unittest.skip("")
    def test_channelize_matlab(self):

        channelizer = channelize(backend="matlab")
        t0 = time.time()
        channelizer(
            self.channelizer_input_data_file_path, 8, "8/7")
        delta = time.time() - t0
        module_logger.info((f"test_channelize_matlab: "
                            f"matlab channelizer took {delta:.3f} seconds"))

    # @unittest.skip("")
    def test_channelize_python(self):
        channelizer = channelize(backend="python")
        t0 = time.time()
        channelizer(
            self.channelizer_input_data_file_path, 8, "8/7")
        delta = time.time() - t0
        module_logger.info((f"test_channelize_python: "
                            f"python channelizer took {delta:.3f} seconds"))

    @unittest.skip("")
    def test_synthesize_matlab(self):
        synthesizer = synthesize(backend="matlab")
        synthesizer(
            self.channelized_data_file_path, 512)

    @unittest.skip("")
    def test_synthesize_python(self):
        pass

    @classmethod
    def tearDownClass(cls):
        for file_path in glob.glob("./*.log"):
            os.remove(file_path)
        for file_path in glob.glob("./*.dump"):
            os.remove(file_path)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    unittest.main()
