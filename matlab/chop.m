function chopped = chop(test_data_pipeline_res, additional_offset_)
  % Utility function for aligning coarse channel input data and coarse channel
  % inverted data.
  %
  % Args:
  %   test_data_pipeline_res (cell): Cell array that is result of call to
  %     ``test_data_pipeline``. Has ``{file_info, data, meta}`` structure.
  %     See :func:`test_data_pipeline` for more information on this structure.
  %   additional_offset_ (int): Any additional shift to introduce to output data.
  % Returns:
  %   cell: cell array containing "chopped" input and inverted data

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
  % inv_squeezed = inv_squeezed(output_shift+1:end);
  sim_squeezed = sim_squeezed(output_shift+1:end);

  % min_ndat = ndat_inv;
  min_ndat = min([length(sim_squeezed), length(inv_squeezed)]);

  input = sim_squeezed(1:min_ndat);
  inv = inv_squeezed(1:min_ndat);

  chopped = {input, inv};
end
