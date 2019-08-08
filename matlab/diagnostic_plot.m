function diagnostic_plot(test_data_pipeline_res, chop_args, plot_sub_title_)
  % Generate a plot of the results of PFB inversion, using the result from a
  % call to :func:`test_data_pipeline`.
  %
  % Args:
  %    test_data_pipeline (struct): Return struct from call to :func:`test_data_pipeline`.
  %    chop_args (cell): cell array containing any extra arguments for call to
  %      :func:`chop`.
  %    plot_sub_title_ (string): Optional. Title for plot.

  plot_sub_title = '';
  if exist('plot_sub_title_', 'var')
    plot_sub_title=plot_sub_title_;
  end

  chopped = chop(test_data_pipeline_res, chop_args{:});

  input_data = squeeze(chopped{1});
  inverted_data = squeeze(chopped{2});

  figure;
  powan = PowerAnalysis;

  ax = subplot(211);
    plot(powan.dB(input_data));
    grid(ax, 'on');
    title('Input data')

  ax = subplot(212);
  % ax = subplot(1,1,1);
    plot(powan.dB(inverted_data));
    grid(ax, 'on');
    title('Inverted data');

  [m_inv, argmax_inv] = max(inverted_data);
  [m_input, argmax_input] = max(input_data);

  fprintf('diagnostic_plot: max/argmax of inverted data: %f/%d\n', m_inv, argmax_inv);
  fprintf('diagnostic_plot: max/argmax of input data: %f/%d\n', m_input, argmax_input);

  suptitle(plot_sub_title);

  pause;

end
