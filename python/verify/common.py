import argparse

__all__ = [
    "create_parser"
]




def create_parser(**kwargs):

    parser = argparse.ArgumentParser(**kwargs)

    parser.add_argument("-t", "--do-time",
                        dest="do_time", action="store_true")

    parser.add_argument("-f", "--do-freq",
                        dest="do_freq", action="store_true")

    parser.add_argument("-n", "--n-test",
                        dest="n_test", action="store",
                        default=100, type=int,
                        help="Specify the number of test vectors to use")

    parser.add_argument("-c", "--config",
                        dest="sub_config_name", action="store",
                        default="low", type=str,
                        help="Specify which sub configuration to use")

    parser.add_argument("--save-output",
                        dest="save_output", action="store_true",
                        help="Indicate whether to save intermediate products")

    parser.add_argument(
        "--extra-args",
        dest="extra_args", action="store",
        default="", type=str,
        help="Specify any additional arguments to pass to dspsr")

    parser.add_argument("-v", "--verbose",
                        dest="verbose", action="store_true")

    return parser
