function header = add_fir_filter_to_header(header, fir_filter_coeff, os_factors)

  function arr_str = arr2str (arr)
    arr_str = "";
    for i = 1:length(arr)-1
      arr_str = arr_str + sprintf('%0.6E', arr(i)) + ',';
    end
    arr_str = arr_str + sprintf('%0.6E', arr(end));
  end

  if ~strcmp(class(fir_filter_coeff), 'cell')
    fir_filter_coeff = {fir_filter_coeff};
  end

  if ~strcmp(class(os_factors), 'cell')
    os_factors = {os_factors};
  end


  header('NSTAGE') = num2str(length(fir_filter_coeff));

  for n = 1:length(fir_filter_coeff)
    fir = fir_filter_coeff{n};
    os_factor = os_factors{n};
    fir_str = arr2str(fir);
    header(sprintf('COEFF_%d', n-1)) = fir_str;
    header(sprintf('OVERSAMP_%d', n-1)) = sprintf(...
      '%d/%d', os_factor.nu, os_factor.de);
    header(sprintf('NTAP_%d', n-1)) = num2str(length(fir));

  end
end
