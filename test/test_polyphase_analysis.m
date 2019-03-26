function test_polyphase_analysis ()
  % simple test to determine if the polyphase_analysis function will run

  n_chan = 8;
  os_factor = struct('nu', 8, 'de', 7);
  test_vector = complex(rand(n_chan*100, 1));
  filt = rand(48, 1);

  polyphase_analysis(test_vector, filt, n_chan, os_factor);
end
