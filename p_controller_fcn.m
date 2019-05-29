function p_controller_fcn(obj, event, vi, vi_label, local_ind, check_interval)
    javaaddpath('./AutoPilot-1.0.jar');
    import autopilot.interfaces.*;
    
    % quality fluctuates within this range are cosideredd good.
    qua_fluctuation = 0.005;  
    base_gain = 8;
    
    persistent base_qua prev_qua cur_qua cur_offset gain mode ...
               pre_seen seen file_id change_dir_cnt
           
    if isempty(base_qua)
        gain = base_gain;
        mode = CallBackMode.Monitor;
        seen = 0;
        cur_offset = 0;
        change_dir_cnt = 0;
    end
    
    %% Determin which frame index to peek
%     chunk = peekdata(obj, 99999);
%     chunk_size = size(chunk, 4);
%     pre_seen = seen;
%     seen = seen + chunk_size;
% 
%     ind = floor(seen/check_interval) * check_interval + local_ind;
%     if ind > seen
%         ind = ind - check_interval;
%     end
%     fprintf('index:%d\n', ind);
%     ind = ind - pre_seen;
%     fprintf('pre_seen:%d  chunk:%d  ind:%d\n', pre_seen, chunk_size, ind);
%     fprintf('framesAvailable:%d\n', obj.framesAvailable);
%     if ind <= 0
%         return
%     end
      chunk = peekdata(obj, 99999);
      chunk_size = size(chunk, 4);
      pre_seen = seen;
      seen = seen + chunk_size;

      % Grab the latest appropriate frame
      ind = floor((seen-1)/check_interval) * check_interval + local_ind;
      if ind > seen
          return
      end
      fprintf('index:%d\n', ind);
      ind = ind - pre_seen;
      %fprintf('pre_seen:%d  chunk:%d  ind:%d\n', pre_seen, chunk_size, ind);
      %fprintf('framesAvailable:%d\n', obj.framesAvailable);
      
      % Arbitrary stop at last frame might make ind negative
      if ind <= 0
          return
      end
    
    
    %% Peek the frame and save it.
    sample_frame = chunk(:,:,:,ind);
    cur_qua = AutoPilotM.dcts2(sample_frame,3);
    
    if isempty(base_qua)
        base_qua = cur_qua;
        imwrite(sample_frame,'monitor.tif');
        file_id = fopen('offsets_qualities.csv','w');
    else
        imwrite(sample_frame,'monitor.tif','WriteMode','append');
        fprintf(file_id,'%f,%f\n', cur_offset, cur_qua);
    end
    fprintf('Offset:%f  Quality:%f Base_Qua:%f\n', cur_offset, cur_qua, base_qua);
    %% Monitor image quality and perform autofocus
    switch mode
        case CallBackMode.Monitor
            if (cur_qua/base_qua) < (1 - qua_fluctuation)
                cur_offset = cur_offset + gain * (base_qua - cur_qua);
                mode = CallBackMode.ProbeDirection;
                fprintf('Found out of focus\n');
            end
        case CallBackMode.ProbeDirection
            fprintf('In ProbeDirection\n');
            if cur_qua >= base_qua * (1 - qua_fluctuation)
                fprintf('pre probe works, go back to monitor\n');
                back_to_monitor();
            end
            if cur_qua < prev_qua
                fprintf('Probe went wrong\n');
                gain = gain * -1;
            else
                fprintf('Keep probing\n');
            end
            cur_offset = cur_offset + gain * (base_qua - cur_qua);
            mode = CallBackMode.PController;   
        case CallBackMode.PController
            
            %fprintf('In PController\n');
            if cur_qua >= base_qua * (1 - qua_fluctuation)
                back_to_monitor();
            elseif cur_qua > prev_qua
                fprintf('Keep going\n');
                cur_offset = cur_offset + gain * (base_qua - cur_qua);
            elseif cur_qua < prev_qua
                fprintf('Change dir\n');
                change_dir_cnt = change_dir_cnt + 1;
                if change_dir_cnt > 1
                    gain = gain * 0.5;
                    change_dir_cnt = 0;
                end
                gain = gain * -1;
                cur_offset = cur_offset + gain * (base_qua - cur_qua);
            else
                gain = gain * -0.5;
                cur_offset = cur_offset + gain * (base_qua - cur_qua);
            end
        otherwise
            warning('Unexpected state in p_controller()');
    end
    vi.SetControlValue(vi_label, cur_offset);
    prev_qua = cur_qua;
    
    function back_to_monitor
        gain = base_gain;
        base_qua = cur_qua;
        change_dir_cnt = 0;
        mode = CallBackMode.Monitor;
    end

end

