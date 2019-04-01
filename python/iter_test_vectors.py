import os
import typing


def iter_test_vectors(base_dir: str,
                      domain_sub_dirs: typing.List[str] = None) -> None:
    """
    Iterate through all the sub directories in the base directory, yielding
    each subdirectory.

    Args:
        base_dir (str): The base directory where test vectors are found.
        domain_sub_dirs (list, optional): A specific set of sub directories
            under `base_dir` under which to look for data.
    Returns:
        generator: yields each subdirectory.
    """
    if domain_sub_dirs is None:
        domain_sub_dirs = os.listdir(base_dir)
    for domain in domain_sub_dirs:
        sub_dir = os.path.join(base_dir, domain)
        for sub_sub_dir in os.listdir(sub_dir):
            yield domain, os.path.join(sub_dir, sub_sub_dir)
