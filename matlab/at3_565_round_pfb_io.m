
% see https://docs.google.com/spreadsheets/d/1F01T1KAoSTZOaW33wYVq6EZJk_xuwu3xuV2oohFhBrA/edit?usp=sharing
optimal_8bit_rms = 33.8;
optimal_12bit_rms = 462.6;
optimal_16bit_rms = 3538.5;

% Owing to the 50% duty cycle of the square wave, the on-pulse standard deviation 
% is underestimated when the variance is computed over all samples.
% The on-pulse variance is 2 times larger than the estimate; therefore,
% the data should be scaled by
%   s = rmsInput/onpulse_rms = rmsInput / (estimated_rms * sqrt(2))
% This change is effected by using rmsInput' = rmsInput / sqrt(2)

duty_cycle_correction = 1.0 / sqrt(2.0);
optimal_8bit_rms = optimal_8bit_rms * duty_cycle_correction;
optimal_16bit_rms = optimal_16bit_rms * duty_cycle_correction;
optimal_16bit_rms = optimal_16bit_rms * duty_cycle_correction;

% no rounding
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true);

% rounding input without re-scaling
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rndInput=true);

% scaling for optimal 8-bit rounded input
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rmsInput=optimal_8bit_rms);

% rounding output without re-scaling
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rndOutput=true);

% scaling for optimal 8-bit rounded output
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rmsOutput=optimal_8bit_rms);

% scaling for optimal 12-bit rounded output
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rmsOutput=optimal_12bit_rms);

% scaling for optimal 16-bit rounded output
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rmsOutput=optimal_16bit_rms);

