function success = REPT_RunAdaptiveStaircase(minPowerLevel, maxPowerLevel, pulseDelay, spaceToTrigger, fullFileName, staircaseParams, serialPortObj)

% Adaptive staricase procedure based on Bayesian adaptive estimation of
% the threshold, to determine phosphene threshold. This procedure is intended to provide
% an automatic estimation of the phosphene threshold and replace the manual staircase
% procedure that has been in place.
%
% Reference: Bayesian adaptive estimation of psychometric slope and threshold
% Kontsevich LL & Tyler CW (1999) Vision Res 39, 2729-2737.
%
% --- Implementation
% Based on Psy adaptive staircase method implementation by Colin Clifford
% 15.10.08, Arman
% 23.10.08, Colin: adopted quick3 function for YES/NO paradigm which is being used for phosphene threshold identification
% 08.12.09, Arman: replace the function Delay with Rapid2_Delay which maintains communication with the stimulator
%                  while delaying, to prevent disarming the stimulator.
% 08.06.10, implemented estimating 50% threshold (default is 60% when using Weibull function).
%
%
% --- Input arguments
% minPowerLevel - minimum power level.
% maxPowerLevel - maximum power level.
% pulseDelay - delay between the pulses. It is recommended to set it to at
%              least 1 sec. 
% spaceToTrigger - if set to 1, wait for participant to press spacebar to
%                  deliver pulse
% fullFileName - name and path of the file where to store data
% staircaseParams - structure containing the following parameteres:
%            xlevels - parameter used in the adaptive staircase procedure
%            xstep - parameter used in the adaptive staircase procedure
%            xmin - parameter used in the adaptive staircase procedure
%            alevels - parameter used in the adaptive staircase procedure
%            astep - parameter used in the adaptive staircase procedure
%            amin - parameter used in the adaptive staircase procedure
%            blevels - parameter used in the adaptive staircase procedure
%            bstep - parameter used in the adaptive staircase procedure
%            bbase - parameter used in the adaptive staircase procedure
% serialPortObj - handle to serial port object
%
% --- Output arguments
% success - 0 if something goes wrong, 1 if the function execution succeeded
%
% --- Example
% success = REPT_RunAdaptiveStaircase(40, 70, staircaseParams, serialPortObj)

% --- Let's start
% If no input arguments specified, assign default values
% This will not work though because serial port object needs to be specified
% But nevertheless
if nargin < 6, [success, staircaseParams] = REPT_DefaultStaircaseParams; end
if nargin < 5, fullFileName = 'REPT_output.txt'; end
if nargin < 4, spaceToTrigger = 1; end
if nargin < 3, pulseDelay = 1; end
if nargin < 2, maxPowerLevel = 75; end
if nargin < 1, minPowerLevel = 45; end

% Define parameters
fixationCrossSize = 12;
blankAfterFixationInFrames = 16; % 106 ms delay after the offset of the fixation cross before presenting the stimulus
% Colour of the text
textColour = 150;

% Set power level to a minimum used in the staircase to avoid abrupt
% changes in setting the power level when starting the program, or else
% stimulator may get stalled
Rapid2_SetPowerLevel(serialPortObj, minPowerLevel, 1);
% used for calculating change in power level
previousPowerLevel = minPowerLevel;

% Because Screen function interferes with the execution of the callback
% function intended to maintain communication with the stimulator every
% 500 ms, we need to disarm the stimulator and
% then arm it once the Screen function has been initialised.
success = Rapid2_DisarmStimulator(serialPortObj);
if ~success
    display 'Cannot disarm the stimulator';
    return;
else
    display 'Stimulator is disarmed';
end

try
    success = 0;
    % --- Initilise graphics and psi function ---
    
    % if there is more than one screen (e.g. laptop connected to external monitor)
    % identify the number of active screens and present stimulus on a screen
    % with highest number, which is usually the external screen
    totalScreens = Screen('Screens');
    activeScreen = max(totalScreens);
    
    % Retrive colour values corresponding to black and white
    whiteColour = WhiteIndex(activeScreen);
    blackColour = BlackIndex(activeScreen);
    % Compute gray colour as middle value
    grayColour = (whiteColour + blackColour) / 2;
    
    % Get key values
    KbName('UnifyKeyNames');
    
    responseYesPhosphene = KbName('RightShift'); % Left "Shift" button
    responseNoPhosphene = KbName('LeftShift'); % Right "Shift" button
    spaceBar = kbName('Space'); % Spacebar
    escapeButton = KbName('Escape'); % Escape button
    
    yesKey = KbName('y'); %  "y" is yes
    noKey = KbName('n'); % "n" is no
    
    % Clean up any left over from previous runs
    Screen('CloseAll');
    
    % Open a window, paint the background black, and hide the mouse cursor
    window = Screen('OpenWindow', activeScreen, blackColour);
    HideCursor;
    
    %Get screen size
    screenSize = Screen('Rect', window);
    % Get refresh interval for Flip function
    refreshInterval = Screen('GetFlipInterval', window);
    % Create an offscreen window for displaying program messages. This offscreen window is not attached to any other window
    messageWindow = Screen(-1, 'OpenOffscreenWindow', blackColour);
    
    % Display message about initialising graphics (redundant but can be useful)
    Screen('DrawText', messageWindow, 'Initialising Graphics ... ', 20, 20, textColour);
    Screen('CopyWindow', messageWindow, window);
    Screen('Flip', window);
    Screen('DrawText', messageWindow, 'Initialising Graphics ... Done', 20, 20, textColour);
    Screen('CopyWindow', messageWindow, window);
    Screen('Flip', window);
        
    % Define the small fixation cross recangle
    fixationCrossRectangle = [screenSize(3)/2-fixationCrossSize/2 screenSize(4)/2-fixationCrossSize/2 screenSize(3)/2+fixationCrossSize/2 screenSize(4)/2+fixationCrossSize/2 ];
    
    % ----- Intialise Psi parameters -----
    Screen('DrawText', messageWindow, 'Initialising Psi Parameters ... ', 20, 100, textColour);
    Screen('CopyWindow', messageWindow, window);
    Screen('Flip', window);
    
    % Psi parameters ...
    num_psi = 1;
    numberOfTrials = 30;  % should be even number
    
    % NB fitting of Weibull (a.k.a. Quick) function with 4% lapse rate gives
    % threshold at 80.3% correct performance or 60.6% hit rate for Yes-No
    miss_rate = 0.04;
    
    xlevels = staircaseParams.xlevels;
    xstep = staircaseParams.xstep;
    xmin = staircaseParams.xmin;
    x = zeros(1,xlevels);
    x(1) = xmin;
    for i = 2:xlevels
        x(i) = x(i-1) * xstep;
    end
    
    % Generate array of power levels by rescaling
    % x from minPowerLevel to maxPowerLevel
    tmp = x - min(x)
    powerLevels = tmp / max(tmp);
    powerLevels = powerLevels * (maxPowerLevel - minPowerLevel);
    powerLevels = powerLevels + minPowerLevel;
    powerLevels = round(powerLevels)
    % plot(powerLevels);
    
    alevels = staircaseParams.alevels;
    astep = staircaseParams.astep;
    amin = staircaseParams.amin;
    
    blevels = staircaseParams.blevels;
    bstep = staircaseParams.bstep;
    bbase = staircaseParams.bbase;
    
    psi_counter = zeros(1,1);
    
    a = zeros(1,alevels);
    a(1) = amin;
    for i = 2:alevels
        a(i) = a(i-1) * astep;
    end
    
    b = zeros(1,blevels);
    b(1) = bbase;
    for i = 2:blevels
        b(i) = b(i-1) + bstep;
    end
    
    % set up values for the prior
    ptl = ones(alevels,blevels,num_psi);
    ptl = ptl./(alevels*blevels);   % uniform prior distribution
    
    % set up look-up table of conditional probabilities
    psuccess_lx = zeros(alevels,blevels,xlevels);
    
    for i = 1:alevels
        for j = 1:blevels
            %psuccess_lx(i,j,:) = 0.5*(1+logistic3([a(i) b(j) miss_rate],x)-miss_rate/2);
            %psuccess_lx(i,j,:) = 0.5*(1+Rapid2_Quick3([a(i) b(j) miss_rate],x));
            psuccess_lx(i,j,:) = Rapid2_Quick3([a(i) b(j) miss_rate],x);
        end
    end
    
    REPT_x = zeros(size(x));    % prob of success after next trial as fn of stim, x
    
    ptl_xsuccess = zeros(alevels,blevels,xlevels,num_psi);
    ptl_xfailure = zeros(alevels,blevels,xlevels,num_psi);
    
    resp_arr = zeros(1,num_psi);    % set up response array
    
    min_level = zeros(1,num_psi);
    
    a_hat = zeros(1,num_psi);
    a_err = zeros(1,num_psi);
    b_hat = zeros(1,num_psi);
    b_err = zeros(1,num_psi);
    
    Screen('DrawText', messageWindow, 'Initialising Psi Parameters ... Done', 20, 100, textColour);
    Screen('CopyWindow', messageWindow, window);
    Screen('Flip', window);
    
    % Arm the stimulator
    success = Rapid2_ArmStimulator(serialPortObj);
    if ~success
        display 'Cannot arm the stimulator';
        return;
    else
        display 'Stimulator is armed';
    end
    
    % Wait for any button press to start ...
    FlushEvents('keyDown')
    Screen('DrawText', messageWindow, 'Press Any Key to Continue', 20, 220, textColour);
    Screen('CopyWindow', messageWindow, window);
    Screen('Flip', window);
    KbPressWait;
    
    % Deactive coil safety switch
    success = Rapid2_IgnoreCoilSafetySwitch(serialPortObj);
    %
    if ~success
        display 'Cannot deactivate the coil safety switch';
        return;
    else
        display 'Coil safety switch is deactivated';
    end
    
    Screen('FillOval', window, grayColour, fixationCrossRectangle);
    flipOnsetTime = Screen('Flip', window);
    
    % Delay to ensure coil safety switch has been deactivated
    Rapid2_Delay(200, serialPortObj);
    
    
    % Change to a higher priority level to ensure more processing time
    % is allocated to Matlab to provide better code execution timing
    priorityLevel=MaxPriority(window);
    % Priority(priorityLevel);
    
    % --- Run adaptive staircase procedure
    numberOfStimuli = numberOfTrials*num_psi;
    responseArray = zeros(numberOfStimuli,3);
    psi_order = Shuffle(ceil([1:numberOfStimuli]./numberOfTrials));

    % Get time measurement to calculate procedure duration
    startTime = GetSecs();

    for t = 1:numberOfStimuli
        
        % randomly select which psi to present ...
        psi = psi_order(t);
        
        % 1. calculate conditional probability of response, r, given stimulus, x
        for k = 1:xlevels
            REPT_x(k) = sum(sum(ptl(:,:,psi).*psuccess_lx(:,:,k)));
        end
        
        % 2. use Bayes rule to estimate posterior prob of each psycho fn ...
        for k = 1:xlevels
            ptl_xsuccess(:,:,k,psi) = (ptl(:,:,psi).*psuccess_lx(:,:,k))./REPT_x(k);
            ptl_xfailure(:,:,k,psi) = (ptl(:,:,psi).*(1-psuccess_lx(:,:,k)))./(1-REPT_x(k));
        end
        
        % 3. estimate entropy of pdf as a fn of stim level and response
        for k = 1:xlevels
            HS(k) = -sum(sum(ptl_xsuccess(:,:,k,psi).*log(ptl_xsuccess(:,:,k,psi))));
            HF(k) = -sum(sum(ptl_xfailure(:,:,k,psi).*log(ptl_xfailure(:,:,k,psi))));
        end
        
        % 4. estimate expected entropy for each stim level
        for k = 1:xlevels
            EH(k) = HS(k).*REPT_x(k) + HF(k).*(1-REPT_x(k));
        end
        
        % 5. find stim level with minimum entropy
        [min_val, min_level(psi)] = min(EH);
        
        % 6. min_level(psi) & ...
        xMin = x(min_level(psi));
        stimulationLevel = powerLevels(min_level(psi));
        
        % Set stimulator's power level
        success = Rapid2_SetPowerLevel(serialPortObj, stimulationLevel, 1);
        
        % Introduce delay to allow time for the stimulator to adjust the new power level
        % 40 ms for each 1% of change of stimulator intensity
        powerLevelChange = abs(previousPowerLevel - stimulationLevel);
        delayInMs = powerLevelChange * 40;
        Rapid2_Delay(delayInMs, serialPortObj);
        
        beep;
        % Introduce delay after the beep to allow the subject to preapre
        % for the next pulse. The delay is specified in "Pulse Delay" edit
        % box on GUI
        Rapid2_Delay(pulseDelay * 1000, serialPortObj);
        
        Screen('FillOval', window, grayColour, fixationCrossRectangle);
        % next_Flip = GetSecs;
        flipOnsetTime = Screen('Flip', window);
        
        % Trigger the stimulator in fast mode
        success = Rapid2_TriggerPulse(serialPortObj, 1);
        
        previousPowerLevel = stimulationLevel;
        
        % Display No/Yes responses on the screen
        Screen('DrawText', window, 'No', 100, 700, textColour);
        Screen('DrawText', window, 'Yes', 870, 700, textColour);
        flipOnsetTime = Screen('Flip', window);

        % Collect response
        validResponse = 0;
        while ~validResponse
            [keyIsDown, keySecs,keyCode] = KbCheck;
            
            if keyIsDown
                if keyCode(responseYesPhosphene)
                    Response = 1;
                    % if whichInterval(t) == 1 ResponseCorrect = 1; else ResponseCorrect = 0; end
                    validResponse = 1;
                    
                elseif keyCode(responseNoPhosphene)
                    Response = 0;
                    % if whichInterval(t) == 2 ResponseCorrect = 1; else ResponseCorrect = 0; end
                    validResponse = 1;
                elseif keyCode(spaceBar)
                elseif keyCode(escapeButton)
                    
                    % break out of program when Escape button is pressed
                    validResponse = 1;
                    Screen('CloseAll');
                    warning on;
                    ShowCursor;
                    success = 0;
                    responseArray
                    return;
                    
                elseif keyIsDown
                    Screen('DrawText', window, 'Invalid Response Key. Try Again.', 400, 650, textColour);
                    flipOnsetTime = Screen('Flip', window);
                    Screen('Flip', window, flipOnsetTime + 5 * refreshInterval);
                    
                end
            end % if keyIsDown
            
        end % while validResponse
        
        % 7. keep the posterior pdf that corresponds to the completed trial
        if (Response)
            ptl(:,:,psi) = ptl_xsuccess(:,:,min_level(psi),psi);
        else
            ptl(:,:,psi) = ptl_xfailure(:,:,min_level(psi),psi);
        end
        
        % write stimulus & response details to responseArray ...
        responseArray(t,:) = [xMin, stimulationLevel, Response];
        
        validResponse = 0;
        % wait for the Spacebar, if specified
        if spaceToTrigger
            Screen('DrawText', window, 'Spacebar to trigger', 400, 650, textColour);
            flipOnsetTime = Screen('Flip', window);
            % Screen('Flip', window, flipOnsetTime + 30 * refreshInterval);
            
            while ~validResponse
                [keyIsDown, keySecs,keyCode] = KbCheck;
                if keyIsDown
                    if keyCode(spaceBar)
                        Screen('FillOval', window, grayColour, fixationCrossRectangle);
                        % next_Flip = GetSecs;
                        flipOnsetTime = Screen('Flip', window);
                        validResponse = 1;
                    elseif keyCode(escapeButton)
                        % break out of program when Escape button is pressed
                        validResponse = 1;
                        Screen('CloseAll');
                        warning on;
                        ShowCursor;
                        responseArray
                        success = 0;
                        return;    
                    end
                end % if keyIsDown
            end % while validResponse
        else
            Screen('FillOval', window, grayColour, fixationCrossRectangle);
            % next_Flip = GetSecs;
            flipOnsetTime = Screen('Flip', window);
        end
        
    end  % end of stuff done every trial
    
    % 8. Find new estimate of psychometric function
    for psi=1:num_psi
        a_hat(psi) = sum(a*ptl(:,:,psi));
        b_hat(psi) = sum(b*ptl(:,:,psi)');
        
        a_mean = ones(size(a)).*a_hat(psi);
        b_mean = ones(size(b)).*b_hat(psi);
        
        a_err(psi) = sqrt(sum(((a-a_mean).^2)*ptl(:,:,psi)));
        b_err(psi) = sqrt(sum(((b-b_mean).^2)*ptl(:,:,psi)'));     % standard error
    end
    
    responseArray;
    %a_hat
    %a_err
    
    % b_hat
    % Calculate duration of the procedure
    duration = GetSecs() - startTime;
    disp ' ';
    disp(['Duration = ', num2str(duration), ' sec']);
    
    % Calculate phosphene threshold
    % The default estimated threshold is 60%  when
    % using the Weibull function (with 0.04 miss rate)
    tmp = a_hat - min(a); % center at 0
    tmp = tmp / max(a - min(a)); % normalise from 0 to 1
    phospheneThreshold60 = tmp * (maxPowerLevel - minPowerLevel);
    phospheneThreshold60 = phospheneThreshold60 + minPowerLevel;
    phospheneThreshold60 = round(phospheneThreshold60);
    disp(['Phospene threshold(at 60%) = ', num2str(phospheneThreshold60), '% of stimulator output']);
    
    % Calculate 50% phosphene threshold.
    % We can do this using inverse Weibull function using alpha
    % (threshold) and beta (slope) calculated above
    tmp1 = 1 - (0.5 / (1 - miss_rate));  % calculate a part of the Weibull inverse equation
    a_hat_50 = a_hat * ((-log(tmp1))^(1 / b_hat));  % the rest of Weibull inverse
    tmp = a_hat_50 - min(a); % center at 0
    tmp = tmp / max(a - min(a)); % normalise from 0 to 1
    phospheneThreshold50 = tmp * (maxPowerLevel - minPowerLevel);
    phospheneThreshold50 = phospheneThreshold50 + minPowerLevel;
    phospheneThreshold50 = round(phospheneThreshold50);
    disp(['Phospene threshold(at 50%) = ', num2str(phospheneThreshold50), '% of stimulator output'])
    
    thresholds = [phospheneThreshold60, phospheneThreshold50];
    
    % Tidy up responses for saving into a file
    responses = responseArray(:, 2:3);
    % Add trials numbers
    trialNumbers = transpose(1:numberOfTrials);
    responses = [trialNumbers, responses]
    
    % Save data into a file
    REPT_SaveData(fullFileName, responses, thresholds, duration);
    
    % Finish and return to the command window
    ShowCursor;
    Screen('CloseAll');
    success =1;
    
catch
    % In the case of an error in the try block, let's activate the
    % cursor and close all windows to let the user enjoy the familiar
    % Matlab prompt
    Priority(0);
    ShowCursor;
    Screen('CloseAll');
    psychrethrow(psychlasterror);
    success = 0;
end %try..catch






