function fig = tight_layout(fig)
  allAxesInFigure = findall(fig,'type','axes');
  factory_font_size = get(groot, 'factoryAxesFontSize');
  for idx=1:length(allAxesInFigure)
    ax = allAxesInFigure(idx);
    font_size = get(ax, 'FontSize');
    font_size_ratio = font_size / factory_font_size;
    pos = ax.Position;

    % font_size_ratio = 1.0;
    % outerpos = ax.OuterPosition;
    % ti = ax.TightInset;
    % left = outerpos(1); % + ti(1);
    % bottom = outerpos(2); % + ti(2);
    % ax_width = outerpos(3) / font_size_ratio;
    % ax_height = outerpos(4) / font_size_ratio;
    % ax_width = outerpos(3) - font_size_ratio*(ti(1) + ti(3));
    % ax_height = outerpos(4) - font_size_ratio*(ti(2) + ti(4));
    % ax.Position = [left bottom ax_width ax_height];
  end
end
