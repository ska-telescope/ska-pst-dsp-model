function current_performance(npoints_, tele_, domain_, diagnostic_)
  % Determine the current performance of the Matlab PST FFT PFB inversion
  % algorithm. Here performance is referring to the ability of the PFB inversion
  % algorithm to reconstruct input data.
  %
  % At the moment, this function must be run from within the containing directory.
  %
  % This function will generate plots in png form.
  %
  % Example:
  %
  %   >> current_performance(10, 'mid', 'time') % get peformance using mid parameters.
  %
  % Args:
  %   npoints_ (numeric): Optional. Number of tones/impulses to use to generate
  %     performance plots.
  %   tele_ (string): Optional. The name of the parameter set to use from the
  %     ``test.config.json`` file. Can be one of ``'test'``, ``'mid'``, or ``'low'``.
  %     Defaults to ``'test'``.
  %   domain_ (string): Optional. Do performance analysis for either time domain
  %     impulse (``'time'``), or tones (``'freq'``). Defaults to ``'time'``.
  %    diagnostic_ (bool): Optional. Make diagnostic plots for each domain
  %      parameter

  tele = 'test';
  if exist('tele_', 'var')
    tele = tele_;
  end

  domain = 'time';
  if exist('domain_', 'var')
    domain = domain_;
  end

  npoints = 300;
  if exist('npoints_', 'var')
    npoints = npoints_;
  end

  diagnostic = false;
  if exist('diagnostic_', 'var')
    diagnostic = true;
  end

  config = default_config(tele);

  if (diagnostic)
    config
  end

  function signal = complex_sinusoid_handle (nbins, frequency, dtype_)
    signal = complex_sinusoid(nbins, [frequency], [pi/4], 0.0, dtype_);
  end

  function signal = time_domain_impulse_handle (nbins, offset, dtype_)
    signal = time_domain_impulse(nbins, [offset], [1], dtype_);
  end

  function handle = time_domain_offsets_factory (npoints)
    function test_params = time_domain_offsets (block_size, nblocks, input_overlap, output_overlap, filt_offset, max_size)
      nbins = max_size;
      jump = block_size - 2*output_overlap;
      test_params = [];
      spaced = filt_offset:jump:nbins;
      test_params = [test_params, spaced];
      test_params = [test_params, spaced(2:end) - output_overlap];
      test_params = [test_params, spaced(1:end-1) + output_overlap];
      test_params = [test_params, filt_offset:block_size:nbins];
      test_params = [test_params, 1:round(nbins/npoints):nbins];
      test_params = sort(test_params);
    end
    handle = @time_domain_offsets;
  end

  function handle = freq_domain_offsets_factory (npoints)
    function test_params = freq_domain_offsets (block_size, nblocks, varargin)
      test_params = (1:round(block_size/npoints):block_size).*nblocks;
    end
    handle = @freq_domain_offsets;
  end

  function handle = freq_domain_performance_factory (fft_length)
    function perf = freq_domain_performance (input, inv)
      p = DomainPerformance();
      perf = p.temporal_difference(input, inv);
      perf = [perf, p.spectral_performance(inv, fft_length)];
    end
    handle = @freq_domain_performance;
  end

  function handle = time_domain_performance_factory (nbins)
    function perf = time_domain_performance (input, inv)
      perf = DomainPerformance().temporal_performance(inv, nbins);
    end
    handle = @time_domain_performance;
  end

  % names_temporal = {'Max Spurious Power of Inverted Signal',...
  %                   'Total Spurious Power of Inverted Signal',...
  %                   'Mean Spurious Power of Inverted Signal'};
  %
  % names_spectral = {'Max Power of Difference of Time Series',...
  %                   'Total Power of Difference of Time Series',...
  %                   'Mean Power of Difference of Time Series',...
  %                   'Max Spurious Power of Spectrum',...
  %                   'Total Spurious Power of Spectrum',...
  %                   'Mean Spurious Power of Spectrum'};

  names_temporal = {'Max Spurious Power of Inverted Signal',...
                    'Total Spurious Power of Inverted Signal'};

  names_spectral = {'Max Power of Difference of Time Series',...
                    'Total Power of Difference of Time Series',...
                    'Max Spurious Power of Spectrum',...
                    'Total Spurious Power of Spectrum'};

  win = PFBWindow();
  factory = win.lookup(config.fft_window);
  window_function = factory(config.input_fft_length, config.input_overlap);
  window_name = config.fft_window;

  title_template = sprintf('%%s performance, %s window function\n%d channels, %d forward FFT, %d overlap',...
    window_name, config.channels, config.input_fft_length, config.input_overlap);
  file_name_template = sprintf('./../products/performance.%%s.%s.%d_chan.%d_fft.%d_overlap.%s.png',...
    window_name, config.channels, config.input_fft_length, config.input_overlap, tele);


  if strcmp(domain, 'time')
    test_overlap = verify_test_vector_params_factory(...
      config,....
      window_function,....
      @time_domain_impulse_handle,....
      time_domain_performance_factory(30),....
      time_domain_offsets_factory(npoints),....
      config.blocks, diagnostic);

    res = feval(test_overlap, config.input_fft_length, config.input_overlap);

    fig = plot_performance_measures(res{:}, names_temporal);

    xlabel('Impulse position');
    h = subtitle(sprintf(title_template, 'Temporal'));
    h.Interpreter = 'none';
    % set(fig, 'visible', 'off');
    saveas(fig, sprintf(file_name_template, 'temporal'));
  end

  if strcmp(domain, 'freq')
    fft_length = 2*normalize(config.os_factor, config.input_fft_length)*config.channels;

    test_overlap = verify_test_vector_params_factory(...
      config,....
      window_function,....
      @complex_sinusoid_handle,....
      freq_domain_performance_factory(fft_length),...
      freq_domain_offsets_factory(npoints),....
      config.blocks, diagnostic);

    res = test_overlap(config.input_fft_length, config.input_overlap);
    freqs = res{1};
    perf = res{2};
    fig = plot_performance_measures(freqs, perf(:, 1:3), {names_spectral{1:3}});

    xlabel('Frequency (Hz)');
    h = suptitle(sprintf(title_template, 'Complex Sinusoid Time Series'));
    h.Interpreter = 'none';
    set(fig, 'visible', 'off');
    saveas(fig, sprintf(file_name_template, 'complex_sinusoid_time_series'));

    fig = plot_performance_measures(freqs, perf(:, 4:6), {names_spectral{4:6}});

    xlabel('Frequency (Hz)');
    h = suptitle(sprintf(title_template, 'Spectral'));
    h.Interpreter = 'none';
    set(fig, 'visible', 'off');
    saveas(fig, sprintf(file_name_template, 'spectral'));
  end
end


function handle = verify_test_vector_params_factory (config,...
                                        window_function_handle,...
                                        signal_generator_handle,...
                                        performance_handle,...
                                        test_param_generator_handle,...
                                        nblocks, diagnostic)
  sample_offset = 1;
  deripple = struct('apply_deripple', config.deripple);
  filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
  filt_offset = round((length(filt_coeff) - 1)/2);
  filt_taps = length(filt_coeff);

  function param_res = verify_test_vector_params (input_fft_length, input_overlap)
    function overlap = calc_overlap (input_fft_length)
      overlap = input_overlap;
    end

    input_overlap = calc_overlap(input_fft_length);
    output_overlap = normalize(config.os_factor, input_overlap)*config.channels;
    output_overlap = output_overlap - 1;

    block_size = normalize(config.os_factor, input_fft_length)*config.channels;
    nbins = nblocks*block_size;

    fprintf('nbins=%d\n', nbins);
    output_nbins = calc_output_nbins(...
        nbins, config.channels, config.os_factor,...
        filt_taps, input_fft_length, input_overlap);
    fprintf('output_nbins=%d\n', output_nbins);

    param_res = [];

    test_params = test_param_generator_handle(...
      block_size, nblocks, input_overlap, output_overlap + 1, filt_offset, output_nbins);

    if diagnostic
      test_params = test_params(12:end);
    end
    prev_bytes = 1;
    fprintf('\n')
    % test_params = [100000];
    for i=1:length(test_params)
      param = test_params(i);
      for b=1:prev_bytes
        fprintf('\b');
      end
      %   prev_bytes = fprintf('polyphase_analysis: %d/%d blocks\n', k, nblocks);
      prev_bytes = fprintf('%d/%d', i, length(test_params));
      res = test_data_pipeline(config, config.channels, config.os_factor,...
                               input_fft_length, nbins,...
                               signal_generator_handle,...
                               {param}, @polyphase_analysis_padded, {1}, ...
                               @polyphase_synthesis, ...
                                {deripple,...
                                 sample_offset,...
                                 @calc_overlap,...
                                 window_function_handle, 1},...
                               config.data_dir);
      chopped = chop(res, output_overlap);
      perf_res = performance_handle(chopped{:});
      param_res = [param_res; perf_res];
      if diagnostic
        diagnostic_plot(res, {output_overlap}, sprintf('Param=%d, total spurious power=%f', param, 10*log10(perf_res(2))));
      end

      if param >= length(chopped{2})
        test_params = test_params(1:i);
        break
      end
    end
    param_res = {test_params, param_res};
  end

  handle = @verify_test_vector_params;
end


function fig = plot_performance_measures(x, perf, names, fig_)
  size_perf = size(perf);
  n_subplots = size_perf(2);
  if exist('fig_', 'var')
    fig = fig_;
  else
    fig = figure('Position', [10 10 1200 400*n_subplots]); %, 'Visible', 'Off');
  end
  for i=1:n_subplots
    ax = subplot(n_subplots, 1, i); grid(ax, 'on');
      plot(x, 10.0*log10(abs(squeeze(perf(:, i))) + 1e-13), '-o');
      ylabel('Signal Level (dB)');
      grid(ax, 'on');
      % set(ax, 'YScale', 'log');
      title(sprintf('%s', names{i}));
  end
end
