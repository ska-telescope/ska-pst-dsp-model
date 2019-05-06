function derippling_effect ()
  % Attempt to quantify the effect derippling has on PFB inversion performance.
  % Generate a plot of the difference between input time domain impulse and
  % the result of PFB inversion, with and without derippling enabled, for a
  % range of FIR filter sizes.

  config = default_config();

  n_blocks = 2;
  block_size = normalize(config.os_factor, config.input_fft_length)*config.n_chan;
  n_bins = n_blocks*block_size;

  pos = 0.25;

  offsets = [floor(pos*n_bins)];
  widths = [1];

  frequencies = [2*n_blocks];
  phases = [pi/4];
  bin_offset = 0.1;

  meta_struct = struct();
  meta_struct.impulse_position = num2str(pos);
  meta_struct.impulse_width = num2str(widths(1));

  function overlap = calc_overlap (input_fft_length)
    overlap = round(input_fft_length / 8);
  end

  n_filters = 2:2:16;
  n_filters = 2;

  deripple_temporal = [];
  noderipple_temporal = [];

  deripple_spectral = [];
  noderipple_spectral = [];

  ntaps = []
  sample_offset = 1;

  perf = DomainPerformance;

  for taps_per_chan=n_filters
    t = config.n_chan*taps_per_chan;
    config.fir_filter_path = design_PFB_FIR_filter(config.n_chan, config.os_factor, t);

    comp_temporal = run_derippling_comparison(...
      config, n_bins, @time_domain_impulse, {offsets, widths}, @perf.temporal_performance, {},  @calc_overlap);
    comp_spectral = run_derippling_comparison(...
      config, n_bins, @complex_sinusoid, {frequencies, phases, bin_offset}, @perf.spectral_performance, {block_size}, @calc_overlap);

    deripple_temporal = [deripple_temporal; comp_temporal{1}{1}];
    noderipple_temporal = [noderipple_temporal; comp_temporal{1}{2}];

    deripple_spectral = [deripple_spectral; comp_spectral{1}{1}];
    noderipple_spectral = [noderipple_spectral; comp_spectral{1}{2}];

    ntaps = [ntaps t];
    if length(n_filters) == 1
      fig = plot_deripple_temporal_performance(...
        comp_temporal{2}{1}{1}, comp_temporal{2}{1}{2}, comp_temporal{2}{2}{2});
        suptitle(sprintf('Derippling Effect, %d Filter Taps', t));
        saveas(fig, sprintf('./../products/derippling_effect.temporal.%d.png', t));
      fig = plot_deripple_spectral_performance(...
        comp_spectral{2}{1}{1}, comp_spectral{2}{1}{2}, comp_spectral{2}{2}{2}, block_size);
      suptitle(sprintf('Derippling Effect, %d Filter Taps', t));
      saveas(fig, sprintf('./../products/derippling_effect.spectral.%d.png', t));


    end

  end
  if length(n_filters) > 1
    fig = figure('Position', [10 10 1200 1200]);
    names = {'Max', 'Total', 'Mean'};
    n_subplots = 3;
    for i=1:n_subplots
      ax = subplot(n_subplots, 1, i); grid(ax, 'on');
        hold on;
        l1 = plot(n_filters, squeeze(deripple_temporal(:, i)), '-o');
        l2 = plot(n_filters, squeeze(noderipple_temporal(:, i)), '-o');
        legend([l1; l2], 'Derippling enabled', 'Derippling disabled');
        hold off;
        xlabel('Filter Taps per Channel');
        ylabel('Signal Level');
        set(ax, 'YScale', 'log');
        title(sprintf('%s spurious power of inverted signal', names{i}));
    end

    suptitle('Effect of derippling correction on temporal purity as a function of number of taps')
    saveas(fig, './../products/derippling_effect.temporal.png');

    fig = figure('Position', [10 10 1200 1200]);
    names = {'Max', 'Total', 'Mean'};
    n_subplots = 3;
    for i=1:n_subplots
      ax = subplot(n_subplots, 1, i); grid(ax, 'on');
        hold on;
        l1 = plot(n_filters, squeeze(deripple_spectral(:, i)), '-o');
        l2 = plot(n_filters, squeeze(noderipple_spectral(:, i)), '-o');
        legend([l1; l2], 'Derippling enabled', 'Derippling disabled');
        hold off;
        xlabel('Filter Taps per Channel');
        ylabel('Signal Level');
        % set(ax, 'YScale', 'log');
        title(sprintf('%s spurious power of inverted signal', names{i}));
    end

    suptitle('Effect of derippling correction on spectral purity as a function of number of taps')
    saveas(fig, './../products/derippling_effect.spectral.png');
  end

end

function argmax = argmax(a)
  [maxval, argmax] = max(a);
end

function dB = dB(a)
  dB = 20.0*log10(abs(a) + 1e-13);
end

function normalized = norm_pow (a)
  normalized = abs(a).^2;
  normalized = normalized ./ max(normalized);
end


function fig = plot_deripple_spectral_performance (in, wi, wo, fft_length)
  fig = figure('Position', [10, 10, 1200, 1200]);
  perf = DomainPerformance;
  n_subplots = 3;

  arr = {in, wi, wo};
  names = {'Input', 'With Derippling', 'No Derippling'};

  for idx=1:length(arr)
    a = fftshift(fft(arr{idx}, fft_length)./fft_length);
    a = a ./max(a);
    name = names{idx};
    fprintf('max of %s: %f\n', name, max(abs(a)));

    res = perf.spectral_performance(arr{idx}, fft_length);
    % res

    ax = subplot(n_subplots, 1, idx);
      l1 = plot(dB(a));
      ylabel('Power Level (dB)');
      title(name);
      grid(ax, 'on');
  end
  xlabel('Frequency bin');
end



function fig = plot_deripple_temporal_performance (in, wi, wo)
  % wi is with deripple
  % wo is without deripple
  perf = DomainPerformance;
  arr = {in, wi, wo};
  names = {'Input', 'With Derippling', 'No Derippling'};
  region = 1000;

  n_subplots = 3;

  offset = argmax(abs(wi))
  argmax(in)
  wo_copy = wo;
  wo_copy(offset) = 0.0;
  max_spurious_val = max(abs(wo_copy))
  % wi(offset) = 0.0;
  % wo(offset) = 0.0;

  fig = figure('Position', [10, 10, 1200, 1200]);
  for idx=1:length(arr)
    a = arr{idx};
    perf.temporal_performance(a)
    name = names{idx};
    ax = subplot(n_subplots, 1, idx);
      l1 = plot(abs(a));
      ylim([0, max_spurious_val*1.2]);
      % xlim([offset-region offset+region]);
      xlabel('Time');
      ylabel('Signal Level');
      title(name);
      grid(ax, 'on');
  end


  % diff = wi - wo;
  % ax = subplot(n_subplots, 1, 3);
  %   l2 = plot(abs(diff));
  %   % set(ax, 'YScale', 'log');
  %   ylim([0, max_spurious_val*1.2]);
  %   xlim([offset-region offset+region]);
  %   xlabel('Time');
  %   ylabel('Signal Level');
  %   title('Difference between input and inverted data');
  %   grid(ax, 'on');
end

function res = run_derippling_comparison(config, n_bins,...
                                         test_vector_handler,...
                                         test_vector_handler_args,...
                                         performance_handler,...
                                         performance_handler_args,...
                                         overlap_handler)
  deripple = struct('apply_deripple', 1);
  sample_offset = 1;
  input_offset = overlap_handler(config.input_fft_length);
  output_offset = normalize(config.os_factor, input_offset)*config.n_chan;

  res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                    config.input_fft_length, n_bins,...
                    test_vector_handler,...
                    test_vector_handler_args, @polyphase_analysis, {1},...
                    @polyphase_synthesis_alt, ...
                    {deripple, sample_offset, overlap_handler},...
                    config.data_dir);

  chopped_deripple = chop(res, output_offset);
  deripple_perf = performance_handler(chopped_deripple{2}, performance_handler_args{:});
  deripple.apply_deripple = 0;

  res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                    config.input_fft_length, n_bins,...
                    test_vector_handler,...
                    test_vector_handler_args,  @polyphase_analysis, {1},...
                    @polyphase_synthesis_alt, ...
                    {deripple, sample_offset, overlap_handler},...
                    config.data_dir);

  chopped_noderipple = chop(res, output_offset);
  noderipple_perf = performance_handler(chopped_noderipple{2}, performance_handler_args{:});
  perf_res = {deripple_perf, noderipple_perf};
  chopped = {chopped_deripple, chopped_noderipple};

  res = {perf_res, chopped};
end
