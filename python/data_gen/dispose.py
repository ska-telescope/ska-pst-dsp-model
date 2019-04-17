import contextlib
import os

__all__ = [
    "dispose"
]


@contextlib.contextmanager
def dispose(*callbacks: tuple):
    """

    Usage:

    Use a single callback:

    .. code-block::python

        >>> f = lambda: DADAFile("path/to/some/file.dump")
        >>> with dipose(f) as dump_file:
        >>>    print(dump_file.file_path)
        >>> os.path.exists(dump_file.file_path)
        >>> False

    Use multiple callbacks:

    .. code-block::python

        def f(a):
            return a

        def g(a, b):
            return a

        file_path = "path/to/some/file.dump"
        with dispose(f(file_path), g(file_path, None)) as dump_files:
            pass

    Use multiple callbacks, trapping some args:

    .. code-block::python

        file_path = "path/to/some/file.dump"
        with dipose(functools.partial(f, file_path),
                    g(file_path, None)) as dump_files:
            pass

    Args:
        callbacks (tuple): Tuple of callables or files. Files can be any
            object with a "file_path" attribute, or a string representing
            a path to a file
    """
    files = []
    for res in callbacks:
        if hasattr(res, "__call__"):
            res = res()
        files.append(res)

    if len(files) == 1:
        yield files[0]
    else:
        yield files

    for f in files:
        if hasattr(f, "file_path"):
            f = f.file_path
        if os.path.exists(f):
            os.remove(f)
