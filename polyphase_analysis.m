function out=polyphase_analysis(in, filt, block, os_factor)

% Polyphase analysis filterbank with cyclic shift of data into FFT
% to remove spectrum rotation in output data
% @method polyphase_analysis
% @author John Bunton <CSIRO> 2003, 2016
% @author Dean Shaff <dshaff@swin.edu.au; Swinburne University> 2019

% @param {single/double []} in - input data. Should be single dimensional.
% @param {single/double []} filt - prototype lowpass filter
%   (length should be multiple of step)
% @param {single/double []} block - length of fft
%   (prefilter length = length(filt)/block
%   if not the 'filt' is padded with zeros to a multiple of block
%   Importantly, This is also the number of channels that will
%   be created by the PFB.
% @param {struct} os_factor - struct with 'nu' and 'de' fields
% @return {single/double []} - output data: two dimensional array.
%   The first dimension is time, the second frequency. The number of frequency
%   frequency channels is equal to `block`

% step will be the same as block in the critically sampled case.
step = floor((block * os_factor.de) / os_factor.nu);
% Making sure the filter has an integer multiple of block size.
phases=ceil(length(filt)/block);
f=(1:phases*block)*0;
f(1:length(filt))=filt;


nblocks=floor( (length(in)-length(f))/step);
fl=length(f);

fprintf('polyphase_analysis: nblocks: %d\n', nblocks);

%block=block*2;     % Interleaved filterbank
%phases=phases/2;   %produces critically sampled outputs as well as
                    %intermediate frequency outputs

for k=0:nblocks-1
  temp=f.*in(1+step*k:fl+step*k);

  %index for cyclic shift of data to FFT to eliminate spectrum rotation
  index = (step*k - floor(step*k/block)*block);
  temp=circshift(temp',index)';

  temp2=(1:block)*0;
  for m=0:phases-1
    temp2=temp2+temp(1+block*m:block*(m+1));
  end
  out(k+1,1:block)= fft(temp2); %temp2;%
end

end
