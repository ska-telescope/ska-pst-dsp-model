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

  chopped = chop(test_data_pipeline_res, chop_args{:});

  data = chopped; % test_data_pipeline_res{2};
  
  input = squeeze( data{1} );
  inverted = squeeze( data{2} );
  
  channelized = test_data_pipeline_res{2}{2};
  chsize = size(channelized);
  nchan = chsize(2);
  nsamp = chsize(3);
  
  chantot = zeros([nsamp 1]);
  
  for ichan = 1:nchan
    chandat = squeeze( channelized(1,ichan,:) );
    chantot = chantot + abs(chandat);  
  end
  
  powan = PowerAnalysis;

  do_fft = 0;
  if (do_fft == 1)
    input = fft(input);
    chantot = fft(chantot);
    inverted = fft(inverted);
  end
  
  power = 1;
  if (power == 1)
    input = powan.dB(input);
    chantot = powan.dB(chantot);
    inverted = powan.dB(inverted);
  else
    nplot = 100;
    input = real(input(1:nplot));
    chantot = real(chantot(1:nplot));
    inverted = real(inverted(1:nplot));
  end

  plot2d = 0;
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
    plot(input);
    grid(ax, 'on');
    title('Input data')

  ax = subplot(312);
  % ax = subplot(1,1,1);
    plot(chantot);
    grid(ax, 'on');
    title('Channelized data');
  
  ax = subplot(313);
  % ax = subplot(1,1,1);
    plot(inverted);
    grid(ax, 'on');
    title('Inverted data');
    
  sgtitle(plot_sub_title);

  [m_inv, argmax_inv] = max(inverted);
  [m_input, argmax_input] = max(input);

  fprintf('diagnostic_plot: max/argmax of input data: %f/%d\n', m_input, argmax_input);
  fprintf('diagnostic_plot: max/argmax of inverted data: %f/%d (offset: %d)\n', m_inv, argmax_inv, argmax_inv-argmax_input);

  fprintf('Press <ENTER> to continue');
  pause;

end
