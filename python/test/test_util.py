import logging
import os
import unittest

import util

cur_dir = os.path.dirname(os.path.abspath(__file__))


class TestUtil(unittest.TestCase):

    def test_updir(self):

        self.assertTrue(util.updir(cur_dir, 0) == cur_dir)
        self.assertTrue(
            util.updir(cur_dir, 1) == os.path.dirname(cur_dir))
        self.assertTrue(
            util.updir(cur_dir, 2) == os.path.dirname(os.path.dirname(cur_dir))
        )

    def test_curdir(self):

        self.assertTrue(util.curdir(__file__) == cur_dir)


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    unittest.main()
