import argparse
import os
import json
import logging

import matplotlib.pyplot as plt
import numpy as np
import comparator

from run_dspsr_with_dump import run_dspsr_with_dump, load_pulsar_params
from iter_test_vectors import iter_test_vectors
from compare_dump_files import load_n_chop

cur_dir = os.path.dirname(os.path.abspath(__file__))
product_dir = os.path.join(os.path.dirname(cur_dir), "products")

meta_data_file_name = "meta.json"

module_logger = logging.getLogger(__name__)

input_params_map = {
    "f": "frequency",
    "o": "offset"
}

key_map = {
    "time": "impulse_position",
    "freq": "freq_position"
}


def get_input_params_from_subdir(sub_dir: str) -> dict:
    """
    Given the name of some sub directory, get the parameters used to
    create the input signal

    Args:
        sub_dir (str): The subdirectory where input data reside.
    Returns:
        dict: keys are parameter names, values are the corresponding values
    """
    sub_dir = os.path.basename(sub_dir)
    sub_dir_split = [v.split("-") for v in sub_dir.split("_")]
    result = {v[0]: v[1] for v in sub_dir_split}
    return result


def load_data_single_dir(sub_dir: str,
                         meta_data: dict):
    """
    Load the data from a given dump file
    """
    file_names = [meta_data["input_file"],
                  meta_data["inverted_file"],
                  meta_data["dspsr_pre_dump"]]

    file_paths = [os.path.join(sub_dir, f) for f in file_names]

    loaded, dada_files = load_n_chop(*file_paths, pol=0)
    loaded = [l.flatten() for l in loaded]
    return loaded, dada_files


def process_single_dir(sub_dir: str,
                       pulsar_params: dict = None,
                       fft_size: int = 16384,
                       dump_stage: str = "Convolution") -> None:
    if not os.path.exists(sub_dir):
        raise RuntimeError(f"Can't find directory {sub_dir}")

    input_params = get_input_params_from_subdir(sub_dir)
    for key in input_params_map:
        if key in input_params:
            module_logger.info(
                (f"process_single_dir: processing input "
                 f"{input_params_map[key]}={input_params[key]}"))

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
        dump_stage=dump_stage,
        extra_args=f"-IF 1:{fft_size} -V"
    )
    meta_data["dspsr_ar_file"] = os.path.basename(ar)
    meta_data["dspsr_pre_dump"] = os.path.basename(dump)

    with open(meta_data_file_path, 'w') as f:
        json.dump(meta_data, f)

    return meta_data


def process_test_vectors(*args: tuple,
                         fft_size: int = 16384,
                         pulsar_params: dict = None,
                         dump_stage: str = "Convolution",
                         plot: bool = True):
    figsize = (16, 9)
    comp = comparator.MultiDomainComparator(domains={
        "time": comparator.SingleDomainComparator("time"),
        # "time": comparator.TimeDomainComparator(),
        "freq": comparator.FrequencyDomainComparator()
    })
    comp.freq.domain = [0, fft_size]

    comp.operators["this"] = lambda a: a
    comp.operators["diff"] = lambda a, b: np.abs(a - b)

    comp.products["mean"] = np.mean
    comp.products["argmax"] = np.argmax
    comp.products["max"] = np.amax
    labels = ["input", "inverted", "dspsr_inverted"]
    report = {"time": [], "freq": []}
    for domain_dir, sub_dir in iter_test_vectors(*args):
        key = key_map[domain_dir]
        meta_data = process_single_dir(
            sub_dir, fft_size=fft_size, pulsar_params=pulsar_params,
            dump_stage=dump_stage)
        loaded, dada_files = load_data_single_dir(sub_dir, meta_data)
        loaded[-1] /= 8*fft_size
        res = {
            "time": comp.time.cartesian(*loaded, labels=labels),
            "freq": comp.freq.polar(*loaded, labels=labels)
        }
        report[domain_dir].append({})
        for res_key in res:
            res_op, res_prod = res[res_key]
            if plot:
                figs, axes = comparator.util.plot_operator_result(
                    res_op, figsize=figsize)
                for i, fig in enumerate(figs):
                    fig.savefig(os.path.join(sub_dir, f"{res_key}.{i}.png"))
            module_logger.debug((f"process_test_vectors: {sub_dir} max "
                                 f"products: {res_prod['this']['max']}"))
            module_logger.debug((f"process_test_vectors: {sub_dir} argmax "
                                 f"products: {res_prod['this']['argmax']}"))
            module_logger.debug((f"process_test_vectors: {sub_dir} difference "
                                 f"products: {res_prod['diff']['mean']}"))
            report[domain_dir][-1][res_key] = {
                key: meta_data[key],
                "diff": list(res_prod["diff"]["mean"]),
                "max": list(res_prod["this"]["max"]),
                "mean": list(res_prod["this"]["mean"])
            }
        plt.close('all')

    return report


def create_report_plot(report):

    for domain_name in report:
        domain_report = report[domain_name]
        dat = [
            (float(d["time"][key_map[domain_name]]),
             d["time"]["diff"][1][2],
             d["freq"]["diff"][1][2]) for d in domain_report
        ]
        dat.sort(key=lambda x: x[0])
        dat = list(zip(*dat))

        fig, axes = plt.subplots(2, 2)
        fig.suptitle(f"Comparison of {domain_name} domain test vectors")
        ax = fig.add_subplot(111, frameon=False)
        plt.tick_params(
            labelcolor="none",
            top=False,
            bottom=False,
            left=False,
            right=False
        )
        ax.set_xlabel("Impulse position as percentage of ndat")
        ax.set_ylabel("Numerical difference")
        axes[0, 0].plot(dat[0], [d[0] for d in dat[1]])
        axes[0, 0].set_title("Time domain comparison: real component")
        axes[0, 0].grid(True)

        axes[0, 1].plot(dat[0], [d[1] for d in dat[1]])
        axes[0, 1].set_title("Time domain comparison: imaginary component")
        axes[0, 1].grid(True)

        axes[1, 0].plot(dat[0], [d[0] for d in dat[2]])
        axes[1, 0].set_title("Frequency domain comparison: magnitude")
        axes[1, 0].grid(True)

        axes[1, 1].plot(dat[0], [d[1] for d in dat[2]])
        axes[1, 1].set_title("Frequency domain comparison: phase")
        axes[1, 1].grid(True)
        fig.savefig(
            os.path.join(product_dir, f"{domain_name}.comparison.png"))

    plt.show()


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

    parser.add_argument("-pl", "--plot",
                        dest="plot", action="store_true")

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
    # for domain_dir, sub_dir in iter_test_vectors(parsed.base_dir):
    #     get_input_params_from_subdir(sub_dir)
    report = process_test_vectors(
        parsed.base_dir,
        fft_size=parsed.fft_size,
        pulsar_params=pulsar_params,
        dump_stage="Convolution",
        plot=parsed.plot
    )
    with open(os.path.join(product_dir, "report.json"), "w") as f:
        json.dump(report, f, cls=comparator.util.NumpyEncoder)
        
    create_report_plot(report)


if __name__ == "__main__":
    main()
