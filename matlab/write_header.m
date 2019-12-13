function write_header(file_id, hdr_map)
  % write DADA header information to a file
  %
  % Args:
  %   file_id (double): file id number generated by `fopen`
  %   hdr_map (containers.Map): map object with header information

  function hdr_str = get_hdr_str (header)
    % fprintf('get_hdr_str\n');
    hdr_str = "";
    hdr_size = str2num(header('HDR_SIZE'));
    hdr_str = strcat(hdr_str, sprintf('HDR_SIZE %s', header('HDR_SIZE')));
    hdr_str = hdr_str + newline;
    for k=keys(header)
      if strcmp(k, 'HDR_SIZE')
        continue;
      end
      key_val = sprintf('%s %s', k{1}, header(k{1}));
      hdr_str = strcat(hdr_str, key_val);
      hdr_str = hdr_str + newline;
    end
    new_hdr_size = length(char(hdr_str));
    if new_hdr_size > hdr_size
      header('HDR_SIZE') = num2str(hdr_size*2);
      hdr_str = get_hdr_str(header);
    end
  end

  hdr_str = get_hdr_str (hdr_map);

  hdr_size = str2num(hdr_map('HDR_SIZE'));
  hdr_char = char(hdr_str);
  n_remaining = hdr_size - length(hdr_char);
  hdr_remaining = char('0' * zeros(n_remaining, 1));

  % file_id = out_filename_or_id;
  % if isstring(out_filename_or_id) || ischar(out_filename_or_id)
  %   file_id = fopen(out_filename_or_id, 'w');
  % end
  fwrite(file_id, hdr_char, 'char');
  fwrite(file_id, hdr_remaining, 'char');
  % fclose(file_id);
end
