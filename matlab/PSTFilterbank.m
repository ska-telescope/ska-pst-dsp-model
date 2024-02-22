function [dout] = PSTFilterbank(din, FIRtaps, doRounding)
% Filterbank, FFT 256 points, 12 taps.

% WvS AT3-150: filter now generated in design_PFB_FIR_filter_lowcbf.m
% FIRtaps = round(2^17 * generate_MaxFlt(256,12));

%% Pad with 11*256 + 64 = 2880 zeros to match the first output in the simulation.
totalSamples = length(din);
outputSamples = floor(totalSamples/192);
dinp = zeros(totalSamples+2880,1);
dinp(2881:end) = din;

if isreal(dinp)
    error ('PSTFilterbank real-valued dinp');
end

%% initialise
dout = zeros(256,outputSamples);
fftIn = zeros(256,1);

%% 
doRounding = 1;
doScale = 1;

scale_before_rounding = 1.0;
% see https://docs.google.com/spreadsheets/d/1F01T1KAoSTZOaW33wYVq6EZJk_xuwu3xuV2oohFhBrA/edit?usp=sharing
optimal_8bit_rms = 33.8;

if doRounding
    if doScale
        stddev = sqrt(var(din,0,"all"));
        % fprintf ("din rms=%e \n", stddev);
        scale_before_rounding = optimal_8bit_rms / stddev;
    end
    dinp = complex(round(scale_before_rounding * dinp));
end

for outputSample = 1:outputSamples
    % FIR filter, with scaling
    
    for n1 = 1:256
        fftIn(n1) = sum(FIRtaps(n1:256:3072) .* dinp((outputSample-1)*192 + (n1:256:(n1+256*11))))/2^9;

%        if (doRounding)
%            fftIn(n1) = round(scale_before_rounding * fftIn(n1));
%        end
    end

    fftIn = complex(fftIn);

    % fprintf ("fftIn rms=%e \n", sqrt(var(fftIn,0,"all")));

    % FFT
    % firmware scaling for a scaling parameter of 0x14 (as configured in the 1st corner turn).
    % firmware scaling is 256 in the FFT, then (for 0x14) 16 after the phase correction.
    dout1 = fftshift(fft(fftIn))/4096;

    % Derotate the output (rotation occurs due to oversampling)
    % Rotation is by pi/2, advancing with each frequency bin and time sample.
    % note : DC is at 129; no rotation; Output sample 0 has no rotation.
    % rotation defined here is in units of pi/2
    rotation = mod((outputSample-1) * (-128:127),4);
    dout2 = dout1 .* shiftdim(exp(1i*2*pi*rotation/4)); 
    
    dout(:,outputSample) = fftshift(dout2);
end

if (doRounding)
    if (doScale)
        stddev = sqrt(var(dout,0,"all"));
        scale_before_rounding = optimal_8bit_rms / stddev;
    end
    dout = complex(round(scale_before_rounding * dout));
end

% fprintf ("dout rms=%f \n", sqrt(var(dout,0,"all")));

if isreal(dout)
    error ('PSTFilterbank real-valued dout');
end


