import argparse
import os
import logging

import pfb.pfb_channelizer
import psr_formats

from . import util
from .config import config, config_dir, build_dir

__all__ = [
    "channelize"
]

module_logger = logging.getLogger(__name__)


def channelize(backend: str = "matlab"):
    """
    channelize data contained in some single channel input data file.
    Use either matlab or Python backends.

    Sample Matlab command line call
    ./build/channelize single_channel.dump 8 8/7 \
        config/OS_Prototype_FIR_8.mat channelized_data.dump ./ 1
    """

    def _channelize(input_data_file_path: str,
                    channels: int = None,
                    os_factor_str: str = None,
                    fir_filter_path: str = None,
                    output_file_name: str = None,
                    output_dir: str = "./",):

        if channels is None:
            channels = config["channels"]

        if os_factor_str is None:
            os_factor_str = config["os_factor"]

        if fir_filter_path is None:
            fir_filter_path = os.path.join(
                config_dir, config["fir_filter_coeff_file_path"])

        module_logger.debug((f"_channelize: "
                             f"input_data_file_path={input_data_file_path}, "
                             f"channels={channels}, "
                             f"os_factor_str={os_factor_str}, "
                             f"fir_filter_path={fir_filter_path}, "
                             f"output_file_name={output_file_name}, "
                             f"output_dir={output_dir}"))

        matlab_cmd_str = "channelize"

        output_base = (f"{matlab_cmd_str}.{channels}."
                       f"{'-'.join(os_factor_str.split('/'))}")

        output_base, log_file_name, output_file_name = \
            util.create_output_file_names(output_file_name, output_base)

        if backend == "matlab":

            cmd_str = (f"{os.path.join(build_dir, matlab_cmd_str)} "
                       f"{input_data_file_path} "
                       f"{channels} {os_factor_str} {fir_filter_path} "
                       f"{output_file_name} {output_dir} 1")

            module_logger.debug(f"_synthesize: cmd_str={cmd_str}")

            util.run_cmd(cmd_str, log_file_path=os.path.join(
                output_dir, log_file_name))

            return psr_formats.DADAFile(
                os.path.join(output_dir, output_file_name)).load_data()

        elif backend == "python":
            input_data_file = psr_formats.DADAFile(
                input_data_file_path).load_data()
            channelizer = pfb.pfb_channelizer.PFBChannelizer.from_input_files(
                input_data_file,
                fir_filter_path
            )
            channelizer.channelize(
                channels, os_factor_str,
                output_file_path=os.path.join(output_dir, output_file_name)
            )
            channelizer.dump_file(
                header_kwargs={"UTC_START": input_data_file["UTC_START"]})
            return channelizer.output_data_file

    return _channelize


def create_parser():

    parser = argparse.ArgumentParser(
        description="Channelize file(s)")

    parser.add_argument("-i", "--input-files",
                        dest="input_file_paths",
                        nargs="+", type=str,
                        required=True)

    parser.add_argument("-c", "--channels",
                        dest="channels", type=int, required=True)

    parser.add_argument("-osf", "--os_factor",
                        dest="os_factor", type=str, required=True)

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
    channelizer = channelize(backend=parsed.backend.lower())
    for file_path in parsed.input_file_paths:
        output_file_name = "channelized." + os.path.basename(file_path)
        channelizer(
            file_path,
            channels=parsed.channels,
            os_factor_str=parsed.os_factor,
            output_dir=parsed.output_dir,
            output_file_name=output_file_name
        )
