function test_polyphase_synthesis_techniques ()
  % run `polyphase_synthesis` and `polyphase_synthesis_alt` on some sample
  % data. Attempt to quantify the diffrence between the two implementations.

  input_fft_length = 256;
  os_factor = struct('nu', 8, 'de', 7);

  n_pol = 2;
  n_chan = 8;
  n_dat = 16384;
  test_vector = rand(n_pol, n_chan, n_dat);

  out1 = polyphase_synthesis(test_vector, input_fft_length, os_factor);
  out2 = polyphase_synthesis_alt(test_vector, input_fft_length, os_factor);


end
