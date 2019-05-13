classdef PFBWindow

  methods

    function windowed = no_window (obj, in_dat, input_fft_length, input_discard)
      windowed = in_dat;
    end

    function handle = tukey_factory (obj, input_fft_length, input_discard)
      window = ones(1, input_fft_length);
      h = transpose(hann(2*input_discard));
      window(1:input_discard) = h(1:input_discard);
      window(input_fft_length - input_discard+1:end) = h(input_discard+1:end);
      % input_discard_2 = round(input_discard*0.75);
      % h = transpose(hann(input_discard_2*2));
      % window(1:input_discard_2) = h(1:input_discard_2);
      % window(input_fft_length - input_discard_2+1:end) = h(input_discard_2+1:end);


      function windowed = tukey_window (in_dat, input_fft_length, input_discard)
        windowed = in_dat;
        size_in_dat = size(windowed);
        nchan = size_in_dat(1);
        for ichan=1:nchan
          windowed(ichan, :) = window.*windowed(ichan,:);
        end
      end
      handle = @tukey_window;
    end


    function handle = fedora_factory (obj, fraction)
      function windowed = fedora_window (in_dat, input_fft_length, input_discard)
        if fraction == 0
          windowed = in_dat;
        else
          discard = round(input_discard / fraction) ;
          in_dat(:, 1:discard) = complex(0.0);
          in_dat(:, input_fft_length-discard+1:end) = complex(0.0);
          windowed = in_dat;
        end
      end
      handle = @fedora_window;
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
