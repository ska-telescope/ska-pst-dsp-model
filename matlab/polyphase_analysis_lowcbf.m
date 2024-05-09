function out=polyphase_analysis_lowcbf(...
    in,...
    filt,...
    block,...
    os_factor,...
    verbose_...
  )
  
% dummy wrapper around PSTFilterbank.m from
% https://gitlab.com/ska-telescope/ska-low-cbf-firmware/-/blob/main/libraries/signalProcessing/filterbanks/src/matlab/PSTFilterbank.m
  
in_size = size(in);
n_pol = in_size(1);
n_chan = in_size(2); % This should always be 1.
  
%% 216 = 256 * 27/32 fine channels span critical part of coarse channel

%
% In PSTFilterbank.m, data are divided by
%
% /  2^9 on line 21
% / 2048 on line 39
% /  256 by taking a 256 point FFT on line 39?
%
scale = 2^9 * 2048 * 256;

persistent do_padding

% zero pad only on the first call to this function
if isempty(do_padding)
    do_padding = 1;
else
    do_padding = 0;
end

for i_pol = 1:n_pol
  
    dout = PSTFilterbank(in(i_pol,1,:), filt, do_padding);

    if (i_pol == 1)
        outsz = size(dout);
        ndat = outsz(2);
        out = zeros(n_pol,216,ndat);
    end
    out(i_pol,:,:)=dout*scale;

end

end