import unittest
import logging
import os

import numpy as np

from config import load_config

config = load_config()
test_dir = os.path.dirname(os.path.abspath(__file__))
config_dir = os.path.join(os.path.dirname(os.path.dirname(test_dir)), "config")


class TestMatlabDspsrPfbInversion(unittest.TestCase):
    """
    These tests attempt to determine whether the PFB inversion algorithm
    as implemented in the PST Matlab model and dspsr do the same thing,
    within the limits of 32-bit float point accuracy.

    Note that offsets and frequencies are expressed as fractions of total
    size of input array.
    """

    time_domain_params = {
        "offset": np.arange(0.01, 1, 0.05),
        "width": [1]
    }

    freq_domain_params = {
        "frequency": np.arange(0.01, 1, 0.05),
        "phase": [np.pi/4.],
        "bin_offset": [0.1]
    }

    freq_domain_formatter = "f-0.100_b-0.100_p-0.785"
    time_domain_formatter = ""

    def test_time_domain_impulse(self):
        """
        Determine whether dspsr and matlab invert time domain impulses of
        varying offsets.
        """
        pass

    def test_complex_sinusoid(self):
        """
        Determine with dspsr and matlab invert complex sinsuoids of varying
        frequency.
        """
        pass

    def test_simulated_pulsar(self):
        """
        Determine whether dspsr and matlab produce the same result when
        inverting simulated pulsar data.
        """
        pass


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    unittest.main()
