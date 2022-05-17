function pipeline()
  config = default_config();
  config.dtype = 'single';
  config.header_file_path = './../config/default_header.json';
  config.fir_filter_path = './../config/Prototype_FIR.8-7.8.80.mat'; % 1

  n_blocks = 4000;
  % config.os_factor = struct('nu', 8, 'de', 7);
  % config.n_chan = 8;
  config.input_fft_length = 128;
  block_size = normalize(config.os_factor, config.input_fft_length)*config.n_chan;
  n_bins = n_blocks*block_size;
  n_bins

  pos = 0.1874;

  offsets = [floor(pos*n_bins)];
  widths = [1];

  % pos = 0.000001;
  % frequencies = [floor(pos*n_bins)];
  frequencies = [4];
  phases = [pi/4];
  bin_offset = 0.0;

  meta_struct = struct();
  % meta_struct.impulse_position = num2str(pos);
  % meta_struct.impulse_width = num2str(widths(1));

  deripple = struct('apply_deripple', 1);

  function overlap = calc_overlap (input_fft_length)
    % overlap = 32;
    overlap = 0;
    % overlap = round(config.input_fft_length / 8);
  end

  sample_offset = 1
  % polyphase_analysis_alt is Ian Morrison's code
  % polyphase_analysis is John Bunton's code
  % res = test_data_pipeline(config, config.n_chan, config.os_factor,...
  %                    config.input_fft_length, n_bins,...
  %                    @time_domain_impulse,...
  %                    {offsets, widths}, @polyphase_analysis_alt, {1}, ...
  %                    @polyphase_synthesis, {sample_offset}, config.data_dir);
  res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                           config.input_fft_length, n_bins,...
                           @complex_sinusoid,...
                           {frequencies, phases, bin_offset}, @polyphase_analysis, {1},...
                           @polyphase_synthesis, ...
                           {deripple, sample_offset, @calc_overlap},...
                           config.data_dir);

  meta_file_path = fullfile(config.data_dir, 'pipeline.freq.meta.json');
  dump_meta_data(res{1}, meta_file_path, meta_struct);

  res = test_data_pipeline(config, config.n_chan, config.os_factor,...
                           config.input_fft_length, n_bins,...
                           @time_domain_impulse,...
                           {offsets, widths}, @polyphase_analysis, {1},...
                           @polyphase_synthesis, ...
                           {deripple, sample_offset, @calc_overlap},...
                           config.data_dir);

  meta_file_path = fullfile(config.data_dir, 'pipeline.time.meta.json');
  dump_meta_data(res{1}, meta_file_path, meta_struct);

end


function dump_meta_data(file_info, file_path, meta_struct)
  meta_struct.input_file = file_info{1};
  meta_struct.channelized_file = file_info{2};
  meta_struct.inverted_file = file_info{3};
  json_meta_str = jsonencode(meta_struct);
  fid = fopen(file_path,'wt');
  fprintf(fid, json_meta_str);
  fclose(fid);
end
