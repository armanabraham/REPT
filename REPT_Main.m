function varargout = REPT_Main(varargin)
% REPT_Main M-file for REPT_Main.fig
%      REPT_Main, by itself, creates a new REPT_Main or raises
%      the existing
%      singleton*.
%
%      H = REPT_Main returns the handle to a new REPT_Main or the
%      handle to
%      the existing singleton*.
%
%      REPT_Main('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REPT_Main.M with the given input arguments.
%
%      REPT_Main('Property','Value',...) creates a new REPT_Main or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before REPT_GUIControl_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to REPT_Main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help REPT_Main

% Last Modified by GUIDE v2.5 07-Mar-2011 10:51:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @REPT_Main_OpeningFcn, ...
                   'gui_OutputFcn',  @REPT_Main_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before REPT_Main is made visible.
function REPT_Main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to REPT_Main (see VARARGIN)

% Choose default command line output for REPT_Main
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes REPT_Main wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Initialise COM1 serial port to control the stimulator
% Create serial port object and set its properties to communicate with the
% Magstim stimulator. Serial port object is created as a part of
% 'handles' data structure to be able to use it in other when programming
% using 'guide'
handles.serialPortObj = serial('COM1', 'BaudRate', 9600, 'DataBits', 8, 'StopBits', 1, 'Parity', 'none', 'FlowControl', 'none', 'Terminator', '?');

% Callback function to execute every 500 ms to ensure that the stimulator
% is in the remote control mode and will stay armed. Otherwise,
% stimulator will disarm itself automatically in about 1 sec.
handles.serialPortObj.TimerPeriod = 0.5; % period of executing the callback function in sec
fopen(handles.serialPortObj);
handles.serialPortObj.TimerFcn = {'Rapid2_MaintainCommunication'};

% Get staircase default parameters 
[success, staircaseParams] = REPT_DefaultStaircaseParams;
handles.staircaseParams = staircaseParams;

% need this param to calculate delay necessary for stimulator when changing
% power level
handles.previousPowerLevel = 0; 

% File name for storing the results of the staircase
currentDir = pwd;
fileName = [get(handles.ParticipantNameEditControl, 'String'), '.txt'];
fullFileName = [currentDir, filesep, fileName];
text = ['Output file name: ', fullFileName];
set(handles.OutputFileNameTextbox, 'String', text);


% Save serialPortObj and staircaseParams as a 'handles'
guidata(hObject, handles);

% Set the initial power level indicated on PowerLevelsListbox (it is set
% to 40 percent by default)
handles.powerLevel = get(handles.PowerLevelListbox,'Value');
% need this param to calculate delay necessary for stimulator when changing
% power level
handles.previousPowerLevel = 0; 

if handles.powerLevel <= 100
    success = Rapid2_SetPowerLevel(handles.serialPortObj, handles.powerLevel, 1);
    if ~success
        display 'Cannot set power level';
        return
    else
        % display 'Power level is set to';
        display(handles.powerLevel);
    end
    % introduce delay to allow the  stimulator to adjust to the new power level
    powerLevelChange = abs(handles.previousPowerLevel - handles.powerLevel);
    % Introduce delay to allow time for the stimulator to adjust the power level
    % 50 ms for each 1% of change in stimulation level
    delayInMs = powerLevelChange * 50;
    Rapid2_Delay(delayInMs, handles.serialPortObj);

else
    display 'Stimulator power level cannot be greater than 100';
end

% Remember this new power level as previous
handles.previousPowerLevel = handles.powerLevel;
% Save powerLevel as GUIDATA for using when 'Stimulate' button is clicked
guidata(hObject, handles);

% Get and display coil temperature
% TODO: think when to update coil temperature. 
% it can be updated at regular time intervals (say every 5 seconds), or
% when "Stimulate", "Estimate ...", or one-click stimulation is present. 
[success, temperature] = Rapid2_GetCoilTemperature(handles.serialPortObj);
if ~success
    display 'Cannot acquire coil temperature';
    return
else
    maxTemperature = max(temperature.coil1, temperature.coil2);
    set(handles.coilTemperatureEditControl, 'String', num2str(maxTemperature));
end


% --- Outputs from this function are returned to the command line.
function varargout = REPT_Main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in PowerLevelListbox.
function PowerLevelListbox_Callback(hObject, eventdata, handles)
% hObject    handle to PowerLevelListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns PowerLevelListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PowerLevelListbox

handles.powerLevel = get(hObject,'Value');

% if not in one-click stimulation mode, disable 'Stimulate' button
% to prevent premature stimulation
if ~get(handles.OneClickStimulationCheckbox, 'Value') 
    set(handles.StimulatePushButton, 'Enable', 'Off');
end

% Set stimulator's power level
% Theoretically this value can never be more than 100. However, this
% precaution is necessary as we are working with a potent device that can't
% be set a power level above the safety levels. 
if handles.powerLevel <= 100
    success = Rapid2_SetPowerLevel(handles.serialPortObj, handles.powerLevel, 1);
    if ~success
        display 'Cannot set power level';
        return
    else
        % display 'Power level is set to';
        display(handles.powerLevel);
    end
    
    % introduce delay to allow the  stimulator to adjust to the new power level
    powerLevelChange = abs(handles.previousPowerLevel - handles.powerLevel);
    % Introduce delay to allow time for the stimulator to adjust the power level
    % 50 ms for each 1% of change in stimulation level
    delayInMs = powerLevelChange * 50;
    Rapid2_Delay(delayInMs, handles.serialPortObj);

else
    display 'Stimulator power level cannot be greater than 100';
end

handles.previousPowerLevel = handles.powerLevel;
% Save powerLevel as GUIDATA for using when 'Stimulate' button is clicked
guidata(hObject, handles);

% if in one-click mode, deliver pulse
if get(handles.OneClickStimulationCheckbox, 'Value') 
    % Trigger the stimulator in fast mode
    success = Rapid2_TriggerPulse(handles.serialPortObj, 1);
else
    % or else, enable 'Stimulate' button
    set(handles.StimulatePushButton, 'Enable', 'On');
end

% --- Executes on button press in StimulatePushButton.
function StimulatePushButton_Callback(hObject, eventdata, handles)
% hObject    handle to StimulatePushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Trigger the stimulator in fast mode
success = Rapid2_TriggerPulse(handles.serialPortObj, 1);

% --- Executes on button press in ArmStimulatorPushButton.
function ArmStimulatorPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to ArmStimulatorPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Arm the stimulator
success = Rapid2_ArmStimulator(handles.serialPortObj);
if ~success
    display 'Cannot arm the stimulator';
    runLoop = 0;
else
    display 'Stimulator is armed';

    % Enable controls for parameters
    %    set(handles.PowerLevelListbox, 'Enable', 'On'); % Matlab seems to have a bug when disabling listbox control 
    set(handles.OneClickStimulationCheckbox, 'Enable', 'On');
    if ~get(handles.OneClickStimulationCheckbox, 'Value')
        set(handles.StimulatePushButton, 'Enable', 'On');
    end
    set(handles.PhospheneThresholdPushButton, 'Enable', 'On');

    
    set(handles.MinPowerLevelEditControl, 'Enable', 'On');
    set(handles.MaxPowerLevelEditControl, 'Enable', 'On');
    set(handles.PulseDelayEditControl, 'Enable', 'On');
        
    set(handles.ParticipantNameEditControl, 'Enable', 'On');

end

% Deactivate safety switch on the coil
success = Rapid2_IgnoreCoilSafetySwitch(handles.serialPortObj);
if ~success
    display 'Cannot ignore the safety switch on the coil';
    runLoop = 0;
else
    display 'Coil safety switch is deactivated';
end
                
% --- Executes on button press in oneClickStimulationCheckbox.
function oneClickStimulationCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to oneClickStimulationCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of oneClickStimulationCheckbox


% --- Executes on button press in DisarmStimulatoPushButton.
function DisarmStimulatoPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to DisarmStimulatoPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Deactivate safety switch on the coil

success = Rapid2_DisarmStimulator(handles.serialPortObj);
if ~success
    display 'Cannot disarm stimulator';
    runLoop = 0;
else
    display 'Stimulator is disarmed';
    % Disable controls to preven modifying the staircase parameters. 
    % set(handles.PowerLevelListbox, 'Enable', 'Off'); % isn't used to avoid Matlab bug 
    set(handles.OneClickStimulationCheckbox, 'Enable', 'Off');
    set(handles.StimulatePushButton, 'Enable', 'Off');
    set(handles.PhospheneThresholdPushButton, 'Enable', 'Off');
    
    set(handles.MinPowerLevelEditControl, 'Enable', 'Off');
    set(handles.MaxPowerLevelEditControl, 'Enable', 'Off');
    set(handles.PulseDelayEditControl, 'Enable', 'Off');
       
end


function xMaxEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to xMaxEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xMaxEditControl as text
%        str2double(get(hObject,'String')) returns contents of xMaxEditControl as a double


% --- Executes during object creation, after setting all properties.
function xMaxEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xMaxEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function xStepEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to xStepEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xStepEditControl as text
%        str2double(get(hObject,'String')) returns contents of xStepEditControl as a double

% Get updated xstep
handles.staircaseParams.xstep = str2double(get(handles.xStepEditControl, 'String'));
%Calculate new xstep
handles.staircaseParams.xmax = REPT_StaircaseParamMaxValue(handles.staircaseParams.xmin, handles.staircaseParams.xstep, handles.staircaseParams.xlevels);
% Update xmax
set(handles.xMaxEditControl, 'String', num2str(handles.staircaseParams.xmax));

% To store GUIdata
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function xStepEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xStepEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xLevelsEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to xLevelsEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xLevelsEditControl as text
%        str2double(get(hObject,'String')) returns contents of xLevelsEditControl as a double

% Get updated xlevels
handles.staircaseParams.xlevels = str2double(get(handles.xLevelsEditControl, 'String'));
%Calculate new xmax
handles.staircaseParams.xmax = REPT_StaircaseParamMaxValue(handles.staircaseParams.xmin, handles.staircaseParams.xstep, handles.staircaseParams.xlevels);
% Update xmax
set(handles.xMaxEditControl, 'String', num2str(handles.staircaseParams.xmax));

% To store GUIdata
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function xLevelsEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xLevelsEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MinPowerLevelEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to MinPowerLevelEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinPowerLevelEditControl as text
%        str2double(get(hObject,'String')) returns contents of MinPowerLevelEditControl as a double


% --- Executes during object creation, after setting all properties.
function MinPowerLevelEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinPowerLevelEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MaxPowerLevelEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to MaxPowerLevelEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxPowerLevelEditControl as text
%        str2double(get(hObject,'String')) returns contents of MaxPowerLevelEditControl as a double


% --- Executes during object creation, after setting all properties.
function MaxPowerLevelEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxPowerLevelEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bBaseEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to bBaseEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bBaseEditControl as text
%        str2double(get(hObject,'String')) returns contents of bBaseEditControl as a double

% Get updated xmin
handles.staircaseParams.bbase = str2double(get(handles.bBaseEditControl, 'String'));
%Calculate new xmax
handles.staircaseParams.bmax = REPT_StaircaseParamMaxValue(handles.staircaseParams.bbase, handles.staircaseParams.bstep, handles.staircaseParams.blevels);
% Update xmax
set(handles.bMaxEditControl, 'String', num2str(handles.staircaseParams.bmax));

% To store GUIdata
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function bBaseEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bBaseEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function aMaxEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to aMaxEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of aMaxEditControl as text
%        str2double(get(hObject,'String')) returns contents of aMaxEditControl as a double


% --- Executes during object creation, after setting all properties.
function aMaxEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aMaxEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function aStepEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to aStepEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of aStepEditControl as text
%        str2double(get(hObject,'String')) returns contents of aStepEditControl as a double

% Get updated xstep
handles.staircaseParams.astep = str2double(get(handles.aStepEditControl, 'String'));
%Calculate new xstep
handles.staircaseParams.amax = REPT_StaircaseParamMaxValue(handles.staircaseParams.amin, handles.staircaseParams.astep, handles.staircaseParams.alevels);
% Update xmax
set(handles.aMaxEditControl, 'String', num2str(handles.staircaseParams.amax));

% To store GUIdata
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function aStepEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aStepEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function aLevelsEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to aLevelsEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of aLevelsEditControl as text
%        str2double(get(hObject,'String')) returns contents of aLevelsEditControl as a double

% Get updated xlevels
handles.staircaseParams.alevels = str2double(get(handles.aLevelsEditControl, 'String'));
%Calculate new xmax
handles.staircaseParams.amax = REPT_StaircaseParamMaxValue(handles.staircaseParams.amin, handles.staircaseParams.astep, handles.staircaseParams.alevels);
% Update xmax
set(handles.aMaxEditControl, 'String', num2str(handles.staircaseParams.amax));

% To store GUIdata
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function aLevelsEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aLevelsEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function bMaxEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to bMaxEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bMaxEditControl as text
%        str2double(get(hObject,'String')) returns contents of bMaxEditControl as a double


% --- Executes during object creation, after setting all properties.
function bMaxEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bMaxEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function bStepEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to bStepEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bStepEditControl as text
%        str2double(get(hObject,'String')) returns contents of bStepEditControl as a double

% Get updated xstep
handles.staircaseParams.bstep = str2double(get(handles.bStepEditControl, 'String'));
%Calculate new xstep
handles.staircaseParams.bmax = REPT_StaircaseParamMaxValue(handles.staircaseParams.bbase, handles.staircaseParams.bstep, handles.staircaseParams.blevels);
% Update xmax
set(handles.bMaxEditControl, 'String', num2str(handles.staircaseParams.bmax));

% To store GUIdata
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function bStepEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bStepEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bLevelsEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to bLevelsEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bLevelsEditControl as text
%        str2double(get(hObject,'String')) returns contents of bLevelsEditControl as a double

% Get updated xlevels
handles.staircaseParams.blevels = str2double(get(handles.bLevelsEditControl, 'String'));
%Calculate new xmax
handles.staircaseParams.bmax = REPT_StaircaseParamMaxValue(handles.staircaseParams.bbase, handles.staircaseParams.bstep, handles.staircaseParams.blevels);
% Update xmax
set(handles.bMaxEditControl, 'String', num2str(handles.staircaseParams.bmax));

% To store GUIdata
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function bLevelsEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bLevelsEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PhospheneThresholdPushButton.
function PhospheneThresholdPushButton_Callback(hObject, eventdata, handles)
% hObject    handle to PhospheneThresholdPushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Read the staircase parameters and run the staircase to estimate the
% phosphene treshold

minPowerLevel = str2double(get(handles.MinPowerLevelEditControl, 'String'));
maxPowerLevel = str2double(get(handles.MaxPowerLevelEditControl, 'String'));
pulseDelay = str2double(get(handles.PulseDelayEditControl, 'String'));

spaceToTrigger = get(handles.SpaceToTriggerCheckbox, 'Value');


% Put together file name and file path 
currentDir = pwd;
fileName = [get(handles.ParticipantNameEditControl, 'String'), '.txt'];
fullFileName = [currentDir, filesep, fileName];
% Display the file name in the "Info" space of the window 
text = ['Output file name: ', fullFileName];
set(handles.OutputFileNameTextbox, 'String', text);

% Disable "Estimate Phosphene Threshold" button to avoid "catching" spacebar
% pressed during the staircase
% disable "Run MOBS" button to avoid Spacebar button presses collected
set(handles.PhospheneThresholdPushButton, 'Enable', 'off'); 

success = REPT_RunAdaptiveStaircase(minPowerLevel, maxPowerLevel, pulseDelay, spaceToTrigger, fullFileName, handles.staircaseParams, handles.serialPortObj);
 
% disable "Run MOBS" button to avoid Spacebar button presses collected
set(handles.PhospheneThresholdPushButton, 'Enable', 'on'); 

function aMinEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to aMinEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of aMinEditControl as text
%        str2double(get(hObject,'String')) returns contents of aMinEditControl as a double

% Get updated xmin
handles.staircaseParams.amin = str2double(get(handles.aMinEditControl, 'String'));
%Calculate new xmax
handles.staircaseParams.amax = REPT_StaircaseParamMaxValue(handles.staircaseParams.amin, handles.staircaseParams.astep, handles.staircaseParams.alevels);
% Update xmax
set(handles.aMaxEditControl, 'String', num2str(handles.staircaseParams.amax));

% To store GUIdata
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function aMinEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aMinEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function xMinEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to xMinEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xMinEditControl as text
%        str2double(get(hObject,'String')) returns contents of xMinEditControl as a double

% Get updated xmin
handles.staircaseParams.xmin = str2double(get(handles.xMinEditControl, 'String'));
%Calculate new xmax
handles.staircaseParams.xmax = REPT_StaircaseParamMaxValue(handles.staircaseParams.xmin, handles.staircaseParams.xstep, handles.staircaseParams.xlevels);
% Update xmax
set(handles.xMaxEditControl, 'String', num2str(handles.staircaseParams.xmax));

% To store GUIdata
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function xMinEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xMinEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in OneClickStimulationCheckbox.
function OneClickStimulationCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to OneClickStimulationCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OneClickStimulationCheckbox

% disable 'Stimulate' button in case one-click stimulation mode is selected
if get(handles.OneClickStimulationCheckbox, 'Value') 
    set(handles.StimulatePushButton, 'Enable', 'Off');
else
    % Alternatively, enable 'Stimulate' button
    set(handles.StimulatePushButton, 'Enable', 'On');
end






function coilTemperatureEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to coilTemperatureEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of coilTemperatureEditControl as text
%        str2double(get(hObject,'String')) returns contents of coilTemperatureEditControl as a double


% --- Executes during object creation, after setting all properties.
function coilTemperatureEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coilTemperatureEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in TemperatureUpdatePushButton.
function TemperatureUpdatePushButton_Callback(hObject, eventdata, handles)
% hObject    handle to TemperatureUpdatePushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[success, temperature] = Rapid2_GetCoilTemperature(handles.serialPortObj);
if ~success
    display 'Cannot acquire coil temperature';
    return
else
    maxTemperature = max(temperature.coil1, temperature.coil2);
    set(handles.coilTemperatureEditControl, 'String', num2str(maxTemperature));
end



% --- Executes on button press in SpaceToTriggerCheckbox.
function SpaceToTriggerCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to SpaceToTriggerCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SpaceToTriggerCheckbox



function ParticipantNameEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to ParticipantNameEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParticipantNameEditControl as text
%        str2double(get(hObject,'String')) returns contents of ParticipantNameEditControl as a double

currentDir = pwd;
fileName = [get(handles.ParticipantNameEditControl, 'String'), '.txt'];
fullFileName = [currentDir, filesep, fileName];
text = ['Output file name: ', fullFileName];
set(handles.OutputFileNameTextbox, 'String', text);


% --- Executes during object creation, after setting all properties.
function ParticipantNameEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParticipantNameEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PulseDelayEditControl_Callback(hObject, eventdata, handles)
% hObject    handle to PulseDelayEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PulseDelayEditControl as text
%        str2double(get(hObject,'String')) returns contents of PulseDelayEditControl as a double


% --- Executes during object creation, after setting all properties.
function PulseDelayEditControl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PulseDelayEditControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
