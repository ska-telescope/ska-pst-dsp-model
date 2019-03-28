function test_polyphase_analysis ()

  function test_sample_data ()
    % simple test to determine if the polyphase_analysis function will run

    n_chan = 8;
    n_pol = 2;
    os_factor = struct('nu', 8, 'de', 7);
    test_vector = complex(rand(n_pol, 1, n_chan*100));
    filt = rand(48, 1);

    polyphase_analysis(test_vector, filt, n_chan, os_factor);
    polyphase_analysis_alt(test_vector, filt, n_chan, os_factor);
  end

  function test_simulated_pulsar_data ()

    input_file_path = 'data/simulated_pulsar.noise_0.0.nseries_10.ndim_2.dump';
    fir_filter_path = 'config/OS_Prototype_FIR_8.mat';

    file_id = fopen(input_file_path); data_header = read_dada_file (file_id); fclose(file_id);
    data = data_header{1};
    header = data_header{2};
    input_tsamp = str2num(header('TSAMP'));
    fir_filter_coeff = read_fir_filter_coeff(fir_filter_path);

    n_pol = str2num(header('NPOL'));

    n_chan = 8;
    os_factor = struct('nu', 8, 'de', 7);

    header('TSAMP') = num2str(normalize(os_factor, input_tsamp) * n_chan);
    header('PFB_DC_CHAN') = '1';
    header('OS_FACTOR') = sprintf('%d/%d', os_factor.nu, os_factor.de);
    add_fir_filter_to_header(header, fir_filter_coeff, os_factor);
    size_data = size(data);
    n_dat = size_data(3);
    n_dat_process = floor(0.2*n_dat);

    out = polyphase_analysis_alt(data(:, :, 1:n_dat_process), fir_filter_coeff, n_chan, os_factor);
    % out = polyphase_analysis_alt(data, fir_filter_coeff, n_chan, os_factor);

    output_file_path = 'data/channelized.alt.simulated_pulsar.noise_0.0.nseries_10.ndim_2.dump';
    file_id = fopen(output_file_path, 'w');
    write_dada_file(file_id, out, header);
    fclose(file_id);

    out = polyphase_analysis(data(:, :, 1:n_dat_process), fir_filter_coeff, n_chan, os_factor);
    % out = polyphase_analysis(data, fir_filter_coeff, n_chan, os_factor);

    output_file_path = 'data/channelized.simulated_pulsar.noise_0.0.nseries_10.ndim_2.dump';
    file_id = fopen(output_file_path, 'w');
    write_dada_file(file_id, out, header);
    fclose(file_id);


  end

  test_sample_data;
  test_simulated_pulsar_data;
end
