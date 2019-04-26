function pipeline ()
  config_struct = struct();
  config_struct.dtype = 'single';
  config_struct.header_file_path = './../config/default_header.json';
  % config_struct.fir_filter_path = './../config/OS_Prototype_FIR_8.mat'; % 6
  config_struct.fir_filter_path = './../config/Prototype_FIR.48.mat'; % 5
  % config_struct.fir_filter_path = './../config/Prototype_FIR.40.mat'; % 5
  % config_struct.fir_filter_path = './../config/Prototype_FIR.120.mat'; % 5
  % config_struct.fir_filter_path = './../config/Prototype_FIR.180.mat'; % 3
  % config_struct.fir_filter_path = './../config/Prototype_FIR.240.mat'; % 1
  % config_struct.fir_filter_path = './../config/Prototype_FIR.320.mat'; % 1
  % config_struct.fir_filter_path = './../config/Prototype_FIR.480.mat'; % 1
  % config_struct.fir_filter_path = './../config/ADE_R6_OSFIR.mat';
  n_blocks = 2;
  os_factor = struct('nu', 8, 'de', 7);
  % os_factor = struct('nu', 32, 'de', 27);
  n_chan = 8;
  % n_chan = 768;
  input_fft_length = 256;
  block_size = normalize(os_factor, input_fft_length)*n_chan;
  % input_fft_length = 16384;
  n_bins = n_blocks*block_size;

  test_vector_dir = './../data';
  if ~exist(test_vector_dir, 'dir')
    mkdir(test_vector_dir)
  end

  fprintf('Generating, channelizing and inverting time domain test vectors\n')
  pos = 0.11;
  fprintf('Creating input data with input at %.3f percent of total band\n', pos*100);

  offsets = [floor(pos*n_bins)];
  widths = [1];

  meta_struct = struct();
  meta_struct.impulse_position = num2str(pos);
  meta_struct.impulse_width = num2str(widths(1));

  deripple = struct('apply_deripple', 1);

  for sample_offset = 1:9
    % polyphase_analysis_alt is Ian Morrison's code
    % polyphase_analysis is John Bunton's code
    % res = test_data_pipeline(config_struct, n_chan, os_factor,...
    %                    input_fft_length, n_bins,...
    %                    @time_domain_impulse,...
    %                    {offsets, widths}, @polyphase_analysis_alt, {1}, ...
    %                    @polyphase_synthesis, {sample_offset}, test_vector_dir);
    res = test_data_pipeline(config_struct, n_chan, os_factor,...
                      input_fft_length, n_bins,...
                      @time_domain_impulse,...
                      {offsets, widths}, @polyphase_analysis, {1},...
                      @polyphase_synthesis_alt, {deripple, sample_offset}, test_vector_dir);

    file_info = res{1};
    data = res{2};

    size_inv = size(data{3});
    ndat_inv = size_inv(3);

    chan_dat = squeeze(data{2}(1, :, :));
    % figure;
    % for ichan=1:n_chan
    %   ax = subplot(n_chan, 1, ichan);
    %   plot(real(chan_dat(ichan, :)), 'red');
    %   plot(imag(chan_dat(ichan, :)), 'green');
    %   grid(ax, 'on');
    % end
    sim_squeezed = squeeze(data{1}(1, 1, :));
    inv_squeezed = squeeze(data{3}(1, 1, :));
    [valmax_sim, argmax_sim] = max(sim_squeezed);
    [valmax_inv, argmax_inv] = max(inv_squeezed);
    fprintf("argmax sim=%d, max sim=%f\n", argmax_sim, valmax_sim);
    fprintf("argmax inv=%d, max inv=%f\n", argmax_inv, valmax_inv);

    % diff_argmax = argmax_sim - argmax_inv;

    output_shift = os_factor.de * (sample_offset - 1);

    sim_squeezed = sim_squeezed(output_shift+1:end);
    sim_squeezed = sim_squeezed(1:ndat_inv);
    inv_squeezed = inv_squeezed(1:ndat_inv);

    figure;
    ax = subplot(411); plot(abs(sim_squeezed)); grid(ax, 'on');
    title(sprintf("sample offset:%d", sample_offset));
    ax = subplot(412);
    hold on;
    plot(abs(inv_squeezed)); grid(ax, 'on');
    for block_bound=1:n_blocks-1
      x = block_bound*block_size;
      l = line([x, x], get(ax,'YLim'), "Color", [1 0 0 0.3]);
    end
    hold off
    xcorr = fft(sim_squeezed) .* conj(fft(inv_squeezed));
    lag = ifft(xcorr);
    [valmax, argmax] = max(lag);
    if argmax > round(length(lag)/2)
      argmax = length(lag) - argmax;
    end
    fprintf("Lag=%d\n", argmax);
    ax = subplot(413); plot(abs(inv_squeezed)); grid(ax, 'on');
    inv_copy = inv_squeezed;
    inv_copy(argmax_inv) = complex(0, 0);
    xlim([offsets(1)-100, offsets(1)+100]);
    ylim([0, abs(max(inv_copy))*1.2]);
    % ax = subplot(413); plot(abs(lag)); grid(ax, 'on');
    ax = subplot(414); plot(angle(xcorr)); grid(ax, 'on');
    % ax = subplot(413); plot(angle(fft(sim_squeezed))); grid(ax, 'on');
    % ax = subplot(414); plot(angle(fft(inv_squeezed))); grid(ax, 'on');
  end

  meta_struct.input_file = file_info{1};
  meta_struct.channelized_file = file_info{2};
  meta_struct.inverted_file = file_info{3};
  meta_file_path = fullfile(test_vector_dir, 'pipeline.meta.json');
  json_meta_str = jsonencode(meta_struct);
  fid = fopen(meta_file_path,'wt');
  fprintf(fid, json_meta_str);
  fclose(fid);
end
