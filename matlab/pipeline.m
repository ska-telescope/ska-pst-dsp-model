function pipeline ()
  config_struct = struct();
  config_struct.dtype = 'single';
  config_struct.header_file_path = './../config/default_header.json';
  % config_struct.fir_filter_path = './../config/OS_Prototype_FIR_8.mat'; % 6
  % config_struct.fir_filter_path = './../config/Prototype_FIR.32.mat'; % 1
  % config_struct.fir_filter_path = './../config/Prototype_FIR.48.mat'; % 1
  % config_struct.fir_filter_path = './../config/Prototype_FIR.40.mat'; % 5
  % config_struct.fir_filter_path = './../config/Prototype_FIR.120.mat'; % 5
  % config_struct.fir_filter_path = './../config/Prototype_FIR.180.mat'; % 3
  config_struct.fir_filter_path = './../config/Prototype_FIR.240.mat'; % 1
  % config_struct.fir_filter_path = './../config/Prototype_FIR.320.mat'; % 1
  % config_struct.fir_filter_path = './../config/Prototype_FIR.480.mat'; % 1
  % config_struct.fir_filter_path = './../config/ADE_R6_OSFIR.mat';
  n_blocks = 2;
  os_factor = struct('nu', 8, 'de', 7);
  % os_factor = struct('nu', 32, 'de', 27);
  n_chan = 8;
  % n_chan = 768;
  input_fft_length = 1024;
  block_size = normalize(os_factor, input_fft_length)*n_chan;
  % input_fft_length = 16384;
  n_bins = n_blocks*block_size;

  test_vector_dir = './../data';
  if ~exist(test_vector_dir, 'dir')
    mkdir(test_vector_dir)
  end

  pos = 0.1874;

  offsets = [floor(pos*n_bins)];
  widths = [1];

  pos = 0.00002;
  frequencies = [floor(pos*n_bins)];
  phases = [pi/4];
  bin_offset = 0.1;

  meta_struct = struct();
  % meta_struct.impulse_position = num2str(pos);
  % meta_struct.impulse_width = num2str(widths(1));

  deripple = struct('apply_deripple', 1);

  function overlap = calc_overlap (input_fft_length)
    % overlap = 32;
    overlap = 0;
    % overlap = round(input_fft_length / 8);
  end

  sample_offset = 1
  % polyphase_analysis_alt is Ian Morrison's code
  % polyphase_analysis is John Bunton's code
  % res = test_data_pipeline(config_struct, n_chan, os_factor,...
  %                    input_fft_length, n_bins,...
  %                    @time_domain_impulse,...
  %                    {offsets, widths}, @polyphase_analysis_alt, {1}, ...
  %                    @polyphase_synthesis, {sample_offset}, test_vector_dir);
  res = test_data_pipeline(config_struct, n_chan, os_factor,...
                    input_fft_length, n_bins,...
                    @complex_sinusoid,...
                    {frequencies, phases, bin_offset}, @polyphase_analysis, {1},...
                    @polyphase_synthesis_alt, ...
                    {deripple, sample_offset, @calc_overlap},...
                    test_vector_dir);
  meta_file_path = fullfile(test_vector_dir, 'pipeline.freq.meta.json');
  dump_meta_data(res{1}, meta_file_path, meta_struct);

  res = test_data_pipeline(config_struct, n_chan, os_factor,...
                    input_fft_length, n_bins,...
                    @time_domain_impulse,...
                    {offsets, widths}, @polyphase_analysis, {1},...
                    @polyphase_synthesis_alt, ...
                    {deripple, sample_offset, @calc_overlap},...
                    test_vector_dir);

  meta_file_path = fullfile(test_vector_dir, 'pipeline.time.meta.json')
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
