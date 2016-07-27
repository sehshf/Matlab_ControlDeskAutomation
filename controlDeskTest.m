function controlDeskTest()

clc;

eval('DsMCD3_Const');

global System;
System = [];

global LogicalLink;
LogicalLink = [];

CR = char(10);

DSError = Initialize();

if(DSError.ErrorCode)
    disp(['Error during initialize of DsMC3_CalibrationDemo:', CR, DSError.ErrorString]);
    Uninitialize();
    return;
end;

disp('Initialization of HIL test succeeded');

DSError = CalibrateScalarCharacteristic('scr_can_stEngOn_O_new', 1);

if(DSError.ErrorCode)
    fprintf('Error occured during calibration of scalar characteristic (details: %s)\n', DSError.ErrorString);
end;

Uninitialize();

disp([CR, '========================================================================']);
disp('HIL test finished');

