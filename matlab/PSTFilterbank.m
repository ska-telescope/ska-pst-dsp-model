function [dout] = PSTFilterbank(din, FIRtaps, do_padding)
% Filterbank, FFT 256 points, 12 taps.

%% pre-pad with 1536 zeros to match the first output in the simulation.
% 1536 is half the total FIR length, so the timestamp for the first SPS sample becomes the timestamp for the first filterbank output sample.

nfilt = 3072;
if (do_padding)
    padding = 1536;
else
    padding = 0;
end

totalSamples = length(din) + padding;
outputSamples = floor((totalSamples-nfilt)/192);

dinp = zeros(totalSamples,1);
% fprintf('pre-padding %d\n',padding)
dinp((padding+1):(padding + length(din))) = din;

%% initialise
dout = zeros(216,outputSamples);
fftIn = zeros(256,1);

for outputSample = 1:outputSamples
    % FIR filter, with scaling
    
    for n1 = 1:256
        fftIn(n1) = sum(FIRtaps(n1:256:end) .* dinp((outputSample-1)*192 + (n1:256:(n1+256*11))))/2^9;
    end

    % FFT
    % firmware scaling for a scaling parameter of 0x14 (as configured in the 1st corner turn).
    % firmware scaling is 256 in the FFT, then (for 0x14) 16 after the phase correction.
    dout1 = fftshift(fft(fftIn))/128;

    % Derotate the output (rotation occurs due to oversampling)
    % Rotation is by pi/2, advancing with each frequency bin and time sample.
    % note : DC is at 129; no rotation; Output sample 0 has no rotation.
    % rotation defined here is in units of pi/2
    rotation = mod((outputSample-1) * (-128:127),4);
    dout2 = dout1 .* shiftdim(exp(1i*2*pi*rotation/4));
    
    dout(:,outputSample) = dout2(21:(21 + 215));
end



