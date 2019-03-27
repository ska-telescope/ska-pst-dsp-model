function test_polyphase_analysis_techniques ()
  % run `polyphase_analysis` and `polyphase_analysis_alt` in order to determine
  % how the two implementations differ.


  n_chan = 8;
  os_factor = struct('nu', 8, 'de', 7);
  test_vector = complex(rand(n_chan*100, 1));
  filt = rand(48, 1);

  out1 = polyphase_analysis(test_vector, filt, n_chan, os_factor);
  out2 = polyphase_analysis_alt(test_vector, filt, n_chan, os_factor);

  
end
