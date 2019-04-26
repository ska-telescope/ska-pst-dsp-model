import unittest
import os
import logging

import data_gen

import data_gen.util

test_dir = data_gen.util.curdir(__file__)
base_dir = data_gen.util.updir(test_dir, 2)
data_dir = os.path.join(base_dir, "data")


class TestDSPSRUtil(unittest.TestCase):

    test_log_file_path = os.path.join(
        test_dir, "test_data", "test_log_file.log"
    )

    simulated_pulsar_file_path = os.path.join(
        data_dir, "simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump"
    )
    psrtxt_test_file_path = os.path.join(
        test_dir, "test_data", "psrdiff.out"
    )

    test_load_psrtxt_data_file_path = os.path.join(
        test_dir, "test_data", "test_psrtxt.txt"
    )

    psrdiff_test_file_paths = [os.path.join(
        test_dir, "test_data", f
    ) for f in ["channelize.8.8-7.ar",
                "simulated_pulsar.noise_0.0.nseries_3.ndim_2.ar"]]

    file_paths = set()

    def test_run_dspsr(self):

        output = data_gen.run_dspsr(
            self.simulated_pulsar_file_path,
            output_dir=test_dir
        )
        for file_path in output:
            self.assertTrue(os.path.exists(file_path))

        self.__class__.file_paths |= set(output)

    def test_run_dspsr_with_dump(self):

        output = data_gen.run_dspsr_with_dump(
            self.simulated_pulsar_file_path,
            output_dir=test_dir,
            dump_stage="Detection"
        )
        for file_path in output:
            if hasattr(file_path, "file_path"):
                file_path = file_path.file_path
            self.assertTrue(os.path.exists(file_path))

        self.__class__.file_paths |= set(output)

    def test_psrdiff(self):
        output = data_gen.run_psrdiff(
            *self.psrdiff_test_file_paths,
            output_dir=test_dir
        )
        self.__class__.file_paths |= set(output)

    def test_psrtxt(self):
        output = data_gen.run_psrtxt(
            self.psrtxt_test_file_path,
            output_dir=test_dir
        )
        self.__class__.file_paths |= set(output)

    def test_find_in_log(self):
        val = data_gen.find_in_log(
            self.test_log_file_path,
            "output_fft_length")
        self.assertTrue(val == "229376")

        with self.assertRaises(RuntimeError):
            data_gen.find_in_log(
                self.test_log_file_path,
                "foo")

    def test_load_psrtxt_data(self):

        data = data_gen.load_psrtxt_data(
            self.test_load_psrtxt_data_file_path)
        self.assertTrue(data[3, 330] == -0.000184)

    @classmethod
    def tearDownClass(cls):
        print(cls.file_paths)
        for file_path in cls.file_paths:
            if hasattr(file_path, "file_path"):
                file_path = file_path.file_path
            os.remove(file_path)


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    unittest.main()
