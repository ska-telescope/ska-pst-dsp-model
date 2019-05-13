function name = get_function_name (func)
  func_str = func2str(func);
  func_str_split = strsplit(func_str, '/');
  func_str = func_str_split{end};
  func_str_split = strsplit(func_str, '.');
  func_str = func_str_split{end};
  name = strrep(func_str, '(varargin{:})', '');
end
