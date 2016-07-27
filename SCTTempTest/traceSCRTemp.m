function traceSCRTemp(data, state)
    
    % Unpack data
    init  = data.SCRTemp.Init ;
    final = data.SCRTemp.Final;
    rate  = data.SCRTemp.Rate ;
    name  = data.ExpName      ;

    % Create automation handle
    CtrDeskHandle = ControlDeskAuto(name);

    % Trace temperature value
    for T = init:rate:final
        CtrDeskHandle.calibrate('Model Root/InletTemp/Value', T);
        %disp(T);
        pause(1);
    end
end