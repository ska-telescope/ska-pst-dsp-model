function test_read_header ()
  % test the read_header function on a DADA file

  fprintf('test_read_header\n');


  data_file_path = 'data/simulated_pulsar.noise_0.0.nseries_10.ndim_2.dump';
  file_id = fopen(data_file_path);
  hdr_map = read_header(file_id);

  assert(hdr_map('NCHAN') == '1');
  assert(hdr_map('NDIM') == '2');
  assert(hdr_map('NPOL') == '2');
  assert(hdr_map('HDR_SIZE') == "4096");
  fclose(file_id);

  data_file_path = 'data/pfb.os_8-7.nchan_8.ntaps_321.dump';
  file_id = fopen(data_file_path);
  hdr_map = read_header(file_id);

  assert(hdr_map('NCHAN') == '8');
  assert(hdr_map('NDIM') == '2');
  assert(hdr_map('NPOL') == '2');
  assert(hdr_map('HDR_SIZE') == "8192");
  fclose(file_id);

end
