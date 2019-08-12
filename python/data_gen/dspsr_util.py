# dspsr_util.py
import os
import glob
import logging
import subprocess
import argparse
import shlex
import typing
import functools

import numpy as np
import psr_formats

from .config import config

module_logger = logging.getLogger(__name__)

__all__ = [
    "run_dspsr_with_dump",
    "run_dspsr",
    "run_psrdiff",
    "run_psrtxt",
    "load_psrtxt_data",
    "find_in_log",
    "BaseRunner"
]


def _coro(func):
    @functools.wraps(func)
    def wrapped(*args, **kwargs):
        res = func(*args, **kwargs)
        next(res)
        return res
    return wrapped


class Singleton(type):

    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(Singleton, cls).__call__(
                *args, **kwargs)
        return cls._instances[cls]


class BaseRunner(metaclass=Singleton):

    def __init__(self):
        self.output_dir = None
        self.output_file_name_base = None
        self.extra_args = None

    def _get_file_base(self, file_path: str, output_file_name: str = None):
        file_name = os.path.basename(file_path)
        if output_file_name is not None:
            file_name = output_file_name

        file_name_base = os.path.splitext(file_name)[0]

        return file_name_base

    def _reset(self):
        self.output_dir = None
        self.output_file_name_base = None
        self.extra_args = None

    def __call__(self, *args, **kwargs):
        res = self.call(*args, **kwargs)
        self._reset()
        return res

    def call(self,
             file_path: str,
             output_file_name: str = None,
             output_dir: str = None,
             extra_args: str = ""):

        self.output_file_name_base = self._get_file_base(
            file_path, output_file_name)

        if output_dir is None:
            output_dir = os.path.dirname(file_path)
        self.output_dir = output_dir
        self.extra_args = extra_args

    @staticmethod
    def chain(*callbacks):
        """
        Chain callbacks together
        """
        def _chain(*args):
            res = []
            res.append(callbacks[0](*args))
            for callback in callbacks[1:]:
                if hasattr(res[-1], "format"):
                    res.append(callback(res[-1]))
                else:
                    res.append(callback(res[-1][0]))
            return res

        return _chain


class DspsrRunner(BaseRunner):
    """
    Run `dspsr`

    Usage:

    Run inverse filterbank

    .. code-block:: python
        run_dspsr =
        ar, log = run_dspsr(
            "channelized.dump",
            dm=2.64476,
            period=0.00575745,
            output_dir="./",
            extra_args="-IF 1:16384"
        )
    """
    @_coro
    def _call(self,
              file_path: str,
              dspsr_bin: str = None,
              dm: float = None,
              period: float = None,
              **kwargs):
        """
         Args:
             file_path (str): Path to file containing data on which to operate
             dm (float): dispersion measure
             period (float): pulsar period
             kwargs (dict): passed to parent class call
         Returns:
             tuple: tuple with archive file and log file from dspsr command
        """
        super(DspsrRunner, self).call(file_path, **kwargs)

        yield

        if dm is None:
            dm = config["dm"]
        if period is None:
            period = config["period"]
        if dspsr_bin is None:
            dspsr_bin = "dspsr"

        output_ar = os.path.join(self.output_dir, self.output_file_name_base)
        output_log = os.path.join(
            self.output_dir, f"{self.output_file_name_base}.log")

        module_logger.debug(f"run_dspsr: output archive: {output_ar}")
        module_logger.debug(f"run_dspsr: output log: {output_log}")
        dspsr_cmd_str = (f"{dspsr_bin} -c {period} -D {dm} {file_path} "
                         f"-O {output_ar} {self.extra_args}")

        module_logger.info(f"run_dspsr: dspsr command: {dspsr_cmd_str}")

        try:
            with open(output_log, "w") as log_file:
                dspsr_cmd = subprocess.run(shlex.split(dspsr_cmd_str),
                                           stdout=log_file,
                                           stderr=log_file)
            if dspsr_cmd.returncode == 0:
                after_cmd_str = (yield)
                if after_cmd_str is not None:
                    subprocess.run(shlex.split(after_cmd_str))
        except subprocess.CalledProcessError as err:
            module_logger.error(
                f"Couldn't execute command {dspsr_cmd_str}: {err}")
        finally:
            dat_files = glob.glob("*.dat")
            if len(dat_files) > 0:
                for dat_file in dat_files:
                    os.remove(dat_file)
        ar = f"{output_ar}.ar"
        # if not os.path.exists(os.path.join(self.output_dir, ar)):
        #     ar = f"{output_ar}_0002.ar"

        yield (ar, output_log)

    def call(self, *args, **kwargs):
        coro = self._call(*args, **kwargs)
        next(coro)
        return coro.send(None)


class DspsrDumpRunner(DspsrRunner):
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
        kwargs (dict): passed to _run_dspsr
    Returns:
        psr_formats.DADAFile: DADAFile object corresponding to dump file
    """
    def call(self, *args,
             dump_stage: str = "Detection",
             extra_args: str = "",
             **kwargs):

        dump_stage = dump_stage.capitalize()
        extra_args += f" -dump {dump_stage}"
        coro = self._call(*args, extra_args=extra_args, **kwargs)
        next(coro)
        output_dump = os.path.join(
            self.output_dir,
            f"pre_{dump_stage}.{self.output_file_name_base}.dump")

        module_logger.debug((f"run_dspsr_with_dump: "
                             f"dumping after {dump_stage} operation"))

        after_cmd_str = f"mv pre_{dump_stage}.dump {output_dump}"

        ar, log = coro.send(after_cmd_str)
        return psr_formats.DADAFile(output_dump).load_data(), ar, log


class PsrdiffRunner(BaseRunner):

    psrdiff_default_out = "psrdiff.out"

    def call(self, *file_paths,
             output_file_name: str = None,
             output_dir: str = "./"):

        module_logger.debug(f"PsrdiffRunner.call: file_paths={file_paths}")

        if output_file_name is None:
            bases = [self._get_file_base(f) for f in file_paths]
            output_file_name_base = "-".join(bases)
            output_file_name = f"{output_file_name_base}.out"
        else:
            output_file_name_base = os.path.splitext(
                output_file_name)[0]

        self.output_file_name_base = output_file_name_base

        log_file_name = f"{output_file_name_base}.log"

        log_file_path = os.path.join(output_dir, log_file_name)
        output_file_path = os.path.join(output_dir, output_file_name)
        psrdiff_cmd_str = f"psrdiff {' '.join(file_paths)}"
        module_logger.debug(f"PsrdiffRunner.call: psrdiff command={psrdiff_cmd_str}")
        after_cmd_str = f"mv {self.psrdiff_default_out} {output_file_path}"
        module_logger.debug(f"PsrdiffRunner.call: mv command={after_cmd_str}")

        try:
            with open(log_file_path, "w") as log_file:
                psrdiff_cmd = subprocess.run(shlex.split(psrdiff_cmd_str),
                                             stdout=log_file,
                                             stderr=log_file)
            if psrdiff_cmd.returncode == 0:
                if after_cmd_str is not None:
                    subprocess.run(shlex.split(after_cmd_str))
        except subprocess.CalledProcessError as err:
            module_logger.error(
                f"Couldn't execute command {psrdiff_cmd_str}: {err}")

        return output_file_path, log_file_path


class PsrtxtRunner(BaseRunner):

    def call(self, file_path,
             output_file_name: str = None,
             output_dir: str = None):
        super(PsrtxtRunner, self).call(file_path,
                                       output_file_name=output_file_name,
                                       output_dir=output_dir)

        if output_file_name is None:
            output_file_name = f"{self.output_file_name_base}.txt"

        output_file_path = os.path.join(self.output_dir, output_file_name)
        log_file_name = f"{self.output_file_name_base}.log"
        log_file_path = os.path.join(self.output_dir, log_file_name)

        psrtxt_cmd_str = f"psrtxt {file_path}"

        try:
            with open(log_file_path, "w") as log_file, \
                    open(output_file_path, "w") as output_file:
                subprocess.run(shlex.split(psrtxt_cmd_str),
                               stdout=output_file,
                               stderr=log_file)
            # if psrtxt_cmd.returncode == 0:
            #     if after_cmd_str is not None:
            #         subprocess.run(shlex.split(after_cmd_str))
        except subprocess.CalledProcessError as err:
            module_logger.error(
                f"Couldn't execute command {psrtxt_cmd_str}: {err}")

        return output_file_path, log_file_path


def load_psrtxt_data(psrtxt_file_path: str):
    """
    Load in data from a `psrtxt` dump file
    """
    with open(psrtxt_file_path, "r") as f:
        txt_data = f.read()

    data = []
    for line in txt_data.split("\n"):
        if line == "":
            continue
        data.append([float(v) for v in line.split(" ")])

    data = np.array([np.array(a) for a in data]).transpose()

    return data


def find_in_log(log_file_path: str,
                *keywords: typing.Tuple[str],
                sep: str = "=",
                delimiter: str = " "):
    """
    Get a value from a log file.
    """
    with open(log_file_path, "r") as f:
        txt = f.read()

    def _get_val_after_keyword(txt: str, keyword: str):
        if keyword not in txt:
            raise RuntimeError(f"find_in_log: couldn't find {keyword}")
        key_idx = txt.find(keyword)
        sep_idx = txt.find(sep, key_idx)
        delim_idx = txt.find(delimiter, sep_idx)
        val = txt[sep_idx+1:delim_idx]
        return val

    vals = []
    for key in keywords:
        vals.append(_get_val_after_keyword(txt, key))

    if len(keywords) == 1:
        return vals[0]
    else:
        return vals


run_dspsr = DspsrRunner()
run_dspsr_with_dump = DspsrDumpRunner()
run_psrdiff = PsrdiffRunner()
run_psrtxt = PsrtxtRunner()


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
