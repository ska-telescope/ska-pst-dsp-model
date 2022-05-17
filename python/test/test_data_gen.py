import unittest
import logging
import os
import glob
import time

import numpy as np

from data_gen.generate_test_vector import generate_test_vector
from data_gen.channelize import channelize
from data_gen.synthesize import synthesize
from data_gen.util import curdir

cur_dir = curdir(__file__)
data_dir = os.path.join(cur_dir, "test_data")
output_dir = cur_dir

module_logger = logging.getLogger(__name__)


def data_gen_test_case_factory():

    class TestDataGen(unittest.TestCase):

        @classmethod
        def tearDownClass(cls):
            for file_path in glob.glob(os.path.join(output_dir, "*.log")):
                os.remove(file_path)
            for file_path in glob.glob(os.path.join(output_dir, "*.dump")):
                os.remove(file_path)

    return TestDataGen


class TestGenerateTestVector(data_gen_test_case_factory()):

    time_domain_args = (1000, 0.1, 1)
    time_domain_kwargs = dict(n_pol=2,
                              output_dir=output_dir,
                              output_file_name="time_domain_impulse.dump",
                              dtype=np.complex64)

    freq_domain_args = (1000, 0.1, np.pi/4, 0.1)
    freq_domain_kwargs = dict(n_pol=2,
                              output_dir=output_dir,
                              output_file_name="complex_sinusoid.dump",
                              dtype=np.complex64)

    def test_generate_test_vectors_matlab(self):
        generator = generate_test_vector(backend="matlab", domain_name="time")
        dada_file = generator(*self.time_domain_args,
                              **self.time_domain_kwargs)

        self.assertTrue(self.time_domain_kwargs["output_file_name"]
                        in dada_file.file_path)

        generator = generate_test_vector(backend="matlab", domain_name="freq")
        dada_file = generator(*self.freq_domain_args,
                              **self.freq_domain_kwargs)

        self.assertTrue(self.freq_domain_kwargs["output_file_name"]
                        in dada_file.file_path)

    def test_generate_test_vectors_python(self):
        generator = generate_test_vector(backend="python", domain_name="time")
        dada_file = generator(*self.time_domain_args,
                              **self.time_domain_kwargs)
        self.assertTrue(self.time_domain_kwargs["output_file_name"]
                        in dada_file.file_path)

        generator = generate_test_vector(backend="python", domain_name="freq")
        dada_file = generator(*self.freq_domain_args,
                              **self.freq_domain_kwargs)

        self.assertTrue(self.freq_domain_kwargs["output_file_name"]
                        in dada_file.file_path)

        dada_file = generator(35840, domain_name="noise",
                              output_file_name="noise.dump",
                              output_dir="./", n_pol=2)

    def test_generate_test_vectors_default_name(self):
        original_val = self.time_domain_kwargs["output_file_name"]

        self.time_domain_kwargs["output_file_name"] = None
        generator = generate_test_vector(backend="python", domain_name="time")
        dada_file = generator(*self.time_domain_args,
                              **self.time_domain_kwargs)
        expected_file_name = ("time_domain_impulse.1000."
                              "0.100-1.000.2.single.python.dump")

        self.assertTrue((os.path.basename(dada_file.file_path) ==
                         expected_file_name))

        self.time_domain_kwargs["output_file_name"] = original_val


# @unittest.skip("")
class TestChannelize(data_gen_test_case_factory()):

    input_data_path = os.path.join(
        data_dir, "complex_sinusoid.dump")

    channelize_kwargs = dict(
        output_file_name=None,
        output_dir=output_dir,
    )

    def test_channelize_matlab(self):

        channelizer = channelize(backend="matlab", output_dir=output_dir)
        t0 = time.time()
        channelizer(
            self.input_data_path, **self.channelize_kwargs)
        delta = time.time() - t0
        module_logger.info((f"test_channelize_matlab: "
                            f"matlab channelizer took {delta:.3f} seconds"))

    def test_channelize_python(self):
        channelizer = channelize(backend="python", output_dir=output_dir)
        t0 = time.time()
        channelizer(
            self.input_data_path, **self.channelize_kwargs)
        delta = time.time() - t0
        module_logger.info((f"test_channelize_python: "
                            f"python channelizer took {delta:.3f} seconds"))


# @unittest.skip("")
class TestSynthesize(data_gen_test_case_factory()):

    input_data_path = os.path.join(
        data_dir, "channelize.256.4-3.dump")

    synthesize_kwargs = dict(
        input_fft_length=1024,
        input_overlap=128,
        fft_window_str="tukey",
        output_file_name=None,
        output_dir=output_dir,
        deripple=True)

    def test_synthesize_matlab(self):
        synthesizer = synthesize(backend="matlab", **self.synthesize_kwargs)
        synthesizer(
            self.input_data_path)

    def test_synthesize_python(self):
        synthesizer = synthesize(backend="python", **self.synthesize_kwargs)
        synthesizer(
            self.input_data_path)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    unittest.main()
