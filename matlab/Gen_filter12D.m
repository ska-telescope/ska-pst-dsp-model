pl=2;  %to enable plottint pl=1
%c=fircls1(191,1/15.115,.001,.0015);  %-3dB bandedge stopband edge 0.666
%c=fircls1(191,1/15.96,.001,.0002);   %-6dB bandedge stopband edge 0.666
c=fircls1(191,1/12.2, .002,.0002);    %flat to bandedge stopband at 0.8333

% 192 = 16 * 12

if (pl==1)

    figure(3)
    fcl=fft([c c*0 c*0 c*0]);
    
    plot((0:47)/48,db(fcl(1:48)))
    hold on
    xline(.5); 
    xline(0.6666);
    xline(.8333); 
   
    ylabel ('Magnitude (dB)','FontSize',14)
    title ('Frequency response','FontSize',14)
    hold off

end

cl=interpft(c,12*256);

if (pl==2)
    
  plot_FIR_filter (256, 4/3, cl);

end
