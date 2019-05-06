function chopped = chop(test_data_pipeline_res, additional_offset_)
  % given the result from test_data_pipeline, chop up the input and inverted
  % data such that the two align in time
  additional_offset = 0;
  if exist('additional_offset_', 'var')
    additional_offset = additional_offset_;
  end

  data = test_data_pipeline_res{2};
  meta = test_data_pipeline_res{3};

  size_inv = size(data{3});
  ndat_inv = size_inv(3);

  sim_squeezed = squeeze(data{1}(1, 1, :));
  inv_squeezed = squeeze(data{3}(1, 1, :));


  output_shift = meta.fir_offset + additional_offset;
  % meta.fir_offset
  % additional_offset
  % size(sim_squeezed)
  % output_shift
  sim_squeezed = sim_squeezed(output_shift+1:end);

  min_ndat = ndat_inv;
  % min_ndat = min([length(sim_squeezed), ndat_inv]);

  input = sim_squeezed(1:min_ndat);
  inv = inv_squeezed(1:min_ndat);

  chopped = {input, inv};
end
