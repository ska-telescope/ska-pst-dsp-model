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

- `write_header.m`: Writes a DADA header to an open file
- `read_header.m`: Reads a DADA header from an open file
- `polyphase_analysis.m`: Implements polyphase filterbank algorithm.
This is originally John Bunton's code.
- `polyphase_synthesis.m`: Implements polyphase filterbank inversion algorithm.
This is cobbled together from many different people's code (all are acknowledged).
- `time_domain_impulse.m`: Generates a time domain impulse
- `complex_sinusoid.m`: Generate a complex sinusoid at a given frequency.
- `pipeline.m`: Run the test vector generation, analysis and synthesis pipeline.

### Testing

Run `test.m` to run a basic suite of unit-like tests.
