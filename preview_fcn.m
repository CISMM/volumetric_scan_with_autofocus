function preview_fcn(obj,event,himage)
%im = imagesc(event.Data);
%foo = double(event.Data);

% fprintf('Min: %f, Max: %f, Range: %f, Mean: %f\n', min(foo(:)), max(foo(:)), range(foo(:)), mean(foo(:)));
% foo = 65535 * (foo ./ max(foo(:)));
% foo = uint16(foo);
% fprintf('Min: %u, Max: %u, Range: %u, Mean: %f\n', min(foo(:)), max(foo(:)), range(foo(:)), mean(foo(:)));
% 
%figure(40303); image(foo); colormap(gray(65535));
%figure(40303); image(foo); colormap(gray(65535));

himage.CData = imadjust(imresize(event.Data,[512, 512]));
%himage.CDataMapping = 'scaled';
%himage.CData = imagesc(imresize(event.Data,[500 500])).CData;
%imaqmontage(vid);

%himage.CData = imadjust(imresize(event.Data,[500 500]));
%himage.CData = imresize(contrast(event.Data), [500 500]);
%himage.CData = imresize(event.Data + 50, [500 500]);
% Display image data.
%himage.CData = event.Data;
end

