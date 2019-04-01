import argparse
import os
import json
import logging

from run_dspsr_with_dump import run_dspsr_with_dump, load_pulsar_params
from iter_test_vectors import iter_test_vectors

meta_data_file_name = "meta.json"

module_logger = logging.getLogger(__name__)


def _process_single_dir(sub_dir, pulsar_params=None, fft_size=16384) -> None:
    if not os.path.exists(sub_dir):
        raise RuntimeError(f"Can't find directory {sub_dir}")

    module_logger.debug((f"_process_single_dir: "
                         f"processing directory {sub_dir}"))

    if pulsar_params is None:
        pulsar_params = load_pulsar_params()
    meta_data_file_path = os.path.join(sub_dir, meta_data_file_name)
    with open(meta_data_file_path, 'r') as f:
        meta_data = json.load(f)

    channelized_data_file_name = meta_data["channelized_file"]
    channelized_data_file_path = os.path.join(
        sub_dir, channelized_data_file_name)
    ar, dump = run_dspsr_with_dump(
        channelized_data_file_path,
        pulsar_params["dm"],
        pulsar_params["period"],
        output_dir=sub_dir,
        extra_args=f"-IF 1:{fft_size}"
    )
    meta_data["dspsr_ar_file"] = ar
    meta_data["dspsr_pre_Detection_dump"] = dump

    with open(meta_data_file_path, 'w') as f:
        json.dump(meta_data, f)

    return meta_data


def process_test_vectors(*args, **kwargs):
    report = {"time": [], "freq": []}
    for domain_dir, sub_dir in iter_test_vectors(*args):
        dspsr_dump = _process_single_dir(sub_dir, **kwargs)
        report[domain_dir].append(dspsr_dump)
    return report


def create_parser():

    parser = argparse.ArgumentParser(
        description="compare the contents of two dump files")

    parser.add_argument("-bd", "--base-dir",
                        dest="base_dir",
                        type=str,
                        required=True)

    parser.add_argument("-fft", "--fft_size",
                        dest="fft_size", type=int,
                        required=False, default=16384)

    parser.add_argument("-v", "--verbose",
                        dest="verbose", action="store_true")

    return parser


def main():
    parsed = create_parser().parse_args()
    level = logging.INFO
    if parsed.verbose:
        level = logging.DEBUG
    logging.basicConfig(level=level)
    logging.getLogger("matplotlib").setLevel(logging.ERROR)
    pulsar_params = load_pulsar_params()
    report = process_test_vectors(
        parsed.base_dir,
        fft_size=parsed.fft_size,
        pulsar_params=pulsar_params
    )
    print(report)


if __name__ == "__main__":
    main()
