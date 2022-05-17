.. PST_PFB_inversion_verification documentation master file, created by
   sphinx-quickstart on Wed Jul  3 14:57:26 2019.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Documentation for PST PFB verification
======================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   matlab


Verification Configuration
--------------------------

`config/test.config.json` define some configurations for testing and verification.
By default, it contains three configurations, one for SKA low, one for mid, and
one 'test' configuration. Each configuration contains parameters that might be
common to several tests, while specific to others.

- fir_filter_coeff_file_path ``str``: Relative (to config directory) path to FIR
  filter coefficients, in .mat format.
- fir_filter_taps ``int``: The number of FIR filter taps in the
  ``fir_filter_coeff_file_path`` file.
- header_file_path ``str``: Relative (to config directory) path to default header file.
- os_factor ``str``: Oversampling factor, expressed as a slash delimited string, eg "8/7".
- channels ``int``: The number of channels to generate in PFB analysis.
- input_fft_length ``int``: The size of the forward FFT used in PFB inversion.
- input_overlap ``int``: The input overlap size used in PFB inversion.
- blocks ``int``: Number of processing blocks to generate.
- backend: Each of the child fields can either be "python" or "matlab", indicating
  which implementation to use. Python is significantly faster, as there is
  no call overhead, but Matlab is the prototype "gold standard". Moreover, the
  Python channelizer has been somewhat optimized with `Numba <https://numba.pydata.org/>`_.

  - test_vectors ``str``: backend for generating test vectors
  - channelize ``str``: PFB channelizer backend
  - synthesize ``str``: PFB inversion backend
- n_pol ``int``: Number of polarizations to generate
- dm ``float``: Dispersion measure. Set to zero to disable dedispersion. Only
  used in tests that with ``dspsr``.
- period ``float``: pulsar period. Only used in tests with ``dspsr``.
- dump_stage ``str``: Tells ``dspsr`` after which stage to dump the results of PFB inversion.
- deripple ``bool``: Boolean value indicating whether or not to perform derippling.
- fft_window ``str``: the FFT window to use in PFB inversion. Can be "no_window"
  or "tukey"


Indices and tables
==================

* :ref:`genindex`
.. * :ref:`modindex`
.. * :ref:`search`
