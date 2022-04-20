
% Analysis for AT3-152

% 'low' filter by John, Ian, and Dean
% plot: products/FIR_filter_response.3072.png
design_PFB_FIR_filter(256, struct('nu', 4, 'de', 3), 12*256, 1);

% new 'low' filter by John
% plot: products/alt_FIR_filter_response.3072.png
design_PFB_FIR_filter_alt(256, struct('nu', 4, 'de', 3), 12, 1);

% mid filter by Thushara
% plot: products/two_stage_filter_response.100352.png
design_PFB_FIR_filter_two_stage(4096, struct('nu', 8, 'de', 7), 28, 32, 1);

%% 

for test = [ "low" "low_psi" "low_alt" "low_psi_alt" "mid" ]
    
    current_performance(10, test, 'time');
    current_performance(10, test, 'freq');
    
end

%% 

for test = [ "low" "low_psi" "low_alt" "low_psi_alt" "mid" ]
    
    square_wave(test);
    
end