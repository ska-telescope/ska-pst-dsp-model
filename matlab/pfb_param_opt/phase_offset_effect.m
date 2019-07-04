function phase_offset_effect()
  config = default_config();

  config.input_fft_length = 1024;
  config.fir_filter_path = fullfile(config.config_dir, 'Prototype_FIR.4-3.8.80.mat');
  config.n_chan = 8;
  % config.os_factor = struct('nu', 8, 'de', 7);

  n_blocks = 2;
  block_size = normalize(config.os_factor, config.input_fft_length)*config.n_chan;
  n_bins = n_blocks*block_size;
  offsets = [round(block_size/2)];
  widths = [1];

  meta_struct = struct();

  deripple = struct('apply_deripple', 1);

  function overlap = calc_overlap (input_fft_length)
    overlap = 0;
  end

  for sample_offset = 9
    % polyphase_analysis_alt is Ian Morrison's code
    % polyphase_analysis is John Bunton's code
    res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                             config.input_fft_length, n_bins,...
                             @time_domain_impulse, {offsets, widths}, ...
                             @polyphase_analysis, {1}, ...
                             @polyphase_synthesis_alt, {deripple, sample_offset, @calc_overlap},...
                             config.data_dir);

    data = res{2};
    meta = res{3};


    size_inv = size(data{3});
    ndat_inv = size_inv(3);

    sim_squeezed = squeeze(data{1}(1, 1, :));
    inv_squeezed = squeeze(data{3}(1, 1, :));

    output_shift = meta.fir_offset;
    % output_shift = output_shift + config.os_factor.de*(sample_offset - 1);
    output_shift = output_shift + config.n_chan*config.os_factor.de*(sample_offset - 1)/config.os_factor.nu;

    sim_squeezed = sim_squeezed(output_shift+1:end);
    sim = sim_squeezed(1:ndat_inv);
    inv = inv_squeezed(1:ndat_inv);
    xcorr = fft(sim) .* conj(fft(inv));

    lag = ifft(xcorr);
    [valmax, argmax] = max(lag);
    if argmax > round(length(lag)/2)
      argmax = length(lag) - argmax;
    end
    fprintf('Lag=%d\n', argmax);
    fig = plot_offset_effect(sim, inv, xcorr);
    suptitle(sprintf('Sample Offset %d', sample_offset - 1));
    saveas(fig, sprintf('./../products/sample_offset.%d.png', sample_offset - 1));
  end
end

function db = db(a)
  db = 20.0*log10(a);
end

function fig = plot_offset_effect (input, inverted, xcorr)
  fig = figure('Position', [10, 10, 1200, 900]);

  n_subplots = 3;

  input_idx = 1;
  ax = subplot(n_subplots, 2, input_idx);
  plot(abs(input));
    grid(ax, 'on');
    ylim([-0.1 1.5]);
    xlabel('Time');
    ylabel('Signal level');
    title('Input Signal');

  input_norm = abs(input) ./ max(abs(input));
  ax = subplot(n_subplots, 2, input_idx + 1);
  plot(db(input_norm + 1e-13));
    grid(ax, 'on');
    xlabel('Time');
    ylabel('Signal level (dB)');
    title('Input Signal');

  inv_idx = 3;
  ax = subplot(n_subplots, 2, inv_idx);
  plot(abs(inverted));
    grid(ax, 'on');
    ylim([-0.1 1.5]);
    xlabel('Time');
    ylabel('Signal level');
    title('Inverted Signal');

  inverted_norm = abs(inverted) ./ max(abs(inverted));
  ax = subplot(n_subplots, 2, inv_idx + 1);
  plot(db(inverted_norm + 1e-13));
    grid(ax, 'on');
    xlabel('Time');
    ylabel('Signal level (dB)');
    title('Inverted Signal');


  % ax = subplot(n_subplots, 2, 3);
  % plot(abs(inv));
  %   grid(ax, 'on');
  %   inv_copy = inv;
  %   inv_copy(argmax_inv) = complex(0, 0);
  %   sum(abs(inv_copy))
  %   xlim([argmax_inv-100, argmax_inv+100]);
  %   ylim([0, abs(max(inv_copy))*1.2]);
  xcorr_idx = 5;
  ax = subplot(n_subplots, 2, [xcorr_idx xcorr_idx+1]);
  plot(angle(xcorr));
    grid(ax, 'on');
    xlabel('Frequency bin');
    ylabel('Radians');
    title('Phase of cross correlation between input and inverted signals');
end
