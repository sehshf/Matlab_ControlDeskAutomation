classdef ControlDeskAuto 
    
    properties (SetAccess = private)
        System
        LogicalLink     
        ExperimentName
    end
    
    methods
        function obj = ControlDeskAuto(name)
            
            obj.ExperimentName = name;
            
            init = initialize(name);

            if(~isempty(init.error))
                disp(['Error during initialize of DsMC3_CalibrationDemo:', char(10), init.error]);
                %uninitialize();
            return;
            end
            
            obj.System         = init.System;
            obj.LogicalLink    = init.LogicalLink;
            
            disp('Initialization of HIL test succeeded.');            
        end
        
        function calibrate(this, VariableName, NewValue)
            
            ActDbCharacteristic = this.LogicalLink.DbObject.DbLocation.DbCharacteristics.GetItemByName(VariableName);
            VariableType = ActDbCharacteristic.Type;

            switch VariableType
                case 'eCT_VALUE'
                    error = CalibrateScalar   (this, VariableName, NewValue);
                    %x = this.Characteristic;
                    %error = CalibrateScalarECU(this, VariableName, NewValue);
                    if(~isempty(error))
                        fprintf('Error occured during calibration of scalar characteristic ''%s'' (details: %s)', VariableName, error);
                    end
%                     case 'eCT_MAP'
%                         error = CalibrateMap   (this, VariableName, NewValue);
%                         error = CalibrateMapECU(this, VariableName, NewValue);
%                         if(~isempty(error))
%                             fprintf('Error occured during calibration of map characteristic ''%s'' (details: %s)', VariableName, error);
%                         end
%                     case 'eCT_CURVE'
%                         error = CalibrateCurve   (this, VariableName, NewValue);
%                         error = CalibrateCurveECU(this, VariableName, NewValue);
%                         if(~isempty(error))
%                             fprintf('Error occured during calibration of curve characteristic ''%s'' (details: %s)', VariableName, error);
%                         end
                otherwise
                    % eCT_CUBOID, eCT_VAL_BLK, eCT_ASCII
                    disp('-----------------------------------------------------------------');
                    fprintf('Characteristic type ''%s'' of value ''%s'' is not supported', VariableType, NewValue);
            end
        end
        
        function vars = getVariables(this)
            DbChar = this.LogicalLink.DbObject.DbLocation.DbCharacteristics;
            count  = DbChar.count;
            for i  = 0 : (count - 1)
                item = DbChar.GetItemByIndex(i);
                vars{i+1} = item.ShortName;
            end
        end
            
    end
end

%% Helper functions for the class methods

function [y] = initialize(name)
    
    y.error = '';
    CR = char(10);
            
    try
        % intialize the test object
        disp('Creating a COM Automation server for ControlDeskNG');
        y.System = actxserver('ControlDeskNG.MC3System', '127.0.0.1');
        if (isempty(y.System))
            y.error = 'Cannot get COM object from ''ControlDeskNG.MC3System''';
            return;
        end;
        pause(0.1);

        % get name of the available projects
        DbProjectDescriptions = y.System.DbProjectDescriptions;
        NumProjects = double(DbProjectDescriptions.count);
        if (NumProjects < 1)
            y.error = 'Cannot find any Project from ControlDeskNG';
            return;
        end;        
        
        NameFound = false;
        i = 0;
        while (~NameFound && i < NumProjects)
            DbProjectDescription = DbProjectDescriptions.GetItemByIndex(i);
            ProjectName = DbProjectDescription.ShortName;
            if strcmp(ProjectName, name)
                NameFound = true;                
            end
            i = i + 1;
        end
        
        if (NameFound)
            disp([CR, 'Project ''', ProjectName, ''' was selected!', CR]);
        else
            y.error = sprintf('Cannot find project ''%s'' in ControlDeskNG', name);
            return;
        end

        Project = y.System.SelectProjectByName(name);
        if(isempty(Project))
            y.error = sprintf('Cannot select project ''%s'' in ControlDeskNG', ProjectName);
            return;
        end

        %DbLocation = y.System.ActiveProject.DbProject.DbModuleLocations.GetItemByIndex(0);
        VehicleInformation = y.System.ActiveProject.DbProject.DbVehicleInformations.GetItemByIndex(0);
        UsedDbLogicalLink = VehicleInformation.DbLogicalLinks.GetItemByIndex(0); 
        UsedDbBinary = UsedDbLogicalLink.DbLocation.DbBinaries.GetItemByIndex(0);

        % create runtime logical link
        y.LogicalLink = y.System.ActiveProject.LogicalLinks.AddByNames(UsedDbLogicalLink.ShortName, UsedDbBinary.ShortName);

        % prepare online calibration
        %LogicalLink.ConnectToModule(constants.eLT_UPLOAD);

        % Activate work page, otherwise calibration will be denied:
        y.LogicalLink.MemoryPage = 1;
        if(isempty(y.LogicalLink))
            y.error = 'Cannot get ''LogicalLink'' from project';
            return;
        end
    catch ME
        y.error = getReport(ME);
    end
end    % End of initialize()

function error = CalibrateScalar(this, VariableName, NewValue)
    % Calibration of a single runtime characteristic
    error = '';

    if (~ischar(VariableName))
        disp('The variable name should be a string.');
        return;
    end

    try
        try
            Characteristic = this.LogicalLink.Characteristics.GetItemByName(VariableName);
        catch
            ActDbCharacteristic = this.LogicalLink.DbObject.DbLocation.DbCharacteristics.GetItemByName(VariableName);
            Characteristic = this.LogicalLink.Characteristics.Add(ActDbCharacteristic);
        end
        
        disp('-----------------------------------------------------------------');
        fprintf('Start calibration of scalar characteristic "%s" converted\r\n', Characteristic.Name);

        % read initial ecu value
        InitialValue = Characteristic.ReadVariant;

        if(Characteristic.DbObject.IsReadOnly)
            disp('This value is read only');
            return;
        end;

        if(isnumeric(InitialValue))
            fprintf('Initial value:\t%d\r\n', InitialValue);

            % create new random value between lower and upper limit
            %LowerLimit = sign(Characteristic.DbObject.LowerLimit) * min(abs(Characteristic.DbObject.LowerLimit), 2^64);
            %UpperLimit = sign(Characteristic.DbObject.UpperLimit) * min(abs(Characteristic.DbObject.UpperLimit), 2^64);
            %NewValue = LowerLimit + rand * (UpperLimit - LowerLimit);

            % write value
            Characteristic.WriteVariant(NewValue, MCD3Constants.eVT_VAL);
            ActValue = Characteristic.ReadVariant;

            % check if modified
            if(abs(ActValue-NewValue) > 0.1)
                disp('!!! Error: Value has not been modified !!!');
            else
                fprintf('Written value:\t%d\r\n', ActValue);
            end;

    %         % write back initial value
    %         disp('    Write back initial value');
    %         Characteristic.WriteVariant(InitialValue, constants.eVT_VAL);
    %         ActValue = Characteristic.ReadVariant;
    %         disp(sprintf('\tCurrent value:\t%d', ActValue));
    %         if(abs(ActValue-InitialValue) > 0.1);
    %             disp('!!! Error: Cannot write back initial value !!!');
    %         end;

        else
            fprintf('Initial value:\t%s\r\n', InitialValue);
    %         Characteristic.WriteVariant(InitialConvertedValue, constants.eVT_VAL);
    %         ActValue = Characteristic.ReadVariant;
    %         if(~ strcmp(ActValue, InitialConvertedValue))
    %             disp('!!! Error: Cannot write back initial value !!!');
    %         end;
        end;
    catch ME
        error = getReport(ME);
    end
end

