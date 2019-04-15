import json
import os

__all__ = [
    "load_config",
    "save_config"
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

cur_dir = os.path.dirname(os.path.abspath(__file__))
config_dir = os.path.join(os.path.dirname(cur_dir), "config")
test_config_file_path = os.path.join(config_dir, "test.config.json")


def load_config():
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
