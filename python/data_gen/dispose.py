import contextlib
import os
import logging

__all__ = [
    "dispose"
]

module_logger = logging.getLogger(__name__)


@contextlib.contextmanager
def dispose(*callbacks: tuple, dispose=True):
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

    def remove_file(f):
        module_logger.debug(f"dispose.remove_file: {f}")
        if hasattr(f, "file_path"):
            f = f.file_path
        if hasattr(f, "format"):
            if os.path.exists(f):
                os.remove(f)
    if dispose:
        for f in files:
            if isinstance(f, (tuple, list)):
                module_logger.debug("dispose: tuple or list!")
                list(map(remove_file, f))
            else:
                remove_file(f)
    else:
        module_logger.debug("dispose: not removing files")
