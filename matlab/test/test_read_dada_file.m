function test_read_dada_file ()

  function test_read_header ()
    % test the read_header function on a DADA file

    fprintf('test_read_header\n');
    data_file_path = './../data/simulated_pulsar.noise_0.0.nseries_10.ndim_2.dump';
    file_id = fopen(data_file_path);
    hdr_map = read_header(file_id);

    assert(hdr_map('NCHAN') == '1');
    assert(hdr_map('NDIM') == '2');
    assert(hdr_map('NPOL') == '2');
    assert(hdr_map('HDR_SIZE') == "4096");
    fclose(file_id);

    data_file_path = './../data/pfb.os_8-7.nchan_8.ntaps_321.dump';
    file_id = fopen(data_file_path);
    hdr_map = read_header(file_id);

    assert(hdr_map('NCHAN') == '8');
    assert(hdr_map('NDIM') == '2');
    assert(hdr_map('NPOL') == '2');
    assert(hdr_map('HDR_SIZE') == "8192");
    fclose(file_id);

  end

  % test the read_dada_file function on a DADA file
  function test_read_dada_file_ ()
    fprintf('test_read_dada_file\n');

    % the following is a single channel DADA file
    % data_file_path = './../data/simulated_pulsar.noise_0.0.nseries_10.ndim_2.dump';
    % the following data file is a multichannel DADA file
    data_file_path = './../data/py_channelized.simulated_pulsar.noise_0.0.nseries_10.ndim_2.os.dump';

    file_id = fopen(data_file_path);
    data_header = read_dada_file(file_id);
    fclose(file_id);

    data = data_header{1};
    header = data_header{2};

  end

  test_read_header;
  test_read_dada_file_;


end
