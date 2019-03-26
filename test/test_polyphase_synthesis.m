function test_polyphase_synthesis ()
  % simple test to determine if the polyphase_synthesis function will run


  input_fft_length = 256;
  os_factor = struct('nu', 8, 'de', 7);

  n_pol = 2;
  n_chan = 8;
  n_dat = 16384;
  test_vector = rand(n_pol, n_chan, n_dat);

  polyphase_synthesis(test_vector, input_fft_length, os_factor);

end
