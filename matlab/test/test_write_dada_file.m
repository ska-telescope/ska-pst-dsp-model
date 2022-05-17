function test_write_dada_file ()
  function test_write_dada_file_ ()
    fprintf('test_write_data_file\n')
    header = containers.Map();
    header('HDR_SIZE') = '4096';

    data = complex(rand(2, 1, 1000, 'single'));

    output_file_path = './../data/test_write_dada_file.dump';

    file_id = fopen(output_file_path, 'w');
    write_dada_file(file_id, data, header);
    fclose(file_id);

    delete(output_file_path);

  end

  function test_write_header ()
    function arr_str = arr2str (arr)
      arr_str = ""
      for i=1:length(arr)
        arr_str = arr_str + sprintf('%0.6E', arr(i));
      end
    end


    fprintf('test_write_header\n')
    output_file_path = './../data/test_write_dada_file.dump';
    file_id = fopen(output_file_path, 'w');
    header = containers.Map();
    header('HDR_SIZE') = '4096';
    write_header(file_id, header);
    fclose(file_id);

    file_id = fopen(output_file_path, 'w');
    header('DATA') = arr2str(1:10000);
    write_header(file_id, header);
    fclose(file_id);

    delete(output_file_path);
  end

  function test_add_fir_filter_to_header ()
    fprintf('test_add_fir_filter_to_header\n')

    header = containers.Map();
    fir = rand(48, 1);
    os_factor = struct('nu', 8, 'de', 7);
    header = add_fir_filter_to_header(header, fir, os_factor);
    assert(header('NSTAGE') == '1');


    firs = {rand(48, 1), rand(60, 1)};
    os_factors = {os_factor, os_factor};
    header = add_fir_filter_to_header(header, firs, os_factors);
    assert(header('NSTAGE') == '2');

  end

  test_write_header;
  test_add_fir_filter_to_header;
  test_write_dada_file_;
end
