function [correct, response, confidence, rt_choice, rt_conf, timing] = one_trial(window, windowRect, screen_number, is_left_gabor_max, gabortex, gabor_dim_pix, variable_arguments)
%% function [correct, response, confidence, rt_choice, rt_conf] = one_trial(window, windowRect, screen_number, is_left_gabor_max, gabortex, gaborDimPix, variable_arguments)
%
% Presents two Gabor patches that vary in contrast over time and then asks
% for which one of the two had higher contrast and the confidence of the
% decision.
%
% Parameters
% ----------
%
% window : window handle to draw into
% windowRect : dimension of the window
% screen_number : which screen to use
% is_left_gabor_max : 1 if correct (max contrast) is left, 0 if right
% gabortex : the gabor texture to draw
% gabor_dim_pix : size of the gabor grating in px.
%
% Variable Arguments
% ------------------
%
% sigma : sigma of the gaussian for the gabor patch
% contrast_left : array of michelson contrast values for left gabor
% contrast_right : array of michelson contrast values for right gabor
% num_cycles : spatial frequency of the gabor
% xpos : array of two x positions for the two gabors
% ypos : array of two y positions for the two gabors
% driftspeed : how fast the gabors drift (units not clear yet)
% gabor_angle : orientation of the two gabors
% ppd : pixels per degree to convert to visual angles
% duration : how long each contrast level is shown in seconds
% baseline_delay : delay between trial start and stimulus onset.
% confidence_delay : delay between decision response and confidence cue
% feedback_delay : delay between confidence response and feedback onset
% rest_delay : delay between feedback onset and trial end
%
%
% A note about contrast. The gabor is created with a procedural texture
% where disablenorm is True, contrastpremult is 0.5 and the background is
% 0.5. The amplitude of the gabor is then given by
%   amp = cpre * con
% The max and min of the Gabor are therefore
%   max, min = ampl +- BG
% The Michelson contrast is then given by
%       (BG + cpre * con) - (BG - cpre * con)    2*cpre*con
%  MC = ------------------------------------- =  ---------- = con [cpre = BG]
%       (BG + cpre * con) + (BG - cpre * con)       2*BG
%  Which is to say that the contrast parameter gives the Michelson contrast
%  with the current contrastpremult and background settings.

%% Process variable input stuff
IsfMRI = default_arguments(variable_arguments, 'IsfMRI', 0); 
x_excentricity = default_arguments(variable_arguments, 'x_excentricity', nan); 

sigma = default_arguments(variable_arguments, 'sigma', gabor_dim_pix/6);
contrast_samples = default_arguments(variable_arguments, 'contrast_samples', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]/10.);
num_cycles = default_arguments(variable_arguments, 'num_cycles', 5);
ypos = default_arguments(variable_arguments, 'ypos', [0]);
driftspeed = default_arguments(variable_arguments, 'driftspeed', 1);
gabor_angle = default_arguments(variable_arguments, 'gabor_angle', 180);
ppd = default_arguments(variable_arguments, 'ppd', estimate_pixels_per_degree(screen_number, 60, IsfMRI));
duration = default_arguments(variable_arguments, 'duration', .1);
baseline_delay = default_arguments(variable_arguments, 'baseline_delay', 0.5);
decision_delay = default_arguments(variable_arguments, 'decision_delay', 0.30);
feedback_delay = default_arguments(variable_arguments, 'feedback_delay', 0.5);
rest_delay = default_arguments(variable_arguments, 'rest_delay', 0.5);
eyetracker = default_arguments(variable_arguments, 'eyetracker', 'n');

reference_contrast = default_arguments(variable_arguments, 'reference_contrast', 0.5);
reference_gabor_angle = default_arguments(variable_arguments, 'reference_gabor_angle', 180);
reference_dur = default_arguments(variable_arguments, 'reference_dur', .4);
inter_dur = default_arguments(variable_arguments, 'inter_dur', .5);


%% Setting the stage
% beeps = {MakeBeep(150, .25), MakeBeep(350, .25)};
timing = struct();
% left_key = KbName('LeftArrow');
% right_key = KbName('RightArrow');

% get the key code (define in a script)
get_key_code

black = BlackIndex(screen_number);
ResponseDotColor=[.25 .25 .25 1];

% Properties of the gabor
ifi = Screen('GetFlipInterval', window);
freq = num_cycles / gabor_dim_pix;
xpos = x_excentricity*ppd;
ypos = ypos*ppd;
[xCenter, yCenter] = RectCenter(windowRect);
xpos = xpos + xCenter;
ypos = ypos + yCenter;
ngabors = numel(xpos);
baseRect = [0 0 gabor_dim_pix gabor_dim_pix];
allRects = nan(4, ngabors);
for i = 1:ngabors
    allRects(:, i) = CenterRectOnPointd(baseRect, xpos(i), ypos(i));
end
degPerSec = 360 * driftspeed;
degPerFrame =  degPerSec * ifi;
gaborAngles = gabor_angle*ones(1, ngabors);
propertiesMat = repmat([NaN, freq, sigma, 0, 1, 0, 0, 0],...
    ngabors, 1);
propertiesMat(:, 1) = 0;
propertiesMat(:, 4) = [reference_contrast];


%% Baseline Delay period
% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window);
timing.TrialOnset = vbl;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'TrialOnset');
end
vbl=WaitSecs(baseline_delay);

%% Animation loop
timing.AnimationOnset = vbl;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'AnimationOnset');
end
start = nan;
cnt = 1;
dynamic = [];
stimulus_onset = nan;

while ~((GetSecs - stimulus_onset) >= (length(contrast_samples)*duration-1*ifi))
    
    % Set the right blend function for drawing the gabors
    Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
%    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Batch draw all of the Gabors to screen
    Screen('DrawTextures', window, gabortex, [], allRects, gaborAngles - 90,...
        [], [], [], [], kPsychDontDoRotation, propertiesMat');
    
    % Change the blend function to draw an antialiased fixation point
    % in the centre of the array
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Draw the fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);   
    
    % Flip our drawing to the screen
    waitframes = 1;
    vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);    
    dynamic = [dynamic vbl];
    % Change contrast every 100ms
    elapsed = GetSecs;
    if isnan(start)
        stimulus_onset = GetSecs;
        start = GetSecs;
    end
    if (elapsed-start) > duration
        val = contrast_samples(1 + mod(cnt, length(contrast_samples)));
        propertiesMat(:,4) = val;
        start = GetSecs;
        cnt = cnt+1;
    end
    
    % Increment the phase of our Gabors
    propertiesMat(:, 1) =  propertiesMat(:, 1) + degPerFrame;
    
%       %to save an image of one patch
%     if cnt==1
%         imageArray=Screen('GetImage', window);
%         assignin('base','imageArray',imageArray)
%         'Save one image in base'
%     end

    
end
% in the centre of the array
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
timing.animation = dynamic;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'animationEnd');
end

%% Wait for some time after stimulus, before response
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window, vbl + (1 - 0.5) * ifi);
WaitSecs(decision_delay);

%%% Get choice [left_arrow|right_arrow]
% Draw the fixation pointsca


Screen('DrawDots', window, [xCenter; yCenter], 10, ResponseDotColor, [], 1);
vbl = Screen('Flip', window, vbl + (1 - 0.5) * ifi);
timing.response_cue = vbl;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'response_cue');
end
start = GetSecs;
rt_choice = nan;
key_pressed = false;
while (GetSecs-start) < 2
    [tmp, RT, keyCode] = KbCheck;
    if keyCode(quit)
        throw(MException('EXP:Quit', 'User request quit'));
    end
    if keyCode(left_resp) || keyCode(right_resp)
        if keyCode(left_resp)
            response = 1;
        else
            response = 0;
        end
        if is_left_gabor_max == response
            correct = 1;
        else
            correct = 0;
        end
        rt_choice = RT-start;
        key_pressed = true;
        break;
    end
end
if ~key_pressed
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
    vbl = Screen('Flip', window);
    wait_period = 1 + feedback_delay + rest_delay;
    WaitSecs(wait_period);
    correct = nan;
    response = nan;
    confidence = nan;
    rt_choice = nan;
    rt_conf = nan;
    return
end

%flash the fix dot for a fraction of second (100ms)
Screen('DrawDots', window, [xCenter; yCenter], 10, [.75 .75 .75], [], 1);
vbl = Screen('Flip', window);
%the dot again in the center
Screen('DrawDots', window, [xCenter; yCenter], 10, ResponseDotColor, [], 1);

%draw the correct response
% Screen('DrawText', window, num2str(correct_location),xCenter+100,yCenter);%[,x] [,y] [,color] [,backgroundColor] [,yPositionIsBaseline] [,swapTextDirection]);

waitframes = .1/ifi;%100ms
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);

%% Get confidence response [a|s|d|f]
key_pressed = false;
timing.start_confidence_delay = vbl;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'start_confidence_delay');
end

% waitframes = confidence_delay/ifi;
% Screen('DrawDots', window, [xCenter; yCenter], 10, ResponseDotColor, [], 1);
% vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
% timing.confidence_cue = vbl;
start = GetSecs;
rt_conf = nan;
while (GetSecs-start) < 2
    [tmp, RT, keyCode] = KbCheck;
    if keyCode(conf_very_high) || keyCode(conf_high) || keyCode(conf_very_low) || keyCode(conf_low)
        key_pressed = true;
        if keyCode(conf_very_high)
            confidence = 2;
        elseif keyCode(conf_high)
            confidence = 1;
        elseif keyCode(conf_low)
            confidence = -1;
        elseif keyCode(conf_very_low)            
            confidence = -2;
        end
        rt_conf = RT-start;
        break;
    end
end
if ~key_pressed
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
    vbl = Screen('Flip', window);    
    wait_period = 0.5 + feedback_delay + rest_delay;
    WaitSecs(wait_period);
    confidence = nan;
    rt_conf = nan;
    return
end
% Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
% vbl = Screen('Flip', window);


%% Provide Feedback

if correct
    Screen('DrawDots', window, [xCenter; yCenter], 10, [0 .5 0 1], [], 1);
else
    Screen('DrawDots', window, [xCenter; yCenter], 10, [1 0 0 1], [], 1);
end
vbl = Screen('Flip', window);
timing.feedback= vbl;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'feedback');
end
waitframes = (feedback_delay/ifi) - 2;

Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
timing.feedback_end = vbl;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'feedback_end');
end

% timing.feedback_start = t1;

%% Rest delay
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
waitframes = rest_delay/ifi;
vbl = Screen('Flip', window, (waitframes - 0.5) * ifi);
timing.trial_end = vbl;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'trial_end');
end
