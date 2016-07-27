function [DSError] = CalibrateScalarCharacteristic(VariableName, NewValue)
% Calibration of a single runtime characteristic

global constants
global LogicalLink

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

if (~ischar(VariableName))
    disp('The variable name should be a string.');
    return;
end

try
    ActDbCharacteristic = LogicalLink.DbObject.DbLocation.DbCharacteristics.GetItemByName(VariableName);
    Characteristic      = LogicalLink.Characteristics.Add(ActDbCharacteristic);
    
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
        Characteristic.WriteVariant(NewValue, constants.eVT_VAL);
        
        fprintf('Write value:\t%d\r\n', NewValue);
        ActValue = Characteristic.ReadVariant;
        
        % check if modified
        if(abs(ActValue-NewValue) > 0.1)
            disp('!!! Error: Value has not been modified !!!');
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
catch
    DSError.ErrorCode   = 1;
    DSError.ErrorString = lasterr;
end;