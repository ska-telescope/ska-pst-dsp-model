function multiplied = multiply(os_factor, n)
  % multiply some number ``n`` by the rational number in ``os_factor``.
  %
  % Example:
  %
  % .. code-block::
  %
  %   >> multiply(struct('nu', 8, 'de', 7), 28);
  %     32
  %
  % Args:
  %   os_factor (struct): rational number struct
  %   n (int): number to be multiplied.
  % Returns:
  %   int: multiplied ``n``
  
  multiplied = (os_factor.nu * n) / os_factor.de;
end
