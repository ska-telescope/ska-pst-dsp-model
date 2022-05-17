function padded = pad_filter(filter_coeff, n_chan)
  % ensure that the number of elements in filter_coeff is equal to an integer
  % number times ``n_chan``.
  %
  % Args:
  %   filter_coeff ([numeric]): filter coefficients
  %   n_chan (numeric): number of target channels
  % Returns:
  %   [numeric]: filter coefficients with zero padding.
  phases=ceil(length(filter_coeff)/n_chan);
  padded=zeros(phases*n_chan, 1, class(filter_coeff));
  padded(1:length(filter_coeff))=filter_coeff;
end
