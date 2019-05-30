import os
import logging

import partialize

__all__ = [
    "pipeline"
]

module_logger = logging.getLogger(__name__)


def pipeline(
    test_vector_callback: callable,
    channelize_callback: callable,
    synthesize_callback: callable,
    output_dir: str = None,
) -> callable:
    """

    Return a callable that generates a test signal, channelizes it,
    and then synthesize the result, saving the output of each step.

    The resulting callable's arguments get passed to the
    `test_vector_callback`, the result of which gets pushed through the
    pipeline.

    Each callback function should return a `formats.DataFile` like object

    Usage:

    Use default parameters for each of the callbacks:

    .. code-block::python

        pipeline_fn = pipeline(
            generate_test_vector("python"),
            channelize("matlab"),
            synthesize("python")
        )

        dada_files = pipeline_fn("time", 1000, 0.1, 1)

        (input_dada_file,
         channelized_dada_file,
         synthesized_dada_file) = dada_files

    Use non default parameters with the help of `functools.partial`:

    .. code-block::python

        import functools

        pipeline_fn = pipeline(
            generate_test_vector("python"),
            functools.partial(channelize("matlab"), channels=16),
            functolls.partial(synthesize("python"), input_fft_length=16384)
        )


    """
    def _pipeline(*args, **kwargs):
        module_logger.debug(f"_pipeline: args={args}, kwargs={kwargs}")
        test_vector_dada_file = test_vector_callback(
            *args, **kwargs, output_dir=output_dir)
        channelized_file_name = "channelized." + \
            os.path.basename(test_vector_dada_file.file_path)
        synthesized_file_name = "synthesized." + \
            os.path.basename(test_vector_dada_file.file_path)

        channelized_dada_file = channelize_callback(
            test_vector_dada_file.file_path,
            output_file_name=channelized_file_name,
            output_dir=output_dir)
        synthesized_dada_file = synthesize_callback(
            channelized_dada_file.file_path,
            output_file_name=synthesized_file_name,
            output_dir=output_dir)

        return (
            test_vector_dada_file,
            channelized_dada_file,
            synthesized_dada_file
        )

    return _pipeline
