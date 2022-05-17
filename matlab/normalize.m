function normalized = normalize(os_factor, n)
  % normalize some number ``n`` by the rational number in ``os_factor``.
  %
  % Example:
  %
  % .. code-block::
  %
  %   >> normalize(struct('nu', 8, 'de', 7), 32);
  %     28
  %
  % Args:
  %   os_factor (struct): rational number struct
  %   n (int): number to be normalized.
  % Returns:
  %   int: normalized ``n``
  
  normalized = (os_factor.de * n) / os_factor.nu;
end
