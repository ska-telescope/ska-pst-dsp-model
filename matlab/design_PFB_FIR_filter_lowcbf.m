function fir_filter_path = design_PFB_FIR_filter_lowcbf(round_, display_)

% dummy wrapper around generate_MaxFlt.m from
% https://gitlab.com/ska-telescope/ska-low-cbf-firmware/-/blob/main/libraries/signalProcessing/filterbanks/src/matlab/PSTFilterbank.m

h = generate_MaxFlt(256,12);

if (round_ == 1)
  % quantize
  h = round(2^17 * h);
end

h = h' / sum(h);

n_chan = 256;
n_filt = 12 * 256;

% Save impulse response h, and other parameters
fir_filter_path = '../config/Prototype_FIR.lowcbf.mat';
save(fir_filter_path, 'h', 'n_chan', 'n_filt');

if (display_ == 1)
    os = 4/3;
    plot_FIR_filter (n_chan, os, h);
end

end
