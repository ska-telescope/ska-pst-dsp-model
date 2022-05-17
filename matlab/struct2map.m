function map = struct2map(s)
  % convert a struct to a containers.Map object
  % 
  % Args:
  %   s (struct): a struct
  % Returns:
  %   containers.Map: containers.Map object with keys and values from input struct.

  map = containers.Map();

  fields = fieldnames(s);

  for i=1:numel(fields)
    map(fields{i}) = s.(fields{i});
  end
end
