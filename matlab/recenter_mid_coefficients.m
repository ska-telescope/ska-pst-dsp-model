% load in the mid filter coefficients, recenter them, and then save them
% to an output file
function recenter_mid_coefficients(diagnostic_)
  diagnostic = 0;
  if exist('diagnostic_', 'var')
    diagnostic = diagnostic_;
  end

  % first, get the configuration directory
  file_path = mfilename('fullpath');
  [file_dir, name, ext] = fileparts(file_path);
  [base_dir, name, ext] = fileparts(file_dir);

  config_dir = fullfile(base_dir, 'config');
  mid_coeff_file_path = fullfile(config_dir, 'NRC_100353_MidFilterCoefficients.mat');
  new_mid_coeff_file_path = fullfile(config_dir, 'NRC_%d_MidFilterCoefficients.mat');

  filt_struct = load(mid_coeff_file_path);
  filt = filt_struct.hQ;

  [maxval, argmax] = max(filt);


  h = filt(2:2*argmax-2);
  Nh = length(h);
  Os = filt_struct.Os;

  if diagnostic
    comp_coeff_file_path = fullfile(config_dir, 'Prototype_FIR.8-7.4096.65536.mat');
    comp_struct = load(comp_coeff_file_path);
    figure;
    nchan = 4096;
    subplot(2,1,1)
      [H0,W] = freqz (h, 1, Nh);
      W = W/pi;
      plot (W, abs(H0), 'LineWidth', 1.5);
      axis ([0 3.5*(1/nchan) -0.15 1.15]);

    subplot(2,1,2)
      [H0,W] = freqz (comp_struct.h, 1, Nh);
      W = W/pi;
      plot (W, abs(H0), 'LineWidth', 1.5);
      axis ([0 3.5*(1/nchan) -0.15 1.15]);



    [maxval, argmax] = max(h);
    fprintf('argmax=%d, length(h)=%d length(h)-argmax=%d\n', argmax, length(h), length(h) - argmax);
  else
    new_mid_coeff_file_path = sprintf(new_mid_coeff_file_path, Nh);
    save(new_mid_coeff_file_path, 'h', 'Nh', 'Os');
  end

end
