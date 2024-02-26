
% see https://docs.google.com/spreadsheets/d/1F01T1KAoSTZOaW33wYVq6EZJk_xuwu3xuV2oohFhBrA/edit?usp=sharing
optimal_8bit_rms = 33.8;
optimal_16bit_rms = 3538.5;

% just rounding input
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rndInput=true);

% scaling for optimal 8-bit rounded input
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rmsInput=optimal_8bit_rms);

% just rounding output
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rndOutput=true);

% scaling for optimal 16-bit rounded output
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rmsOutput=optimal_16bit_rms);

% scaling for optimal 8-bit rounded input, and scaling for optimal 16-bit rounded output
sgcht (signal='square_wave', cfg='sps', cfg2='lowpsi', critical=true, rmsInput=optimal_8bit_rms, rmsOutput=optimal_16bit_rms);
