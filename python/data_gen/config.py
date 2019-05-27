import json
import os

from . import util

__all__ = [
    "load_config",
    "save_config",
    "config",
    "config_dir",
    "build_dir",
    "matplotlib_config"
]

_required_fields = {
    "fir_filter_coeff_file_path",
    "header_file_path",
    "os_factor",
    "channels",
    "input_fft_length",
    "blocks",
    "backend",
    "dm",
    "period",
    "dump_stage"
}

cur_dir = util.curdir(__file__)
config_dir = os.path.join(util.updir(cur_dir, 2), "config")
build_dir = os.path.join(util.updir(cur_dir, 2), "build")
test_config_file_name = "test.config.json"
test_config_file_path = os.path.join(config_dir, test_config_file_name)


def load_config():
    if not os.path.exists(test_config_file_path):
        raise RuntimeError((f"Cannot find {test_config_file_name} "
                            f"in {config_dir}"))
    with open(test_config_file_path, "r") as f:
        config = json.load(f)
    return config


def _check_config(config):
    config_fields_set = set(config.keys())
    return config_fields_set.issubset(_required_fields)


def save_config(new_config):
    if _check_config(new_config):
        with open(test_config_file_path, "w") as f:
            f.dump(new_config, f)
    else:
        raise RuntimeError(
            ("New configuration does not have all "
             "required configuration fields"))


def matplotlib_config():
    import matplotlib as mpl
    params = {
        'figure.titlesize': 'xx-large',
        'axes.labelsize': 'xx-large',
        'axes.titlesize': 'xx-large',
        'xtick.labelsize': 'medium',
        'ytick.labelsize': 'large'
    }
    mpl.rcParams.update(params)


config = load_config()
