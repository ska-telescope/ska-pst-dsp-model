% input_file_path = './noise.dump';
input_file_path = './data/simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump';

fir_filter_path = './config/OS_Prototype_FIR_8.mat';

channelized_file_name = 'channelized.noise.dump';
synthesized_file_name = 'synthesized.2.noise.dump';
output_dir = './';

% channelize(input_file_path, '8', '8/7', fir_filter_path, channelized_file_name, output_dir, '1');
synthesize(channelized_file_name, '1024', synthesized_file_name, output_dir, '1');
