# test_dedispersion.py
import unittest
import logging


class TestDedispersion(unittest.TestCase):
    """
    Run psrdiff on the output of running data through dspsr with no parameters
    (simple dedispersion) and on the output of the InverseFilterbank, operating
    on channelized data
    """

    def test_complex_sinusoid(self):
        pass

    def test_time_domain_impulse(self):
        pass

    def test_simulated_pulsar(self):
        pass


if __name__ == "__main__":
    logging.basicConfig(logging.DEBUG)
    unittest.main()
