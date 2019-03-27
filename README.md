## PST_Matlab_dspsr_PFB_inversion_comparison

Compare the results of dspsr's PFB inversion implementation to the PST Signal model,
implemented in Matlab. The goal of this comparison is to assess whether the two
implementations produce the same results, within numerical precision.

Attempting to abide by the Matlab coding conventions enumerated [here](https://au.mathworks.com/matlabcentral/fileexchange/46056-matlab-style-guidelines-2-0).

Function documentation using [jsdoc](http://usejsdoc.org/) style documentation.

### Usage

- `single_double_fft.m`: Determines if matlab's `fft` returns an array whose data
type is the same a that of the input. This also produces a plot displaying the
numerical difference between the input arrays and the results of applying
the `fft` function to each of the input arrays. The motivation for this script
comes from the fact that Numpy's FFT implementation does not return the same
datatype for single precision inputs:

```python
>>> import numpy as np
>>> a = np.random.rand(1024, dtype=np.float32)
>>> f = np.fft.fft(a)
>>> print(f.dtype)
complex128
```

If Numpy's FFT were datatype consistent, the above example should output `complex64`.
Moreover, we can see that Numpy actually implicitly upcasts 32 bit data when
calling `numpy.fft.fft`:

```python
>>> import numpy as np
>>> a32 = np.random.rand(1024, dtype=np.float32)
>>> a64 = a32.astype(np.float64)
>>> f32 = np.fft.fft(a32) # not actually 32-bit data!
>>> f64 = np.fft.fft(a64)
>>> np.sum(np.abs(f32 - f64))
0
```

If Numpy were actually computing a 32-bit FFT, we would see some numerical
difference between `f32` and `f64` even though the inputs are attempting to
represent the same array of numbers. This is actually a known bug in Numpy:
https://github.com/numpy/numpy/issues/6012

- `write_header.m`: Writes a DADA header to an open file
- `read_header.m`: Reads a DADA header from an open file
- `polyphase_analysis.m`: Implements polyphase filterbank algorithm.
This is originally John Bunton's code with some (small) modifications to incorporate
`os_factor` structs.
- `polyphase_analysis_alt.m`: Implements polyphase filterbank algorithm using
an alternative algorithm. This is based on code written by Ian Morrison and
Thushara Kanchana Gunaratne.
- `polyphase_synthesis.m`: Implements polyphase filterbank inversion algorithm.
- `polyphase_synthesis_alt.m`: Implements polyphase filterbank inversion algorithm.
The purpose of this function is to exactly implement the PFB inversion algorithm
used in Ian Morrison's PST spectral and temporal purity [tests](https://github.com/SKA-PST/PST_Matlab_channelizer_inverter_purity_measurement_CDR).
- `time_domain_impulse.m`: Generates a time domain impulse. Can generate
multiple impulses of varying widths.
- `complex_sinusoid.m`: Generate a complex sinusoid at a given frequency. Can
also generate a linear combination of sinusoids at any number of specified
frequencies.
- `pipeline.m`: Run the test vector generation, analysis and synthesis pipeline.

### Testing

Run `test.m` to run a basic suite of unit-like tests.
