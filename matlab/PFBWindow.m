classdef PFBWindow

  methods

    function windowed = no_window (obj, in_dat, input_fft_length, input_discard)
      windowed = in_dat;
    end

    function windowed = baseball_hat_window (obj, in_dat, input_fft_length, input_discard)
      in_dat(:, 1:input_discard) = complex(0.0);
      % in_dat(:, input_fft_length-input_discard+1:end) = complex(0.0);
      windowed = in_dat;
    end

    function windowed = top_hat_window (obj, in_dat, input_fft_length, input_discard)
      in_dat(:, 1:input_discard) = complex(0.0);
      in_dat(:, input_fft_length-input_discard+1:end) = complex(0.0);
      windowed = in_dat;
    end

    function handle = hann_factory (obj, input_fft_length)
      % h = hann(input_fft_length + 2*input_discard);
      % h = transpose(h(input_discard+1:input_fft_length+input_discard));
      h = hann(input_fft_length);
      h = transpose(h);
      function windowed = hann_window (in_dat, input_fft_length, input_discard)
        windowed = in_dat;
        size_in_dat = size(windowed);
        nchan = size_in_dat(1);
        for ichan=1:nchan
          windowed(ichan, :) = h.*windowed(ichan,:);
        end
      end
      handle = @hann_window;
    end

    function handle = blackman_factory (obj, input_fft_length)
      h = transpose(blackman(input_fft_length));
      function windowed = blackman_window (in_dat, input_fft_length, input_discard)
        windowed = in_dat;
        size_in_dat = size(windowed);
        nchan = size_in_dat(1);
        for ichan=1:nchan
          windowed(ichan, :) = h.*windowed(ichan,:);
        end
      end
      handle = @blackman_window;
    end
  end
end
