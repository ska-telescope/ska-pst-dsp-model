function name = get_function_name(func)
  % given some function handle, get its name.
  %
  % Example:
  %
  % .. code-block::
  %
  %   >> win = PFBWindow;
  %   >> func2str(@win.hann_factory)
  %     '@(varargin)win.hann_factory(varargin{:})'
  %   >> get_function_name(@win.hann_factory)
  %     'hann_factory'
  %
  % Args:
  %   func (handle): Some function
  % Returns:
  %   string: name of function
  
  func_str = func2str(func);
  func_str_split = strsplit(func_str, '/');
  func_str = func_str_split{end};
  func_str_split = strsplit(func_str, '.');
  func_str = func_str_split{end};
  name = strrep(func_str, '(varargin{:})', '');
end
