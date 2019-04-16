import os
import argparse
import logging

import psr_formats

from . import util
from .config import config, build_dir

__all__ = [
    "synthesize"
]

module_logger = logging.getLogger(__name__)


def synthesize(backend: str = "matlab"):
    """
    Synthesize data contained in some multichannel input data file.
    Use either matlab or Python backends.

    Sample Matlab command:

    .. code-block:: bash
        ./build/synthesize \
            channelized_data.dump \
            16384 test_synthesis.dump ./ 1
    """
    def _synthesize(input_data_file_path,
                    input_fft_length: int = None,
                    output_file_name: str = None,
                    output_dir: str = "./",):
        """

        """
        if input_fft_length is None:
            input_fft_length = config["input_fft_length"]

        module_logger.debug((f"_synthesize: "
                             f"input_data_file_path={input_data_file_path}, "
                             f"input_fft_length={input_fft_length}, "
                             f"output_file_name={output_file_name}, "
                             f"output_dir={output_dir}"))

        matlab_cmd_str = "synthesize"
        output_base = (f"{matlab_cmd_str}.{input_fft_length}")

        output_base, log_file_name, output_file_name = \
            util.create_output_file_names(output_file_name, output_base)

        if backend == "matlab":

            cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                       f"{input_data_file_path} "
                       f"{input_fft_length} "
                       f"{output_file_name} {output_dir} 1")

            module_logger.debug(f"_synthesize: cmd_str={cmd_str}")

            util.run_cmd(cmd_str, log_file_path=os.path.join(
                output_dir, log_file_name))
            return psr_formats.DADAFile(
                os.path.join(output_dir, output_file_name)).load_data()

        elif backend == "python":
            raise NotImplementedError(("synthesize not "
                                       "implemented in Python"))

    return _synthesize


def create_parser():

    parser = argparse.ArgumentParser(
        description="Synthesize multichannel data")

    parser.add_argument("-i", "--input-files",
                        dest="input_file_paths",
                        nargs="+", type=str,
                        required=True)

    parser.add_argument("-fft", "--input_fft_length",
                        dest="input_fft_length", type=int, required=True)

    parser.add_argument("-b", "--backend",
                        dest="backend", type=str, required=False,
                        default="python",
                        help=("Specify a backend to use, "
                              "either \"matlab\" or \"python\""))

    parser.add_argument("-od", "--output_dir",
                        dest="output_dir", type=str, required=False,
                        default="./")

    parser.add_argument("-v", "--verbose",
                        dest="verbose", action="store_true")

    return parser


if __name__ == "__main__":
    parsed = create_parser().parse_args()
    level = logging.INFO
    if parsed.verbose:
        level = logging.DEBUG
    logging.basicConfig(level=level)
    synthesizer = synthesize(backend=parsed.backend.lower())
    for file_path in parsed.input_file_paths:
        output_file_name = "synthesized." + os.path.basename(file_path)
        synthesizer(
            file_path,
            input_fft_length=parsed.input_fft_length,
            output_dir=parsed.output_dir,
            output_file_name=output_file_name
        )
