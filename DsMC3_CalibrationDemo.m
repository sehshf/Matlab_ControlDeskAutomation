 function DsMC3_CalibrationDemo()
% DsMC3_CalibrationDemo: 
% This script shows how to read and write characteristics of the type scalar, curve and map 
% with the asammc3 server over MATLAB. 
% The function "CalibrateOverAllCharacteristics" iterates through all characteristics available
% in the project and reads and writes their values. 
% The characteristic's value written in this demo is a random value between lower and upper limit. 
%
% INPUT ARGUMENTS
% 
% OUTPUT ARGUMENTS
% 
% REMARKS
%
% EXAMPLES
%   MeasurementDemo

% HINTS
%	Only characteristics of the type eCT_CURVE, eCT_MAP and eCT_VALUE are currently supported.
% 
% LOCAL FUNCTIONS
%   [DSError] = Initialize()
%   [DSError] = CalibrateOverAllCharacteristics()
%   Uninitialize()
%   [DSError] = CalibrateScalarCharacteristic(Characteristic)
%   [DSError] = CalibrateMapCharacteristic(Characteristic)
%   [DSError] = CalibrateCurveCharacteristic(Characteristic)
%   [DSError] = CalibrateScalarCharacteristicECU(Characteristic)
%   [DSError] = CalibrateMapCharacteristicECU(Characteristic)
%   [DSError] = CalibrateCurveCharacteristicECU(Characteristic)
%   [DSError, NewValue] = CreateRandom2DimCellArray(SizeOfValue, LowerLimit, UpperLimit)
%   [Result, Description] = Compare2DimDoubleCellArray(CellArray1, CellArray2, Tolerance)   
%   [Result, Description] = Compare3DimDoubleCellArray(CellArray1, CellArray2, Tolerance)
%
% Copyright (c) 2004 by dSPACE GmbH, GERMANY

% $Source: DsMC3_CalibrationDemo.m $ $Revision: 1.12 $ $Date: 2010/03/24 11:01:20MEZ $

% clear screen
clc;

disp('Start DsMC3_CalibrationDemo');
disp('========================================================================');

% check required MATLAB version
RequiredMLVersion = [6,5,1];
Success = CheckMLVersionStruct(RequiredMLVersion);
if(~Success)
    disp(sprintf('To calibrate values with the asammc3 server at least MATLAB 6.5.1 (R13 SP1) is required. Installed version is: %s', version));
    return;
end;

% define MCD3 constants
global constants
eval('DsMCD3_Const');

global System;
System = [];

global LogicalLink;
LogicalLink = [];

CR = char(10);

DSError = Initialize;

if(DSError.ErrorCode)
    disp(['Error during initialize of DsMC3_CalibrationDemo:', CR, DSError.ErrorString]);
    Uninitialize;
    return;
end;

disp('Initialize of DsMC3_CalibrationDemo suceeded');

DSError = CalibrateOverAllCharacteristics;
if(DSError.ErrorCode)
    disp(['Error during CalibrateOverAllCharacteristics of DsMC3_CalibrationDemo:', CR, DSError.ErrorString]);
    Uninitialize;
    return;
end;

Uninitialize;

disp([char(10), '========================================================================']);
disp('Finished DsMC3_CalibrationDemo');

% END OF function DsMC3_CalibrationDemo()
% ===================================================================================================================


function [DSError] = Initialize()

global System;
global LogicalLink;

global CR;

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

try
    disp('Creating a COM Automation server for ControlDeskNG');
    System = actxserver('ControlDeskNG.MC3System', '127.0.0.1');
    if(isempty(System))
        DSError.ErrorCode   = 1;
        DSError.ErrorString = 'Cannot get COM object from ''ControlDeskNG.MC3System''';
        return;
    end;
    
    pause(0.1);
    
    % get name of the available projects
    DbProjectDescriptions = System.DbProjectDescriptions;
    NumProjects = double(DbProjectDescriptions.count);
    if(NumProjects < 1)
        DSError.ErrorCode   = 1;
        DSError.ErrorString = 'Cannot get Project from ControlDeskNG';
        return;
    end;
    
    disp([CR, 'Available projects:', CR]);
    
    for CountProjects = 0 : (NumProjects - 1)
        ActDbProjectDescription = DbProjectDescriptions.GetItemByIndex(CountProjects);
        ActProjectName = ActDbProjectDescription.ShortName;
        disp(sprintf('\t%d. - %s', CountProjects + 1, ActProjectName));
    end;
    
    ChosenProject = 0;
    disp(CR);
    while(ChosenProject < 1 | ChosenProject > NumProjects)
        UserInput = input('Please choose a project by number: ');
        if(isnumeric(UserInput))
            ChosenProject = UserInput;
        else
            UserInput = 0;
        end;
    end;
    
    % select chosen project
    DbProjectDescription = DbProjectDescriptions.GetItemByIndex(UserInput - 1);
    ProjectName = DbProjectDescription.ShortName;
    Project = System.SelectProjectByName(ProjectName);
    if(isempty(Project))
        DSError.ErrorCode   = 1;
        DSError.ErrorString = sprintf('Cannot select project ''%s'' in ControlDeskNG', ProjectName);
        return;
    else
        disp([CR, 'Project ''', ProjectName, ''' was selected!', CR]);
    end;

    DbLocation = System.ActiveProject.DbProject.DbModuleLocations.GetItemByIndex(0);
    VehicleInformation = System.ActiveProject.DbProject.DbVehicleInformations.GetItemByIndex(0);

    UsedDbLogicalLink = VehicleInformation.DbLogicalLinks.GetItemByIndex(0); 
    UsedDbBinary = UsedDbLogicalLink.DbLocation.DbBinaries.GetItemByIndex(0);

    % create runtime logical link
    LogicalLink = System.ActiveProject.LogicalLinks.AddByNames(UsedDbLogicalLink.ShortName, UsedDbBinary.ShortName);
    
    % Activate work page, otherwise calibration will be denied:
    LogicalLink.MemoryPage = 1;
    if(isempty(LogicalLink))
        DSError.ErrorCode   = 1;
        DSError.ErrorString = 'Cannot get ''LogicalLink'' from project';
        return;
    end;
catch
    DSError.ErrorString = lasterr;
end;
% END OF function Initialize()
% ===================================================================================================================

function Uninitialize()

global System;

if(~isempty(System))
    if(~isempty(System.ActiveProject))
        System.ActiveProject.LogicalLinks.RemoveAll;
        System.DeselectProject;
    end;
    delete(System);
end;
% END OF function Uninitialize()
% ===================================================================================================================


function [DSError] = CalibrateOverAllCharacteristics()
    % Iterating over all DbCharacteristics of a project, 
    % creating a runtime characteristic and reading/writing values

global LogicalLink;

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

try
    % print "Iterating over all characteristics in the module and select scalar characteristics only:"    
    for CharacteristicCount = 0 : (LogicalLink.DbObject.DbLocation.DbCharacteristics.count - 1)
        ActDbCharacteristic = LogicalLink.DbObject.DbLocation.DbCharacteristics.GetItemByIndex(CharacteristicCount);

        if(strcmp(ActDbCharacteristic.Type, 'eCT_VALUE'))
            % Create a runtime characteristic which gets its information from a DbCharacteristic
            Characteristic = LogicalLink.Characteristics.Add(ActDbCharacteristic);
            DSError = CalibrateScalarCharacteristic(Characteristic);
            if(DSError.ErrorCode)
               disp(sprintf('Error occured during calibration of scalar characteristic ''%s'' (details: %s)', Characteristic.Name, DSError.ErrorString));
            end;
            % calibrate ECU variables
            DSError = CalibrateScalarCharacteristicECU(Characteristic);
            if(DSError.ErrorCode)
               disp(sprintf('Error occured during calibration of scalar characteristic ''%s'' (details: %s)', Characteristic.Name, DSError.ErrorString));
            end;
        elseif(strcmp(ActDbCharacteristic.Type, 'eCT_MAP'))
            % Create a runtime characteristic which gets its information from a DbCharacteristic
            Characteristic = LogicalLink.Characteristics.Add(ActDbCharacteristic);
            DSError = CalibrateMapCharacteristic(Characteristic);
            if(DSError.ErrorCode)
               disp(sprintf('Error occured during calibration of map characteristic ''%s'' (details: %s)', Characteristic.Name, DSError.ErrorString));
            end;
            % calibrate ECU variables
            DSError = CalibrateMapCharacteristicECU(Characteristic);
            if(DSError.ErrorCode)
               disp(sprintf('Error occured during calibration of map characteristic ''%s'' (details: %s)', Characteristic.Name, DSError.ErrorString));
            end;
        elseif(strcmp(ActDbCharacteristic.Type, 'eCT_CURVE'))
            % Create a runtime characteristic which gets its information from a DbCharacteristic
            Characteristic = LogicalLink.Characteristics.Add(ActDbCharacteristic);
            DSError = CalibrateCurveCharacteristic(Characteristic);
            if(DSError.ErrorCode)
               disp(sprintf('Error occured during calibration of curve characteristic ''%s'' (details: %s)', Characteristic.Name, DSError.ErrorString));
            end;
            % calibrate ECU variables
            DSError = CalibrateCurveCharacteristicECU(Characteristic);
            if(DSError.ErrorCode)
               disp(sprintf('Error occured during calibration of curve characteristic ''%s'' (details: %s)', Characteristic.Name, DSError.ErrorString));
            end;            
        else
            % eCT_CUBOID, eCT_VAL_BLK, eCT_ASCII
            disp('-----------------------------------------------------------------');
            disp(sprintf('Characteristic type ''%s'' of value ''%s'' is not supported', ActDbCharacteristic.Type, ActDbCharacteristic.ShortName));
        end;
    end;
catch
    DSError.ErrorCode   = 1;
    DSError.ErrorString = lasterr;
end;
% END OF function Uninitialize()
% ===================================================================================================================


function [DSError] = CalibrateScalarCharacteristic(Characteristic)
% Calibration of a single runtime characteristic

global constants

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

try
    disp('-----------------------------------------------------------------');
    disp(sprintf('Start calibration of scalar characteristic %s converted', Characteristic.Name));
    
    % read initial ecu value
    InitialValue = Characteristic.ReadVariant;
    
    if(Characteristic.DbObject.IsReadOnly)
        disp('This value is read only');
        return;
    end;
    
    if(isnumeric(InitialValue))
        disp(sprintf('\tInitial value:\t%d', InitialValue));
        
        % create new random value between lower and upper limit
        LowerLimit = sign(Characteristic.DbObject.LowerLimit) * min(abs(Characteristic.DbObject.LowerLimit), 2^64);
        UpperLimit = sign(Characteristic.DbObject.UpperLimit) * min(abs(Characteristic.DbObject.UpperLimit), 2^64);
        NewValue = LowerLimit + rand * (UpperLimit - LowerLimit);
        
        % write value
        disp(sprintf('\tWrite value:\t%d', NewValue));
        Characteristic.WriteVariant(NewValue, constants.eVT_VAL);
        
        % check if modified
        ActValue = Characteristic.ReadVariant;
        if(abs(ActValue-NewValue) > 0.1)
            disp('!!! Error: Value has not been modified !!!');
        end;
        
        % write back initial value
        disp('    Write back initial value');
        Characteristic.WriteVariant(InitialValue, constants.eVT_VAL);
        ActValue = Characteristic.ReadVariant;
        disp(sprintf('\tCurrent value:\t%d', ActValue));
        if(abs(ActValue-InitialValue) > 0.1);
            disp('!!! Error: Cannot write back initial value !!!');
        end;
        
    else
        disp(sprintf('\tInitial value:\t%s', InitialValue));
        Characteristic.WriteVariant(InitialConvertedValue, constants.eVT_VAL);
        ActValue = Characteristic.ReadVariant;
        if(~ strcmp(ActValue, InitialConvertedValue))
            disp('!!! Error: Cannot write back initial value !!!');
        end;
    end;
catch
    DSError.ErrorCode   = 1;
    DSError.ErrorString = lasterr;
end;
% END OF function CalibrateScalarCharacteristic(Characteristic)
% ===================================================================================================================

function [DSError] = CalibrateMapCharacteristic(Characteristic)
global constants

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

try
    disp('-----------------------------------------------------------------');
    disp(sprintf('Start calibration of map characteristic %s converted', Characteristic.Name));
    
    InitialCompleteValue = Characteristic.Read;
    
    InitialValue = Characteristic.Value.Read;
    InitialXAxis = Characteristic.XAxis.Read;
    InitialYAxis = Characteristic.YAxis.Read;
    
    LowerLimit = sign(Characteristic.DbObject.LowerLimit) * min(abs(Characteristic.DbObject.LowerLimit), 2^64);
    UpperLimit = sign(Characteristic.DbObject.UpperLimit) * min(abs(Characteristic.DbObject.UpperLimit), 2^64);
        
    [DSError, NewValue] = CreateRandom2DimCellArray(size(InitialValue), LowerLimit, UpperLimit);
    if(DSError.ErrorCode)
        return;
    end;
    
    disp('Write new value');
    Characteristic.Value.Write(NewValue, 0, -1, 0, -1, constants.eVT_VAL);
    ActValue = Characteristic.Value.Read;
    
    % check actual values with written values
    [Result, Description] = Compare2DimDoubleCellArray(NewValue, ActValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the current value on at least one position (details: %s)', Description));
    end;
    
    disp('Write back initial value');
    Characteristic.Value.Write(InitialValue, 0, -1, 0, -1, constants.eVT_VAL);
    
    ActValue = Characteristic.Value.Read;
    
    % check actual values with initial values
    [Result, Description] = Compare2DimDoubleCellArray(InitialValue, ActValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the initial value and the current value on at least one position (details: %s)', Description));
    end;
    
    disp('Write complete value');
    NewCompleteValue = InitialCompleteValue;
    NewCompleteValue{3} = NewValue;
    Characteristic.Write(NewCompleteValue, 0, -1, 0, -1, constants.eVT_VAL);

    ActCompleteValue = Characteristic.Read;
    
    % check actual values with written values
    [Result, Description] = Compare3DimDoubleCellArray(NewCompleteValue, ActCompleteValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the current value on at least one position (details: %s)', Description));
    end;
    
    disp('Write back initial complete value');
    Characteristic.Write(InitialCompleteValue, 0, -1, 0, -1, constants.eVT_VAL);

    ActCompleteValue = Characteristic.Read;
    
    % check actual values with written values
   [Result, Description] = Compare3DimDoubleCellArray(InitialCompleteValue, ActCompleteValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the initial value and the current value on at least one position (details: %s)', Description));
    end;
    
catch
    DSError.ErrorCode   = 1;
    DSError.ErrorString = lasterr;
end;
% END OF function [DSError] = CalibrateMapCharacteristic(Characteristic)
% ===================================================================================================================

function [DSError] = CalibrateCurveCharacteristic(Characteristic)
global constants

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

try
    disp('-----------------------------------------------------------------');
    disp(sprintf('Start calibration of curve characteristic %s converted', Characteristic.Name));

    InitialCompleteValue = Characteristic.Read;
    InitialAxis  = Characteristic.Axis.Read;
    InitialValue = Characteristic.Value.Read;
    
    %Create suitable values to write to characteristic that match its limits:         
    LowerLimit = sign(Characteristic.DbObject.LowerLimit) * min(abs(Characteristic.DbObject.LowerLimit), 2^64);
    UpperLimit = sign(Characteristic.DbObject.UpperLimit) * min(abs(Characteristic.DbObject.UpperLimit), 2^64);
        
    [DSError, NewValue] = CreateRandom2DimCellArray(size(InitialValue), LowerLimit, UpperLimit);
    if(DSError.ErrorCode)
        return;
    end;
    
    disp('Write single values');
    Characteristic.Value.Write(NewValue, 0, -1, constants.eVT_VAL);
    ActValue = Characteristic.Value.Read;

    [Result, Description] = Compare2DimDoubleCellArray(NewValue, ActValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the current value on at least one position (details: %s)', Description));
    end;
    
    disp('Write back initial values');
    Characteristic.Value.Write(InitialValue, 0, -1, constants.eVT_VAL);
    ActValue = Characteristic.Value.Read;
    
    % check InitialValue == ActValue
    [Result, Description] = Compare2DimDoubleCellArray(InitialValue, ActValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the initial value on at least one position (details: %s)', Description));
    end;
    
    disp('Write complete value');
    NewCompleteValue = InitialCompleteValue;
    NewCompleteValue{2} = NewValue;
        
    Characteristic.Write(NewCompleteValue, 0, -1, constants.eVT_VAL);
    ActCompleteValue = Characteristic.Read;
    
    % check actual values with written values
    [Result, Description] = Compare3DimDoubleCellArray(NewCompleteValue, ActCompleteValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the current value on at least one position (details: %s)', Description));
    end;
    
    % write back initial value
    Characteristic.Write(InitialCompleteValue, 0, -1, constants.eVT_VAL);
    ActCompleteValue = Characteristic.Read;
    
    % check actual values with written values
   [Result, Description] = Compare3DimDoubleCellArray(InitialCompleteValue, ActCompleteValue, 0.01);
    if(~Result)
        disp(sprintf('Found differences between the initial value and the current value on at least one position (details: %s)', Description));
    end;
    
catch
    DSError.ErrorCode   = 1;
    DSError.ErrorString = lasterr;
end;
% END OF function [DSError] = CalibrateMapCharacteristic(Characteristic)
% ===================================================================================================================


function [DSError] = CalibrateScalarCharacteristicECU(Characteristic)
% Calibration of a single runtime characteristic

global constants

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

try
    disp('-----------------------------------------------------------------');
    disp(sprintf('Start calibration of scalar characteristic ''%s'' on ECU', Characteristic.Name));
    
    % read initial ecu value
    InitialValue = Characteristic.ReadVariant(constants.eRT_ECU);
    
    if(Characteristic.DbObject.IsReadOnly)
        disp('This value is read only');
        return;
    end;
    
    disp(sprintf('\tInitial value:\t%d', InitialValue));
    
    NewValue = InitialValue - 1;
    
    % write value
    disp(sprintf('\tWrite value:\t%d', NewValue));
    Characteristic.WriteVariant(NewValue, constants.eVT_VAL, constants.eRT_ECU);
    
    % check if modified
    ActValue = Characteristic.ReadVariant(constants.eRT_ECU);
    if(abs(ActValue-NewValue) > 0.1)
        disp('!!! Error: Value has not been modified !!!');
    end;
    
    % write back initial value
    disp('    Write back initial value');
    Characteristic.WriteVariant(InitialValue, constants.eVT_VAL, constants.eRT_ECU);
    ActValue = Characteristic.ReadVariant(constants.eRT_ECU);
    disp(sprintf('\tCurrent value:\t%d', ActValue));
    if(abs(ActValue-InitialValue) > 0.1);
        disp('!!! Error: Cannot write back initial value !!!');
    end;
catch
    DSError.ErrorCode   = 1;
    DSError.ErrorString = lasterr;
end;
% END OF function CalibrateScalarCharacteristicECU(Characteristic)
% ===================================================================================================================

function [DSError] = CalibrateMapCharacteristicECU(Characteristic)
global constants

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

try
    disp('-----------------------------------------------------------------');
    disp(sprintf('Start calibration of map characteristic ''%s'' on ECU', Characteristic.Name));
    
    InitialCompleteValue = Characteristic.Read(0, -1, 0, -1, constants.eRT_ECU);
    
    InitialValue = Characteristic.Value.Read(0, -1, 0, -1, constants.eRT_ECU);
    InitialXAxis = Characteristic.XAxis.Read(0, -1, constants.eRT_ECU);
    InitialYAxis = Characteristic.YAxis.Read(0, -1, constants.eRT_ECU);
    
    NewValue = InitialValue;
    for Count = 1 : length(NewValue)
        if(NewValue{Count} > 0)
            NewValue{Count} = NewValue{Count} - 1;
        elseif(NewValue{Count} < 0)
            NewValue{Count} = NewValue{Count} + 1;
        end;
    end;
    
    disp('Write new value');
    Characteristic.Value.Write(NewValue, 0, -1, 0, -1, constants.eVT_VAL, constants.eRT_ECU);
    ActValue = Characteristic.Value.Read(0, -1, 0, -1, constants.eRT_ECU);
    
    % check actual values with written values
    [Result, Description] = Compare2DimDoubleCellArray(NewValue, ActValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the current value on at least one position (details: %s)', Description));
    end;
    
    disp('Write back initial value');
    Characteristic.Value.Write(InitialValue, 0, -1, 0, -1, constants.eVT_VAL, constants.eRT_ECU);
    
    ActValue = Characteristic.Value.Read(0, -1, 0, -1, constants.eRT_ECU);
    
    % check actual values with initial values
    [Result, Description] = Compare2DimDoubleCellArray(InitialValue, ActValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the initial value and the current value on at least one position (details: %s)', Description));
    end;
    
    disp('Write complete value');
    NewCompleteValue = InitialCompleteValue;
    NewCompleteValue{3} = NewValue;
    Characteristic.Write(NewCompleteValue, 0, -1, 0, -1, constants.eVT_VAL, constants.eRT_ECU);

    ActCompleteValue = Characteristic.Read(0, -1, 0, -1, constants.eRT_ECU);
    
    % check actual values with written values
    [Result, Description] = Compare3DimDoubleCellArray(NewCompleteValue, ActCompleteValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the current value on at least one position (details: %s)', Description));
    end;
    
    disp('Write back initial complete value');
    Characteristic.Write(InitialCompleteValue, 0, -1, 0, -1, constants.eVT_VAL, constants.eRT_ECU);

    ActCompleteValue = Characteristic.Read(0, -1, 0, -1, constants.eRT_ECU);
    
    % check actual values with written values
   [Result, Description] = Compare3DimDoubleCellArray(InitialCompleteValue, ActCompleteValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the initial value and the current value on at least one position (details: %s)', Description));
    end;
    
catch
    DSError.ErrorCode   = 1;
    DSError.ErrorString = lasterr;
end;
% END OF function [DSError] = CalibrateMapCharacteristicECU(Characteristic)
% ===================================================================================================================

function [DSError] = CalibrateCurveCharacteristicECU(Characteristic)
global constants

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

try
    disp('-----------------------------------------------------------------');
    disp(sprintf('Start calibration of curve characteristic ''%s'' on ECU', Characteristic.Name));

    InitialCompleteValue = Characteristic.Read(0, -1, constants.eRT_ECU);
    InitialAxis  = Characteristic.Axis.Read(0, -1, constants.eRT_ECU);
    InitialValue = Characteristic.Value.Read(0, -1, constants.eRT_ECU);
        
    NewValue = InitialValue;
    for Count = 1 : length(NewValue)
        if(NewValue{Count} > 0)
            NewValue{Count} = NewValue{Count} - 1;
        elseif(NewValue{Count} < 0)
            NewValue{Count} = NewValue{Count} + 1;
        end;
    end;
        
    disp('Write single values');
    Characteristic.Value.Write(NewValue, 0, -1, constants.eVT_VAL, constants.eRT_ECU);
    ActValue = Characteristic.Value.Read(0, -1, constants.eRT_ECU);

    [Result, Description] = Compare2DimDoubleCellArray(NewValue, ActValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the current value on at least one position (details: %s)', Description));
    end;
    
    disp('Write back initial values');
    Characteristic.Value.Write(InitialValue, 0, -1, constants.eVT_VAL, constants.eRT_ECU);
    ActValue = Characteristic.Value.Read(0, -1, constants.eRT_ECU);
    
    % check InitialValue == ActValue
    [Result, Description] = Compare2DimDoubleCellArray(InitialValue, ActValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the initial value on at least one position (details: %s)', Description));
    end;
    
    disp('Write complete value');
    NewCompleteValue = InitialCompleteValue;
    NewCompleteValue{2} = NewValue;
        
    Characteristic.Write(NewCompleteValue, 0, -1, constants.eVT_VAL, constants.eRT_ECU);
    ActCompleteValue = Characteristic.Read(0, -1, constants.eRT_ECU);
    
    % check actual values with written values
    [Result, Description] = Compare3DimDoubleCellArray(NewCompleteValue, ActCompleteValue, 0.1);
    if(~Result)
        disp(sprintf('Found differences between the written value and the current value on at least one position (details: %s)', Description));
    end;
    
    % write back initial value
    Characteristic.Write(InitialCompleteValue, 0, -1, constants.eVT_VAL, constants.eRT_ECU);
    ActCompleteValue = Characteristic.Read(0, -1, constants.eRT_ECU);
    
    % check actual values with written values
   [Result, Description] = Compare3DimDoubleCellArray(InitialCompleteValue, ActCompleteValue, 0.01);
    if(~Result)
        disp(sprintf('Found differences between the initial value and the current value on at least one position (details: %s)', Description));
    end;
    
catch
    DSError.ErrorCode   = 1;
    DSError.ErrorString = lasterr;
end;
% END OF function [DSError] = CalibrateMapCharacteristicECU(Characteristic)
% ===================================================================================================================


function [DSError, NewValue] = CreateRandom2DimCellArray(SizeOfValue, LowerLimit, UpperLimit)

DSError.ErrorCode   = 0;
DSError.ErrorString = '';
NewValue = [];

try
    if(length(SizeOfValue) ~= 2)
        DSError.ErrorCode   = 1;
        DSError.ErrorString = 'Unsupported number of dimensions for ''CreateRandomCellArray''';
        return;
    end;
    
    NewValue = cell(SizeOfValue);
    
    for x = 1 : SizeOfValue(1)
        for y = 1 : SizeOfValue(2)
            NewValue{x, y} = LowerLimit + rand * (UpperLimit - LowerLimit);
        end;
    end;
catch
    DSError.ErrorCode   = 1;
    DSError.ErrorString = lasterr;
end;
% END OF function [DSError, NewValue] = CreateRandom2DimCellArray(SizeOfValue, LowerLimit, UpperLimit)
% ===================================================================================================================

function [Result, Description] = Compare2DimDoubleCellArray(CellArray1, CellArray2, Tolerance)

Result = 0;
Description = '';

if(size(CellArray1) ~= size(CellArray2))
    Description = 'The sizes of the cell arrays are not equal';
    return;
end;

try
    DoubleMatrix1 = cell2mat(CellArray1);
    DoubleMatrix2 = cell2mat(CellArray2);
    
    DifPos = find(abs(DoubleMatrix1 - DoubleMatrix2) > Tolerance);
    if(DifPos)
        Difference = abs(DoubleMatrix1(DifPos(1)) - DoubleMatrix2(DifPos(1)));
        Description = sprintf('Found differences %.2f at position %d', Difference, DifPos(1));
    else
        Result = 1;
    end;
catch
    disp(sprintf('Error occured during compare cell arrays: %s', lasterr));
end;
% END OF function [DSError, NewValue] = CreateRandom2DimCellArray(SizeOfValue, LowerLimit, UpperLimit)
% ===================================================================================================================

function [Result, Description] = Compare3DimDoubleCellArray(CellArray1, CellArray2, Tolerance)
Result = 0;
Description = '';

if(size(CellArray1) ~= size(CellArray2))
    Description = 'The sizes of the cell arrays are not equal';
    return;
end;

ArraySize = size(CellArray1);
for Count = 1 : ArraySize(1)
    [Result, Description] = Compare2DimDoubleCellArray(CellArray1{Count}, CellArray2{Count}, Tolerance);
    if(~Result)
        return;
    end;
end;
% END OF function [Result, Description] = Compare3DimDoubleCellArray(CellArray1, CellArray2, Tolerance)
% ===================================================================================================================

function [Success] = CheckMLVersionStruct(RequiredVersion)

Success = 0;

RequiredVersionString = sprintf('%d.%d.%d', RequiredVersion(1), RequiredVersion(2), RequiredVersion(3));

% check position 1
[MLVer_1, Rest] = strtok(version,  '. ');

if(str2num(MLVer_1) < RequiredVersion(1))
    return;
end;

if(str2num(MLVer_1) > RequiredVersion(1))
    Success = 1;
    return;
end;

% check position 2
[MLVer_2, Rest] = strtok(Rest, '. ');

if(str2num(MLVer_2) < RequiredVersion(2))
    return;
end;

if(str2num(MLVer_2) > RequiredVersion(2))
    Success = 1;
    return;
end;

% check position 2
[MLVer_3, Rest] = strtok(Rest, '. ');
if(str2num(MLVer_3) < RequiredVersion(3))
    return;
end;

Success = 1;
% function [Success] = CheckMLVersionStruct(RequiredVersion)
% ===================================================================================================================
