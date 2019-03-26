## PST_Matlab_dspsr_PFB_inversion_comparison

Compare the results of dspsr's PFB inversion implementation to the PST Signal model,
implemented in Matlab. The goal of this comparison is to assess whether the two
implementations produce the same results, within numerical precision.

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
