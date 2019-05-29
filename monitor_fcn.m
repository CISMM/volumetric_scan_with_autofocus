function monitor_fcn(obj, event, vi, vi_label, desired_ind, total_ind)
javaaddpath('./AutoPilot-1.0.jar');
import autopilot.interfaces.*;
  
persistent mode pre_qua base_qua qua_percent_threshold probe_arr probe_qua ...
           cur_offset base_offset optimize_cnt step seen pre_seen;

if isempty(base_qua)
    mode = CallBackMode.Monitor;
    pre_qua = 0;
    qua_percent_threshold = 0.95;
    probe_arr = [0.02, -0.02];
    probe_qua = [];
    cur_offset = 0;
    base_offset = cur_offset;
    optimize_cnt = 0;
    step = probe_arr(1);
    seen = 0;
end

chunk = peekdata(obj,99999);
chunk_size = size(chunk, 4);
pre_seen = seen;
seen = seen + chunk_size;

ind = floor(seen/total_ind) * total_ind + desired_ind;
if ind > seen
    ind = ind - total_ind;
end
%fprintf('pre_seen:%d chunk_size:%d ind:%d', pre_seen, chunk_size, ind);
ind = ind - pre_seen;
if ind <= 0
    return
end

sample_frame = chunk(:,:,:,ind);
cur_qua = AutoPilotM.dcts2(sample_frame,3);
if isempty(base_qua)
    base_qua = cur_qua;
    imwrite(sample_frame,'monitor.tif');
else
    imwrite(sample_frame,'monitor.tif','WriteMode','append');
end

%fprintf("cur_qua:%f ETL3:%f base_qua:%f\n", cur_qua, cur_offset, base_qua);
fprintf("%f %f\n", cur_offset, cur_qua);

switch mode
    case CallBackMode.Monitor
        if (cur_qua/base_qua) < qua_percent_threshold
            cur_offset = cur_offset + probe_arr(1);
            vi.SetControlValue(vi_label, cur_offset);
            mode = CallBackMode.Probe;
        end
    % Find out the correct direction to go that would improve image quality.
    % Once the algorithm finds it, 'step' will be set to the correct offset,
    % and voltage will be set to base_offset + step, and swtich to
    % 'Optimize'.
    case CallBackMode.Probe
        if cur_qua > pre_qua
            step = probe_arr(size(probe_qua, 2) + 1);
            probe_qua = [];
            mode = CallBackMode.Optimize;
            %fprintf('Found probe step: %f\n', step);
        else
            fprintf('Try the other probe\n');
            probe_qua = [probe_qua, cur_qua];
            probe_size = size(probe_qua, 2);
            %fprintf('probe size: %d\n', probe_size);
            %if probe_size < size(probe_arr, 2)
            if probe_size < 2
                cur_offset = base_offset+probe_arr(probe_size+1);
                vi.SetControlValue(vi_label, cur_offset);
            else
                %fprintf('Cannot find direction to improve\n');
                cur_offset = base_offset;
                vi.SetControlValue(vi_label, cur_offset);
                probe_qua = [];
                mode = CallBackMode.Monitor;
                return
            end
        end
    % At this point we know 'step' is the correct offset to add on, so we 
    % keep adding 'step' to current voltage, until image quality drops.
    % If that happens, we back off step/2 in distance.
    case CallBackMode.Optimize
        if optimize_cnt == 0
            %fprintf('Entering Optimize mode\n');
            cur_offset = cur_offset + step;
            vi.SetControlValue(vi_label, cur_offset);
        else
            if cur_qua > pre_qua
                cur_offset = cur_offset + step;
                vi.SetControlValue(vi_label, cur_offset);
                %fprintf('keep optimize to:%f\n', cur_offset);
            elseif cur_qua <= pre_qua
                step = -step / 4;
                cur_offset = cur_offset + step;
                vi.SetControlValue(vi_label, cur_offset);
                mode = CallBackMode.FineOptimize;
                %fprintf('See quality drop. Entering Fine tune mode...\n');
            % if new ETL causes image quality to be the same as previous
            % one, we step down half of the change, and done.
            else
                cur_offset = cur_offset - (step / 2);
                vi.SetControlValue(vi_label, cur_offset);
                optimize_cnt = -1;
                base_offset = cur_ofset;
                mode = CallBackMode.Monitor;
            end
        end
        optimize_cnt = optimize_cnt + 1;
    case CallBackMode.FineOptimize    
        if cur_qua < pre_qua
            cur_offset = cur_offset - step;
            vi.SetControlValue(vi_label, cur_offset);
            optimize_cnt = 0;
            base_offset = cur_offset;
            mode = CallBackMode.Monitor;
            %fprintf('Fine tune is done at ETL3: %f\n', cur_offset);
            base_qua = pre_qua;
        else
            cur_offset = cur_offset + step;
            vi.SetControlValue(vi_label, cur_offset);
            %fprintf('Fine tuning ETL3 to %f', cur_offset);
        end
    otherwise
        warning('Unexpected state in refocus()');    
end
pre_qua = cur_qua;
end

