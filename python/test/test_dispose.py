# test_dispose.py
import unittest
import logging
import functools
import os

import psr_formats

from data_gen import dispose


class TestDispose(unittest.TestCase):

    def test_dispose(self):

        def create_file(a):
            with open(a, "w"):
                pass

        def f(a):
            create_file(a)
            return a

        def g(a, b):
            create_file(a)
            return psr_formats.DADAFile(a)

        file_paths = ["test.dump", "test.0.dump"]
        with dispose(f(file_paths[0]), g(file_paths[1], None)) as dump_files:
            pass

        self.assertFalse(os.path.exists(dump_files[0]))
        self.assertFalse(os.path.exists(dump_files[1].file_path))

        with dispose(functools.partial(f, file_paths[0])) as dump_file:
            pass

        self.assertFalse(os.path.exists(dump_file))


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    unittest.main()
