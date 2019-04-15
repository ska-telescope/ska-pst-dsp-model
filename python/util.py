import os

__all__ = [
    "updir",
    "curdir"
]


def updir(base_dir, levels):
    """
    Go up `levels` number of directories
    """
    if levels == 0:
        return base_dir
    else:
        return updir(os.path.dirname(base_dir), levels - 1)


def curdir(file_path):
    """
    Get the current directory where a given file resides
    """
    return os.path.dirname(os.path.abspath(file_path))
