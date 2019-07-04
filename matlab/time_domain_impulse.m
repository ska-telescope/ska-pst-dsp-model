function signal = time_domain_impulse(n_bins, offsets, widths, dtype_)
  % generate a time domain impulse. The location and width of each impulse
  % is specified in ``offsets`` and ``widths``
  %
  % Args:
  %   n_bins (numeric): The length of the output array
  %   offsets ([numeric]): The location of each impulse in the output array
  %   widths ([numeric]): The width of the impulse whose location is specified in offsets
  %   bin_offset (numeric): Fractional offset from bin center
  %   dtype_ (string): Optional. data type of returned array.
  % Returns:
  %   [numeric]: time domain impulses
  dtype = 'single';
  if exist('dtype_', 'var')
    dtype = dtype_;
  end

  signal = complex(zeros(1, n_bins, dtype));
  for i=1:length(offsets)
    o = offsets(i);
    w = widths(i);
    signal(o: o+w-1) = complex(1.0, 1.0);
  end
  signal = complex(signal);
end
