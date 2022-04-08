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

totalSamples = length(in)
outputSamples = floor(totalSamples/192);

%% initialise
out = zeros(1,216,outputSamples);

scale=192*192;
out(1,:,:)=dout*scale*scale;

size(out)
end
