function  start()
clear p_controller_fcn;
x0 = 872;
y0 = 1124;
width = 164;
height = 160;
desired_frame = 3;
volume_frames = 5;
actual_check = volume_frames * 2;
global vid
delete(imaqfind);
root_dir = 'C:\Users\phsiao\Desktop\MATLAB\self_focus_template';
vi_path = 'single_color_3D_continuous_scan_with_delay_and_ETL_control.vi';
etl3_label = 'ETL3 (v)';

% connect to labview executable via activex
e = actxserver('volumetricScan.Application');
vi = invoke(e, 'GetVIREference', fullfile(root_dir, vi_path));
    
imaqmex('feature', '-previewFullBitDepth', true);
vid = videoinput('hamamatsu', 1, 'MONO16_2048x2048_FastMode');
src = getselectedsource(vid);
vid.ROIPosition = [x0 y0 width height];
vid.FramesPerTrigger = 1;
src.DefectCorrect = 'on';
src.TriggerActive = 'level';
src.TriggerPolarity = 'positive';
src.TriggerSource = 'external';
src.TriggerConnector = 'bnc';
vid.TriggerRepeat = Inf;
triggerconfig(vid, 'hardware', 'DeviceSpecific', 'DeviceSpecific');

vid.FramesAcquiredFcnCount = volume_frames;
vid.FramesAcquiredFcn = {'p_controller_fcn', vi, etl3_label, desired_frame, actual_check};

hImage = image( zeros(512, 512, vid.NumberOfBands) );
setappdata(hImage,'UpdatePreviewWindowFcn',@preview_fcn);

h = preview(vid, hImage);
a = ancestor(h,'axes');
set(h,'CDataMapping','scaled');
set(a,'Clim',[0 2^16]);
start(vid);
warning('off', 'imaq:peekdata:tooManyFramesRequested');
% w = warning('query','last')
% id = w.identifier;
% warning('off',id)

end

