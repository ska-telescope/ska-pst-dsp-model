import os
import json
import argparse

import matplotlib.pyplot as plt

import data_gen.util
from data_gen.config import matplotlib_config

matplotlib_config()

cur_dir = data_gen.util.curdir(__file__)
products_dir = os.path.join(data_gen.util.updir(cur_dir, 1), "products")


def plot_purity_results(results_path):
    key_map = {
        "test_complex_sinusoid": "freq",
        "test_time_domain_impulse": "offset"
    }

    key_map_names = {
        "test_complex_sinusoid": "Complex Sinusoid",
        "test_time_domain_impulse": "Time Domain Impulse"
    }

    purity_measures = [
        "max_spurious_power",
        "total_spurious_power",
        "mean_spurious_power"
    ]

    diff_measures = [
        "mean_diff",
        "total_diff"
    ]

    in_per_row = 4

    with open(results_path, "r") as f:
        results = json.load(f)

    def plot_results(x, x_label, dat, dat_labels):
        fig, axes = plt.subplots(len(dat), 1,
                                 figsize=(in_per_row*len(dat), 10))

        for i, label, d in zip(range(len(dat)), dat_labels, dat):
            axes[i].scatter(x, d)
            label = " ".join([s.capitalize() for s in label.split("_")])
            axes[i].set_title(label)
            axes[i].set_ylabel("Power (dB)")
            axes[i].set_xlabel(x_label)
            axes[i].grid(True)

        fig.tight_layout(rect=[0, 0.03, 1, 0.95])

        return fig, axes

    for key in key_map:
        if key not in results:
            continue
        domain_key = key_map[key]
        domain = []
        purity = []
        diff = []
        for val in results[key]:
            domain.append(val["arg"])
            purity.append([val[k] for k in purity_measures])
            diff.append(val[k] for k in diff_measures)

        purity = list(zip(*purity))
        diff = list(zip(*diff))

        fig, axes = plot_results(domain, domain_key, purity, purity_measures)

        fig.suptitle(f"{key_map_names[key]} Purity")
        fig.savefig(
            os.path.join(products_dir, f"purity.{key}.png"))

        fig, axes = plot_results(domain, domain_key, diff, diff_measures)
        fig.suptitle(f"{key_map_names[key]} Difference")
        fig.savefig(
            os.path.join(products_dir, f"diff.{key}.png"))


def create_parser():

    parser = argparse.ArgumentParser(
        description="plot purity results")

    parser.add_argument("-i", "--input-file",
                        dest="input_file_path",
                        required=True)

    return parser


if __name__ == "__main__":
    parsed = create_parser().parse_args()
    results_path = parsed.input_file_path
    # results_path = os.path.join(products_dir, "report.purity.json")
    plot_purity_results(results_path)
