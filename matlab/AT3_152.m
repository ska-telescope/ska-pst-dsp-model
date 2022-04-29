
% Analysis for AT3-152

% 'low' filter by John, Ian, and Dean
% plot: products/FIR_filter_response.3072.png
design_PFB_FIR_filter(256, struct('nu', 4, 'de', 3), 12*256, 1);

% new 'low' filter by John
% plot: products/alt_FIR_filter_response.3072.png
design_PFB_FIR_filter_alt(256, struct('nu', 4, 'de', 3), 12, 1);

% 'mid' filter by Thushara
% plot: products/two_stage_filter_response.100352.png
design_PFB_FIR_filter_two_stage(4096, struct('nu', 8, 'de', 7), 28, 32, 1);

tests = [ "low" "low_psi" "low_alt" "low_psi_alt" "mid" ];

%% run the tone and delta function tests

for test = tests
    
    current_performance(10, test, 'time');
    current_performance(10, test, 'freq');
    
end

%% generate DADA files containing square-wave amplitude modulated noise 
% passed through the specified analysis filter bank configuration

for test = tests
    
    square_wave(test);
    
end

%% generate DADA files containing square-wave amplitude modulated noise
% passed through the specified analysis filter bank configuration
% and then inverted using the InverseFilterbank

for test = tests
    
    fprintf ('Producing inverted square waves after %s filter bank \n', test);
    square_wave(test,1);
    
end