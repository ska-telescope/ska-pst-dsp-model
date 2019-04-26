function generate_test_vectors ()
  config_struct = struct();
  config_struct.dtype = 'single';
  config_struct.header_file_path = './../config/default_header.json';
  config_struct.fir_filter_path = './../config/OS_Prototype_FIR_8.mat';

  os_factor = struct('nu', 8, 'de', 7);
  n_chan = 8;
  input_fft_length = 1024;
  % input_fft_length = 16384;
  n_bins = 5*normalize(os_factor, input_fft_length)*n_chan;

  fprintf('Generating, channelizing and inverting frequency domain test vectors\n')
  fprintf('Each vector will have %d complex elements\n', n_bins)

  test_vector_dir = './../data/test_vectors';
  if ~exist(test_vector_dir, 'dir')
    mkdir(test_vector_dir)
  end

  % for pos=0.01:0.05:1
  for pos=0.1:2:1
    fprintf('Creating input data with frequency at %.3f percent of total band\n', pos*100);
    frequencies = [floor(pos*n_bins)];
    phases = [pi/4];
    bin_offset = 0.1;

    freq_dir = fullfile(test_vector_dir, 'freq');
    if ~exist(freq_dir, 'dir')
      mkdir(freq_dir);
    end

    freq_sub_dir = fullfile(freq_dir, sprintf('f-%.3f_b-%.3f_p-%.3f', pos, bin_offset, phases(1)));
    if ~exist(freq_sub_dir, 'dir')
      mkdir(freq_sub_dir);
    end

    meta_struct = struct();
    meta_struct.freq_position = num2str(pos);
    meta_struct.phase = num2str(phases(1));
    meta_struct.bin_offset = num2str(bin_offset);


    file_info_alt = test_data_pipeline(config_struct, n_chan, os_factor,...
                       input_fft_length, n_bins,...
                       @complex_sinusoid,...
                       {frequencies, phases, bin_offset},...
                       @polyphase_analysis_alt, {}, ...
                       @polyphase_synthesis_alt, {1}, freq_sub_dir);

   % file_info = test_data_pipeline(config_struct, n_chan, os_factor,...
   %                    input_fft_length, n_bins,...
   %                    @complex_sinusoid,...
   %                    {frequencies, phases, bin_offset}, @polyphase_analysis,...
   %                    @polyphase_synthesis, freq_sub_dir);

    meta_struct.input_file = file_info_alt{1};
    meta_struct.channelized_file = file_info_alt{2};
    meta_struct.inverted_file = file_info_alt{3};
    % meta_struct.channelized_file_alt = file_info{2};
    % meta_struct.inverted_file_alt = file_info{3};
    meta_file_path = fullfile(freq_sub_dir, 'meta.json');
    json_meta_str = jsonencode(meta_struct);
    fid = fopen(meta_file_path,'wt');
    fprintf(fid, json_meta_str);
    fclose(fid);

  end
  % fprintf('Generating, channelizing and inverting time domain test vectors\n')
  % for pos=0.01:0.05:1
  % % for pos=0.01:2:1
  %   fprintf('Creating input data with input at %.3f percent of total band\n', pos*100);
  %
  %   offsets = [floor(pos*n_bins)];
  %   if offsets(1) == 0
  %     offsets(1) = 1;
  %   end
  %   widths = [1];
  %
  %   freq_dir = fullfile(test_vector_dir, 'time');
  %   if ~exist(freq_dir, 'dir')
  %     mkdir(freq_dir);
  %   end
  %
  %   freq_sub_dir = fullfile(freq_dir, sprintf('o-%.3f_w-%.3f', pos, widths(1)));
  %   if ~exist(freq_sub_dir, 'dir')
  %     mkdir(freq_sub_dir);
  %   end
  %
  %   meta_struct = struct();
  %   meta_struct.impulse_position = num2str(pos);
  %   meta_struct.impulse_width = num2str(widths(1));
  %
  %
  %   file_info_alt = test_data_pipeline(config_struct, n_chan, os_factor,...
  %                      input_fft_length, n_bins,...
  %                      @time_domain_impulse,...
  %                      {offsets, widths}, @polyphase_analysis_alt,...
  %                      @polyphase_synthesis, freq_sub_dir);
  %
  %  % file_info = test_data_pipeline(config_struct, n_chan, os_factor,...
  %  %                    input_fft_length, n_bins,...
  %  %                    @time_domain_impulse,...
  %  %                    {offsets, widths}, @polyphase_analysis,...
  %  %                    @polyphase_synthesis, freq_sub_dir);
  %
  %   meta_struct.input_file = file_info_alt{1};
  %   meta_struct.channelized_file = file_info_alt{2};
  %   meta_struct.inverted_file = file_info_alt{3};
  %   % meta_struct.channelized_file_alt = file_info{2};
  %   % meta_struct.inverted_file_alt = file_info{3};
  %   meta_file_path = fullfile(freq_sub_dir, 'meta.json');
  %   json_meta_str = jsonencode(meta_struct);
  %   fid = fopen(meta_file_path,'wt');
  %   fprintf(fid, json_meta_str);
  %   fclose(fid);
  %
  % end
end
