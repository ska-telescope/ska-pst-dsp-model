import os
import argparse
import logging

import partialize
import psr_formats
import pfb.format_handler
import pfb.fft_windows

from . import util
from .config import config, build_dir

__all__ = [
    "synthesize"
]

module_logger = logging.getLogger(__name__)

fft_window_lookup = {
    "no_window": lambda a, *args: pfb.fft_windows.no_window(a),
    "tukey": pfb.fft_windows.tukey_window
}


@partialize.partialize
def synthesize(input_data_file_path,
               input_fft_length: int = None,
               input_overlap: int = None,
               fft_window_str: str = "no_window",
               output_file_name: str = None,
               output_dir: str = "./",
               deripple: bool = True,
               backend: str = "matlab"):
    """
    Synthesize data contained in some multichannel input data file.
    Use either matlab or Python backends.

    Sample Matlab command:

    .. code-block:: bash
        ./build/synthesize \
            channelized_data.dump \
            16384 test_synthesis.dump ./ 1
    """
    if input_fft_length is None:
        input_fft_length = config["input_fft_length"]

    if input_overlap is None:
        input_overlap = config["input_overlap"]

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
        deripple_int = 1 if deripple else 0
        cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                   f"{input_data_file_path} "
                   f"{input_fft_length} "
                   f"{output_file_name} {output_dir} "
                   f"1 1 {deripple_int} {input_overlap} {fft_window_str}")

        module_logger.debug(f"_synthesize: cmd_str={cmd_str}")

        util.run_cmd(cmd_str, log_file_path=os.path.join(
            output_dir, log_file_name))
        return psr_formats.DADAFile(
            os.path.join(output_dir, output_file_name)).load_data()

    elif backend == "python":
        input_data_file = psr_formats.DADAFile(input_data_file_path)
        fft_window_func = fft_window_lookup[fft_window_str]
        fft_window = fft_window_func(input_fft_length, input_overlap)
        synthesizer = pfb.format_handler.PSRFormatSynthesizer(
            input_overlap=input_overlap,
            fft_window=fft_window,
            input_fft_length=input_fft_length,
            apply_deripple=deripple
        )
        output_data_file = synthesizer(
            input_data_file,
            output_dir=output_dir,
            output_file_name=output_file_name
        )
        return output_data_file


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
