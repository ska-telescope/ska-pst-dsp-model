function overlap_parameter_search()
  config = default_config;
  % config.n_chan = 16;
  % config.fir_filter_path = './../config/Prototype_FIR.4-3.16.160.mat';

  function signal = complex_sinusoid_handle(nbins, frequency, dtype_)
    signal = complex_sinusoid(nbins, [frequency], [pi/4], 0.0, dtype_);
  end

  function signal = time_domain_impulse_handle(nbins, offset, dtype_)
    signal = time_domain_impulse(nbins, [offset], [1], dtype_);
  end

  function handle = time_domain_offsets_factory(npoints)
    function test_params = time_domain_offsets(block_size, nblocks, input_overlap, output_overlap, filt_offset)
      nbins = block_size*nblocks;
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

  function handle = freq_domain_offsets_factory(npoints)
    function test_params = freq_domain_offsets(block_size, nblocks, varargin)
      test_params = (1:round(block_size/npoints):block_size).*nblocks;
    end
    handle = @freq_domain_offsets;
  end

  function handle = freq_domain_performance_factory(fft_length);
    function perf = freq_domain_performance(input, inv)
      p = DomainPerformance();
      perf = p.temporal_difference(input, inv);
      perf = [perf, p.spectral_performance(inv, fft_length)];
    end
    handle = @freq_domain_performance;
  end

  function perf = time_domain_performance(input, inv)
    perf = DomainPerformance().temporal_performance(inv);
  end

  npoints = 200;
  nblocks = 3;
  % input_fft_lengths = [512, 1024, 2048];
  % overlap_sizes = [128, 256, 512];
  input_fft_lengths = [1024];
  overlap_sizes = [128];

  names_temporal = {'Max Spurious Power of Inverted Signal',...
                    'Total Spurious Power of Inverted Signal',...
                    'Mean Spurious Power of Inverted Signal'};

  names_spectral = {'Max Power of Difference of Time Series',...
                    'Total Power of Difference of Time Series',...
                    'Mean Power of Difference of Time Series',...
                    'Max Spurious Power of Spectrum',...
                    'Total Spurious Power of Spectrum',...
                    'Mean Spurious Power of Spectrum'};
  for input_fft_length=input_fft_lengths
    for overlap_size=overlap_sizes
      if input_fft_length / overlap_size <= 2
        continue
      end
      win = PFBWindow()
      window_function = PFBWindow().tukey_factory(...
        input_fft_length, overlap_size);
      % window_function = PFBWindow().fedora_factory(2);
      % window_function = @win.no_window;

      window_name = get_function_name(window_function);

      title_template = sprintf('%%s performance, %s window function\n%d channels, %d forward FFT, %d overlap',...
        window_name, config.n_chan, input_fft_length, overlap_size);
      file_name_template = sprintf('./../products/performance.%%s.%s.%d_chan.%d_fft.%d_overlap.png',...
        window_name, config.n_chan, input_fft_length, overlap_size);


      % test_overlap = test_overlap_factory(...
      %   config,....
      %   window_function,....
      %   @time_domain_impulse_handle,....
      %   @time_domain_performance,....
      %   time_domain_offsets_factory(npoints),....
      %   nblocks);
      %
      %
      % res = test_overlap(input_fft_length, overlap_size);
      %
      % fig = plot_performance_measures(res{:}, names_temporal);
      %
      %
      % xlabel('Impulse position');
      % h = suptitle(sprintf(title_template, 'Temporal'));
      % h.Interpreter = 'none';
      % set(fig, 'visible', 'off');
      % saveas(fig, sprintf(file_name_template, 'temporal'));

      fft_length = 2*normalize(config.os_factor, input_fft_length)*config.n_chan;

      test_overlap = test_overlap_factory(...
        config,....
        window_function,....
        @complex_sinusoid_handle,....
        freq_domain_performance_factory(fft_length),...
        freq_domain_offsets_factory(npoints),....
        nblocks);

      res = test_overlap(input_fft_length, overlap_size);
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
end


function handle = test_overlap_factory(config,...
                                        window_function_handle,...
                                        signal_generator_handle,...
                                        performance_handle,...
                                        test_param_generator_handle,...
                                        nblocks)
  sample_offset = 1;
  deripple = struct('apply_deripple', 1);
  filt_coeff = read_fir_filter_coeff(config.fir_filter_path);
  filt_offset = round((length(filt_coeff) - 1)/2);

  function param_res = test_overlap(input_fft_length, overlap_size)
    function overlap = calc_overlap(input_fft_length)
      overlap = overlap_size;
    end

    input_overlap = calc_overlap(input_fft_length);
    output_overlap = normalize(config.os_factor, input_overlap)*config.n_chan;

    block_size = normalize(config.os_factor, input_fft_length)*config.n_chan;
    nbins = nblocks*block_size;

    param_res = [];

    test_params = test_param_generator_handle(block_size, nblocks, input_overlap, output_overlap, filt_offset);

    for param=test_params
      res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                               input_fft_length, nbins,...
                               signal_generator_handle,...
                               {param}, @polyphase_analysis, {1}, ...
                               @polyphase_synthesis, ...
                                {deripple,...
                                 sample_offset,...
                                 @calc_overlap,...
                                 window_function_handle},...
                               config.data_dir);
      chopped = chop(res, output_overlap);
      perf_res = performance_handle(chopped{:});
      % ax = subplot(2, 1, 1)
      % plot(real(chopped{1}))
      % ax = subplot(2, 1, 2)
      % plot(real(chopped{2}))
      % ylim([-1 1])
      %
      %
      % for i=1:length(perf_res)
      %   fprintf('%f, %f\n', perf_res(i), 10*log10(perf_res(i) + 1e-13));
      % end
      % pause
      param_res = [param_res; perf_res];
    end
    param_res = {test_params, param_res};
  end

  handle = @test_overlap;
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
