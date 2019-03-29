function signal = time_domain_impulse (n_bins, offsets, widths, dtype_)
  % generate a time domain impulse. The location and width of each impulse
  % is specified in `offsets` and `widths`
  % @method time_domain_impulse
  % @param {double} n_bins - The length of the output array
  % @param {double []} offsets - The location of each impulse in the output
  %   array
  % @param {double []} widths - The width of the impulse whose location is
  %    specified in offsets
  % @param {double} bin_offset - Fractional offset from bin center
  % @return {double []} - time domain impulses
  dtype = 'single';
  if exist('dtype_', 'var')
    dtype = dtype_;
  end

  signal = complex(zeros(1, n_bins, dtype));
  for i=1:length(offsets)
    o = offsets(i);
    w = widths(i);
    signal(o: o+w-1) = 1.0;
  end
end
