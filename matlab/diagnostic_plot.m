function res = diagnostic_plot(test_data_pipeline_res, chop_args, plot_sub_title_)
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

  data = test_data_pipeline_res{2};
  
  input = squeeze( data{1} );
  inverted = squeeze( data{3} );
  
  chsize = size(data{2});
  nchan = chsize(2);
  nsamp = chsize(3);
  
  channelized = zeros([nsamp 1]);
  
  for ichan = 1:nchan
    chandat = squeeze( data{2}(1,ichan,:) );
    channelized = channelized + abs(chandat);  
  end
  
  [m_input, argmax_input] = max(input);
  [m_chan, argmax_chan] = max(channelized);
  [m_invert, argmax_invert] = max(inverted);
  
  plot2d = 0;
  
  powan = PowerAnalysis;

  if (plot2d == 1)
    z=squeeze( data{2} );  
    figure;
    
    ax = subplot(211);
    image(powan.dB(real(z)),'CDataMapping','scaled')
    colorbar
    title('real[channelized]');

    ax = subplot(212);
    image(powan.dB(imag(z)),'CDataMapping','scaled')
    colorbar
    title('imag[channelized]');

  end
  
  figure;

  ax = subplot(311);
    plot(powan.dB(input));
    grid(ax, 'on');
    title('Input data')

  ax = subplot(312);
  % ax = subplot(1,1,1);
    plot(powan.dB(channelized));
    grid(ax, 'on');
    title('Channelized data');
    
    ax = subplot(313);
  % ax = subplot(1,1,1);
    plot(powan.dB(inverted));
    grid(ax, 'on');
    title('Inverted data');
    
    sgtitle(plot_sub_title);

  fprintf('diagnostic_plot: imax of input data: %d\n', argmax_input);
  fprintf('diagnostic_plot: imax of channelized data: %d\n', argmax_chan);
  fprintf('diagnostic_plot: nchan of channelized data: %d\n', nchan);
  fprintf('diagnostic_plot: imax of inverted data: %d\n\n', argmax_invert);
  
  scaled_imax = argmax_chan * nchan * 7 / 8;
  diff_imax = argmax_input - argmax_invert;
  
  fprintf('diagnostic_plot: scaled imax of channelized data: %d\n', scaled_imax);
  fprintf('diagnostic_plot: diff imax (input - inverted): %d\n', diff_imax);
  fprintf('diagnostic_plot: diff imax (input - scaled): %d\n', argmax_input - scaled_imax);
  
  res = { argmax_input, argmax_chan, scaled_imax, argmax_input - scaled_imax };

  chopped = chop(test_data_pipeline_res, chop_args{:});
  
  input_data = squeeze(chopped{1});
  inverted_data = squeeze(chopped{2});

  [m_inv, argmax_inv] = max(inverted_data);
  [m_input, argmax_input] = max(input_data);

  fprintf('diagnostic_plot: max/argmax of input data: %f/%d\n', m_input, argmax_input);
  fprintf('diagnostic_plot: max/argmax of inverted data: %f/%d (offset: %d)\n', m_inv, argmax_inv, argmax_inv-argmax_input);

  pause;

end
