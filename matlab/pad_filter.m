function padded = pad_filter(filter_coeff, n_chan)
  % ensure that the number of elements in filter_coeff is equal to an integer
  % number times `n_chan`.
  % @method pad_filter
  % @param {double/single []} filter_coeff - filter coefficients
  % @param {double/single} n_chan - number of target channels
  % @return {double/single []} - filter coefficients with zero padding.

  phases=ceil(length(filter_coeff)/n_chan);
  padded=zeros(phases*n_chan, 1, class(filter_coeff));
  padded(1:length(filter_coeff))=filter_coeff;
end
