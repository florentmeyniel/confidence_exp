% Scrip to test if the button work correctly.

% =========================================================================
%                               INITIALIZATION
% =========================================================================

clear all; close all;
tic;
addpath subfunctions

% --- SETTINGS ---
% ################
define_parameters

% --- COMPLETE SETTINGS ---
% #########################

AssertOpenGL;
PsychDefaultSetup(2);

% Open a window for display
if isunix && strcmp(getenv('USER'), 'meyniel') % for my Linux HP
    [w_px, h_px] = Screen('WindowSize', 0);
    if fullscreen == 1
        % NB: this is similar to Niklas' code
        [window, windowRect] = PsychImaging('OpenWindow', 0, bg, [], 32, 2, [], [],  kPsychNeed32BPCFloat);
        HideCursor
    else
        [window, windowRect] = PsychImaging('OpenWindow', 0, bg, [1 1 1+round(0.33*w_px) 1+round(0.5*h_px)]);
    end
    w_px = windowRect(3);
    h_px = windowRect(4);
elseif isunix && strcmp(getenv('USER'), 'fm239804') % for Z800 computer
    [w_px, h_px] = Screen('WindowSize', 0);
    if fullscreen == 1
        % NB: this is similar to Niklas' code
        [window, windowRect] = PsychImaging('OpenWindow', 0, bg, [], 32, 2, [], [],  kPsychNeed32BPCFloat);
        HideCursor
    else
        [window, windowRect] = PsychImaging('OpenWindow', 0, bg, [1 1 1+0.4*w_px 1+0.7*h_px]);
    end
    w_px = windowRect(3);
    h_px = windowRect(4);
else
    [w_px, h_px] = Screen('WindowSize', 0);
    if fullscreen == 1
        % NB: this is similar to Niklas' code
        [window, windowRect] = PsychImaging('OpenWindow', 0, bg, [], 32, 2, [], [],  kPsychNeed32BPCFloat);
        HideCursor
    else
        [window, windowRect] = PsychImaging('OpenWindow', 0, bg, [1 1 1+0.5*w_px 1+0.5*h_px]);
    end
    w_px = windowRect(3);
    h_px = windowRect(4);
end

% get screen center coordinates
crossY = 1/2*h_px;
crossX = 1/2*w_px;

% Make a back up of the current clut table (to restore it at the end)
LoadIdentityClut(window);
load(gamma_lookup_table)
Screen('LoadNormalizedGammaTable', window, mygammatable);

Screen('Flip', window);

% Maximum priority level
topPriorityLevel = MaxPriority(window);

% Set font
Screen('TextSize', window, 21);
Screen('TextFont', window, 'Mono');

% Set key code
get_key_code

% --- CONFIDENCE RATING ---
% #########################
exittask = 0;
while ~exittask

    % Plot 
    text = '       Test des boutons de reponse                 ';
    [w, h] = RectSize(Screen('TextBounds', window, text));
    Screen('DrawText', window, text, ceil(crossX-w/2), ceil(crossY-h*2.5), colText);
    text1 = '            [ ]  [ ]  [ ]  [ ]                    ';
    text2 = 'selection:   G    G    D    D    (Gauche / Droite)';
    text3 = 'confiance:  haut bas  bas  haut                   ';
    [w, h] = RectSize(Screen('TextBounds', window, text1));
    Screen('DrawText', window, text1, ceil(crossX-w/2), ceil(crossY-h/2), colText);
    [w, h] = RectSize(Screen('TextBounds', window, text2));
    Screen('DrawText', window, text2, ceil(crossX-w/2), ceil(crossY-h/2 + 30), colText);
    [w, h] = RectSize(Screen('TextBounds', window, text3));
    Screen('DrawText', window, text3, ceil(crossX-w/2), ceil(crossY-h/2 + 50), colText);
    Screen(window,'Flip');
    
    % wait for answer
    isValidated = 0;
    while ~exittask && ~isValidated
        
        % Get subject responses
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown
           if keyCode(KbName('ESCAPE')); % press escape to quit the experiment
                exittask = 1;
            elseif keyCode(resp_L_conf_H);
                isValidated = 1; SConfLevel = 2; STargetPos = 1;
            elseif keyCode(resp_L_conf_L);
                isValidated = 1; SConfLevel = 1; STargetPos = 1;
            elseif keyCode(resp_R_conf_L);
                isValidated = 1; SConfLevel = 1; STargetPos = 2;
            elseif keyCode(resp_R_conf_H);
                isValidated = 1; SConfLevel = 2; STargetPos = 2;
            end
        end
    end
    
    if exittask
        break
    end
    
    % DISPLAY CONFIDENCE RESPONSE
    % Plot Confidence choice
    text = '       Test des boutons de reponse                 ';
    [w, h] = RectSize(Screen('TextBounds', window, text));
    Screen('DrawText', window, text, ceil(crossX-w/2), ceil(crossY-h*2.5), colText);
    if      STargetPos == 1 && SConfLevel == 2; text1 = '            [X]  [ ]  [ ]  [ ]                    ';
    elseif  STargetPos == 1 && SConfLevel == 1; text1 = '            [ ]  [X]  [ ]  [ ]                    ';
    elseif  STargetPos == 2 && SConfLevel == 1; text1 = '            [ ]  [ ]  [X]  [ ]                    ';
    elseif  STargetPos == 2 && SConfLevel == 2; text1 = '            [ ]  [ ]  [ ]  [X]                    ';
    end
    text2 = 'selection:   G    G    D    D    (Gauche / Droite)';
    text3 = 'confiance:  haut bas  bas  haut                   ';
    [w, h] = RectSize(Screen('TextBounds', window, text1));
    Screen('DrawText', window, text1, ceil(crossX-w/2), ceil(crossY-h/2), colText);
    [w, h] = RectSize(Screen('TextBounds', window, text2));
    Screen('DrawText', window, text2, ceil(crossX-w/2), ceil(crossY-h/2 + 30), colText);
    [w, h] = RectSize(Screen('TextBounds', window, text3));
    Screen('DrawText', window, text3, ceil(crossX-w/2), ceil(crossY-h/2 + 50), colText);
    Screen(window,'Flip');
    WaitSecs(0.4);  
end

% Clean up for exit
WaitSecs(0.2)
text = 'Closing...';
[w, h] = RectSize(Screen('TextBounds', window, text));
Screen('DrawText', window, text, ceil(crossX-w/2), ceil(crossY-h/2), colText);
Screen(window,'Flip');
WaitSecs(0.2)
sca                                 % close PTB window
