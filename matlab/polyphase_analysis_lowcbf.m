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
dout = PSTFilterbank(in, filt, doRounding);

totalSamples = length(in);
outputSamples = floor(totalSamples/192);

%% initialise
out = zeros(1,256,outputSamples);

%
% In PSTFilterbank.m, data are divided by
%
% /  2^9 on line 21
% / 2048 on line 39
% /  256 by taking a 256 point FFT on line 39?
%
scale = 2^9 * 2048 * 256;
out(1,:,:)=dout*scale;

end
