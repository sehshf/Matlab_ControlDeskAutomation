function varargout = SCRTempTest_GUI(varargin)

%  Create and then hide the GUI as it is being constructed.
fh = figure('Visible','off','Position',[360,500,450,285]);

fColor = get(fh, 'Color');

% Share data across GUI
TestData = initData();
guidata(fh, TestData);

%% Experiment selection
ExpNameVec = {'SCRTempSensor', 'SCRNOxSensor'};

pmh_Exp = uicontrol('Style'   , 'popupmenu', ...
                    'String'  , ExpNameVec , ...
                    'Value'   , 1          , ...
                    'Position', [30, 240, 130, 20], ...
                    'Callback', @pmh_Exp_Callback ...
                    );


%% Temperature module
% Position handling
pos = [0, 170];

% Initial temperature
sth_initTemp = uicontrol('Style'   , 'text', ...
                         'String'  , ['Initial temperature' ...
                         char(10)    'T [K]'], ...
                         'Position', [pos(1), pos(2), 150, 40] ...
                         );
eth_initTemp = uicontrol('Style'   , 'edit', ...
                         'Position', [pos(1)+57, pos(2)-10, 40, 20], ...
                         'Callback', @eth_initTemp_Callback ...
                         );

set(sth_initTemp, 'BackgroundColor', fColor);

% Final temperature
sth_finalTemp = uicontrol('Style'   , 'text', ...
                          'String'  , ['Final temperature' ...
                          char(10)    'T [K]'], ...
                          'Position', [pos(1)+120, pos(2), 150, 40] ...
                          );
eth_finalTemp = uicontrol('Style'   , 'edit', ...
                          'Position', [pos(1)+177, pos(2)-10, 40, 20], ...
                          'Callback', @eth_finalTemp_Callback ...
                          );

set(sth_finalTemp, 'BackgroundColor', fColor);

% Rate of change
sth_rateTemp = uicontrol('Style'   , 'text', ...
                         'String'  , ['Rate of change' ...
                         char(10)    '[K/s]'], ...
                         'Position', [pos(1)+240, pos(2), 150, 40] ...
                         );
eth_rateTemp = uicontrol('Style'   , 'edit', ...
                         'Position', [pos(1)+295, pos(2)-10, 40, 20], ...
                         'Callback', @eth_rateTemp_Callback ...
                         );

set(sth_rateTemp, 'BackgroundColor', fColor);

% Temperature trace
tbh_traceTemp = uicontrol('Style'   , 'togglebutton', ...
                          'String'  , 'Trace', ...
                          'value'   , 0, ...
                          'Position', [pos(1)+380, pos(2)-5, 50, 40], ...
                          'Callback', @tbh_traceTemp_Callback ...
                          );
                      
set(tbh_traceTemp, 'BackgroundColor', fColor);

%%
% Assign the GUI a name to appear in the window title.
set(fh,'Name','HIL Test')

% Move the GUI to the center of the screen.
movegui(fh,'center')

% Make the GUI visible.
set(fh,'Visible','on');

end

%% Initialization
% Initialize data
function data = initData()
    data.ExpName = 'SCRTempSensor';
    data.SCRTemp.Init  = 300;
    data.SCRTemp.Final = 500;
    data.SCRTemp.Rate  = 0.1;
end


%% Callback functions
%% Experiment
function pmh_Exp_Callback(hObject, eventdata)
    data = guidata(hObject);
    data.ExpName = get(hObject, 'String');
    guidata(hObject,data);
end

%% Temperature module
% Get initial temperature
function eth_initTemp_Callback(hObject, eventdata)
    data = guidata(hObject);
    str  = get(hObject, 'String');
    data.SCRTemp.Init = str2double(str);
    guidata(hObject,data);
end

% Get final Temperature
function eth_finalTemp_Callback(hObject, eventdata)
    data = guidata(hObject);
    str  = get(hObject, 'String');
    data.SCRTemp.Final = str2double(str);
    guidata(hObject,data);
end

% Get rate of change
function eth_rateTemp_Callback(hObject, eventdata)
    data = guidata(hObject);
    str  = get(hObject, 'String');
    data.SCRTemp.Rate = str2double(str);
    guidata(hObject,data);
end

% Temperature trace
function tbh_traceTemp_Callback(hObject, eventdata)
    data  = guidata(hObject);
    state = get(hObject,'Value');
    %set(hObject, 'Interruptible', 'on');
    if state == 1
        traceSCRTemp(data, state);
    end
end
