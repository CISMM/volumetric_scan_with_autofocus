function stop(img_path)
global vid
stoppreview(vid);
stop(vid);
frames = getdata(vid, vid.FramesAcquired);
if vid.FramesAcquired > 0
    imwrite(frames(:,:,1,1), img_path);
end
for i = 2:vid.FramesAcquired
    imwrite(frames(:,:,1,i), img_path, 'WriteMode', 'append');
    fprintf('saving %d/%d frames\n', i, vid.FramesAcquired);
end
fclose('all');
end

