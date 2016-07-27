function SCRTempTest()

% Experiment name
ExpName = 'SCRTempSensor';

% Create automation handle
CtrDeskHandle = ControlDeskAuto(ExpName);

% Change temperature value
% vars = CtrDeskHandle.getVariables();
% save('vars', 'vars');
CtrDeskHandle.calibrate('Model Root/InletTemp/Value', 350);

end