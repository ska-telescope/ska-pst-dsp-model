function out=polyphase_analysis_lowcbf(...
    in,...
    filt,...
    block,...
    os_factor,...
    verbose_...
  )
  
% dummy wrapper around PSTFilterbank.m from
% https://gitlab.com/ska-telescope/ska-low-cbf-firmware/-/blob/main/libraries/signalProcessing/filterbanks/src/matlab/PSTFilterbank.m

doRounding = 0;
  
in_size = size(in);
n_pol = in_size(1);
n_chan = in_size(2); % This should always be 1.
n_dat = in_size(3);

outputSamples = floor(n_dat/192);
  
%% initialise
out = zeros(n_pol,256,outputSamples);

%
% In PSTFilterbank.m, data are divided by
%
% /  2^9 on line 21
% / 2048 on line 39
% /  256 by taking a 256 point FFT on line 39?
%
scale = 2^9 * 2048 * 256;

for i_pol = 1:n_pol
  
    dout = PSTFilterbank(in(i_pol,1,:), filt, doRounding);
    out(i_pol,:,:)=dout*scale;

end

end