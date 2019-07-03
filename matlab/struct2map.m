function map = struct2map(s)
  map = containers.Map();

  fields = fieldnames(s);

  for i=1:numel(fields)
    map(fields{i}) = s.(fields{i});
  end
end
