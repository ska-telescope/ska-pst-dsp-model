function same = compare_dump_files(file_path1, file_path2)
  % Determine if two dump files contain the same data.
  % Example:
  %
  % .. code-block::
  %
  %   >> compare_dump_files('path/to/dump1', '/path/to/dump2')
  %   ans =
  %
  %     logical
  %
  %      1
  %
  % Args:
  %   file_path1 (string): The path to first dump file
  %   file_path2 (string): The path to second dump file
  % Returns:
  %   bool: true if the dump files contain the same data, false otherwise

  file_paths = {file_path1, file_path2};
  data = {};
  headers = {};
  sizes = zeros(length(file_paths), 1);

  for i=1:length(file_paths)
    file_path = file_paths{i};
    file_id = fopen(file_path);
    data_header = read_dada_file(file_id);
    fclose(file_id);
    data{i} = data_header{1};
    data{i} = data{i} ./ max(data{i}(:))
    headers{i} = data_header{2};
    size_data = size(data{i});
    sizes(i) = size_data(3);
  end

  for i=1:length(file_paths)
    data{i} = data{i}(:,:,1:min(sizes));
  end

  ax = subplot(311);
  plot(squeeze(real(data{1}(1, 1, :))));
  grid(ax, 'on')

  ax = subplot(312);
  plot(squeeze(real(data{2}(1, 1, :))));
  grid(ax, 'on')

  diff = abs(data{2} - data{1});
  ax = subplot(313);
  plot(reshape(diff, numel(diff), 1));
  grid(ax, 'on')

  sum(diff(:))
  saveas(gcf, 'products/compare_dump_files.png');


end
