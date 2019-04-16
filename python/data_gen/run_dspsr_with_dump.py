# run_dspsr_with_dump.py
import os
import glob
import logging
import subprocess
import argparse
import shlex
import typing

import psr_formats

from .config import config

module_logger = logging.getLogger(__name__)

__all__ = [
    "run_dspsr_with_dump"
]


def run_dspsr_with_dump(file_path: str,
                        dm: float = None,
                        period: float = None,
                        output_dir: str = None,
                        output_file_name: str = None,
                        dump_stage: str = "Detection",
                        extra_args: str = None) -> typing.Tuple[str]:
    """
    Run `dspsr`, creating a dump file after a specified step.

    Usage:

    Run inverse filterbank, saving before Convolution step

    .. code-block:: python

        dada_file = run_dspsr_with_dump(
            "channelized.dump",
            dm=2.64476,
            period=0.00575745,
            output_dir="./",
            dump_stage="Convolution",
            extra_args="-IF 1:16384"
        )

    Args:
        file_path (str): Path to file containing data on which to operate
        dm (float): dispersion measure
        period (float): pulsar period
        output_dir (str): directory where dump file should go
        output_file_name (str): name of output dump file
        dump_stage (str): stage at which to create dump file
        extra_args (str): Extra arguments to pass to dspsr command.
    Returns:
        psr_formats.DADAFile: DADAFile object corresponding to dump file
    """
    if dm is None:
        dm = config["dm"]
    if period is None:
        period = config["period"]

    file_dir = os.path.dirname(file_path)
    file_name = os.path.basename(file_path)
    if output_file_name is None:
        file_name_base = os.path.splitext(file_name)[0]
    else:
        file_name_base = output_file_name

    if output_dir is None:
        output_dir = file_dir

    if extra_args is None:
        extra_args = ""

    dump_stage = dump_stage.capitalize()

    output_ar = os.path.join(output_dir, file_name_base)
    output_dump = os.path.join(
        output_dir, f"pre_{dump_stage}.{file_name_base}.dump")
    output_log = os.path.join(
        output_dir, f"{file_name_base}.log")

    module_logger.debug((f"run_dspsr_with_dump: "
                         f"dumping after {dump_stage} operation"))
    module_logger.debug(f"run_dspsr_with_dump: output archive: {output_ar}")
    module_logger.debug(f"run_dspsr_with_dump: output dump: {output_dump}")
    module_logger.debug(f"run_dspsr_with_dump: output log: {output_log}")
    dspsr_cmd_str = (f"dspsr -c {period} -D {dm} {file_path} "
                     f"-O {output_ar} -dump {dump_stage} {extra_args}")

    module_logger.debug(f"run_dspsr_with_dump: dspsr command: {dspsr_cmd_str}")

    after_cmd_str = f"mv pre_{dump_stage}.dump {output_dump}"

    # cleanup_cmd_str = "rm *.dat"

    try:
        with open(output_log, "w") as log_file:
            dspsr_cmd = subprocess.run(shlex.split(dspsr_cmd_str),
                                       stdout=log_file,
                                       stderr=log_file)
        if dspsr_cmd.returncode == 0:
            subprocess.run(shlex.split(after_cmd_str))
    except subprocess.CalledProcessError as err:
        print(f"Couldn't execute command {dspsr_cmd_str}: {err}")
    finally:
        dat_files = glob.glob("*.dat")
        if len(dat_files) > 0:
            for dat_file in dat_files:
                os.remove(dat_file)
            # subprocess.run(cleanup_cmd_str, shell=True)
    return psr_formats.DADAFile(output_dump).load_data()
    # return (f"{output_ar}.ar", output_dump)


def create_parser():
    parser = argparse.ArgumentParser(
        description="run dspsr with dump file")

    parser.add_argument("-i", "--input-file",
                        dest="input_file_path",
                        required=True)

    parser.add_argument("-a", "--args",
                        dest="extra_args",
                        required=False)

    parser.add_argument("--dump-stage",
                        default="Detection",
                        dest="dump_stage", required=False)

    parser.add_argument("-od", "--output-dir",
                        dest="output_dir",
                        type=str,
                        required=False)

    parser.add_argument("-pf", "--param-file",
                        dest="pulsar_param_file_path",
                        type=str,
                        default=None,
                        required=False)

    return parser


if __name__ == '__main__':
    parsed = create_parser().parse_args()
    run_dspsr_with_dump(
        parsed.input_file_path,
        dm=config["dm"],
        period=config["period"],
        dump_stage=parsed.dump_stage,
        output_dir=parsed.output_dir,
        extra_args=parsed.extra_args
    )
