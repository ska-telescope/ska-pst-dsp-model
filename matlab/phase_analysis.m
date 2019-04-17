% input_file_path = './noise.dump';
input_file_path = './data/simulated_pulsar.noise_0.0.nseries_3.ndim_2.dump';

fir_filter_path = './config/OS_Prototype_FIR_8.mat';

% channelized_file_path = './../data/channelized.noise.dump';
channelized_file_path = './../data/channelized.time_domain_impulse.229376.0.110-1.000.2.single.python.dump';
% channelized_file_path = './../data/channelized.complex_sinusoid.229376.0.110-0.785-0.100.2.single.python.dump';
% channelize(input_file_path, '8', '8/7', fir_filter_path, channelized_file_path, output_dir, '1');

output_dir = './../data';

for offset=1:22
  synthesized_file_name = sprintf('synthesized.%d.time_domain_impulse.dump', offset);
  synthesize(channelized_file_path, '1024',...
    synthesized_file_name, output_dir, '1', num2str(offset));
end
