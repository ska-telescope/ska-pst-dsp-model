function test_polyphase_synthesis ()
  % simple test to determine if the polyphase_synthesis function will run
  function test_polyphase_synthesis_()
    input_fft_length = 256;
    os_factor = struct('nu', 8, 'de', 7);

    n_pol = 2;
    n_chan = 8;
    n_dat = 16384;
    test_vector = rand(n_pol, n_chan, n_dat);
    % test_vector = reshape(1:n_pol*n_chan*n_dat, n_pol, n_chan, n_dat);
    out = polyphase_synthesis(test_vector, input_fft_length, os_factor);
    out_alt = polyphase_synthesis_alt(test_vector, input_fft_length, os_factor);
    diff_real = abs(real(out) - real(out_alt));
    sum(diff_real(:))
    diff_imag = abs(imag(out) - imag(out_alt));
    sum(diff_imag(:))


    ax = subplot(311);
    plot(abs(reshape(out, numel(out), 1)));
    title('Inversion, method 1')
    grid(ax, 'on');

    ax = subplot(312);
    plot(abs(reshape(out_alt, numel(out_alt), 1)));
    title('Inversion, method 2')
    grid(ax, 'on');


    ax = subplot(313);
    plot(abs(reshape(diff_real, numel(diff_real), 1)));
    title('Difference (Real component)')
    grid(ax, 'on');

    saveas(gcf, './../products/test_polyphase_synthesis.png');
  end

  function test_simulated_pulsar_data ()

    input_fft_length = 32768;
    os_factor = struct('nu', 8, 'de', 7);

    input_file_path = './../data/simulated_pulsar.noise_0.0.nseries_10.ndim_2.dump';
    file_id = fopen(input_file_path);
    data_header = read_dada_file(file_id);
    input_data = data_header{1};
    input_header = data_header{2};
    fclose(file_id);


    channelized_file_path = './../data/full_channelized_simulated_pulsar.noise_0.0.nseries_10.ndim_2.os.dump';
    file_id = fopen(channelized_file_path);
    data_header = read_dada_file(file_id);
    data = data_header{1};
    header = data_header{2};
    fclose(file_id);

    inverted = polyphase_synthesis(data, input_fft_length, os_factor);
    inverted_alt = polyphase_synthesis_alt(data, input_fft_length, os_factor);

    diff_real = abs(real(inverted) - real(inverted_alt));
    sum(diff_real(:))
    diff_imag = abs(imag(inverted) - imag(inverted_alt));
    sum(diff_imag(:))


    ax = subplot(211);
    plot(abs(reshape(inverted, numel(inverted), 1)));
    title('channelized, inverted simulated pulsar data')
    grid(ax, 'on');

    ax = subplot(212);
    plot(abs(reshape(input_data, numel(input_data), 1)));
    title('simulated pulsar data')
    grid(ax, 'on');

    saveas(gcf, './../products/test_polyphase_synthesis.png');

  end

  test_polyphase_synthesis_;
  test_simulated_pulsar_data;

end
