function [fb_data] = load_fb_tb_data(fname, total_frames, total_vc)
% Load filterbank output data from the simulation

% Load the filterbank output data saved by the VHDL testbench
% Example data :
% 7 0000009B 0000 0001 0002 F7 F8 0A 0C FE F9 02 FD FC FB 0B FB
% 0 0000009B 0000 0001 0002 FF 01 05 FD 01 01 01 02 06 02 0A FD
% ... etc. Note 216 lines between the 7 in the first column which signifies the start of the packet
% (one packet = 216 fine channels for a single time sample and 3 virtual channels)

% Arguments:
%   Number of frames to load (specific to the data file):
%     total_frames = 4;
%   Number of virtual channels to load (specific to the data file):
%     total_vc = 3;
%   Input file name:
%     fname = 'test4_fb_out.txt'
%

% Load the source data from a file
fid = fopen(fname);
[a,cnt] = fscanf(fid,'%x %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x');
fclose(fid);

b = reshape(a,17,floor(cnt/17));

first_frame_set = 0;
b_int = zeros(12,1);
% (216 fine channels) * (time samples) * (2 pol) * (virtual channels)
fb_data = zeros(216,288*total_frames,2,total_vc);
total_timesamples = zeros(total_frames,total_vc);

for c1 = 1:(total_frames * 216 * 288 * floor(total_vc/3))
    % Each frame is 288 packets of 216 fine channels, with 3 virtual channels on each line.
    sop = b(1,c1);  % start of packet
    this_frame = b(2,c1);  % absolute frame (relative to SKA epoch)
    vc0 = b(3,c1);   % virtual channel 0
    vc1 = b(4,c1);   % virtual channel 1
    vc2 = b(5,c1);   % virtual channel 2
    if ~first_frame_set
        first_frame = this_frame;
        frame = 0;
        first_frame_set = 1;
    else
        frame = this_frame - first_frame;
    end
    if sop > 0
        fine_frequency = 0;
        %disp([frame vc0]);
        time_sample = total_timesamples(frame+1,vc0+1);
        total_timesamples(frame+1,vc0+1) = total_timesamples(frame+1,vc0+1) + 1;
    else
        fine_frequency = fine_frequency + 1;
    end
    % convert the values to signed integers
    for c2 = 1:12
        if b(c2 + 5,c1) > 127
            b_int(c2) = b(c2+5,c1) - 256;
        else
            b_int(c2) = b(c2+5,c1);
        end
    end
    fb_data(fine_frequency+1,frame*288 + time_sample+1,1,vc0+1) = b_int(1) + 1i * b_int(2);
    fb_data(fine_frequency+1,frame*288 + time_sample+1,2,vc0+1) = b_int(3) + 1i * b_int(4);
    fb_data(fine_frequency+1,frame*288 + time_sample+1,1,vc1+1) = b_int(5) + 1i * b_int(6);
    fb_data(fine_frequency+1,frame*288 + time_sample+1,2,vc1+1) = b_int(7) + 1i * b_int(8);
    fb_data(fine_frequency+1,frame*288 + time_sample+1,1,vc2+1) = b_int(9) + 1i * b_int(10);
    fb_data(fine_frequency+1,frame*288 + time_sample+1,2,vc2+1) = b_int(11) + 1i * b_int(12);
    
end


