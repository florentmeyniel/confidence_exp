function [correct, response, confidence, rt_choice, timing] = one_trial(window, windowRect, screen_number, is_left_gabor_max, gabortex, gabor_dim_pix, variable_arguments)
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
% ypos : array of two y positions for the two gabors
% driftspeed : how fast the gabors drift (units not clear yet)
% gabor_angle : orientation of the two gabors
% duration : how long each contrast level is shown in seconds
% baseline_delay : delay between trial start and stimulus onset.
% feedback_delay : delay between confidence response and feedback onset
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
IsfMRI = default_arguments(variable_arguments, 'IsfMRI'); 
x_excentricity = default_arguments(variable_arguments, 'x_excentricity'); 


sigma = default_arguments(variable_arguments, 'sigma', gabor_dim_pix/6);
contrast_samples1 = default_arguments(variable_arguments, 'contrast_samples1');
contrast_samples2 = default_arguments(variable_arguments, 'contrast_samples2');

num_cycles = default_arguments(variable_arguments, 'num_cycles');
ypos = default_arguments(variable_arguments, 'ypos');
driftspeed = default_arguments(variable_arguments, 'driftspeed');
gabor_angle = default_arguments(variable_arguments, 'gabor_angle', 180);
dist2screen = default_arguments(variable_arguments, 'dist2screen');
ScreenSize = default_arguments(variable_arguments, 'ScreenSize');
ppd = estimate_pixels_per_degree(screen_number, dist2screen, IsfMRI, ScreenSize);

duration = default_arguments(variable_arguments, 'duration');
baseline_delay = default_arguments(variable_arguments, 'baseline_delay');
decision_delay = default_arguments(variable_arguments, 'decision_delay');
feedback_delay = default_arguments(variable_arguments, 'feedback_delay');
response_duration = default_arguments(variable_arguments, 'response_duration');
delay_before_fb = default_arguments(variable_arguments, 'delay_before_fb');

eyetracker = default_arguments(variable_arguments, 'eyetracker');

reference_contrast = default_arguments(variable_arguments, 'reference_contrast');

bg = default_arguments(variable_arguments, 'bg');
fix = default_arguments(variable_arguments, 'fix');

%% Setting the stage
timing = struct();

% get the key code (define in a script)
get_key_code

black = BlackIndex(screen_number);
ResponseDotColor=[.25 .25 .25 1];

% Properties of the gabor
ifi = Screen('GetFlipInterval', window);
freq = num_cycles / gabor_dim_pix;
xpos1 = -x_excentricity*ppd;
xpos2 = x_excentricity*ppd;
ypos = ypos*ppd;
[xCenter, yCenter] = RectCenter(windowRect);
xpos1 = xpos1 + xCenter;
xpos2 = xpos2 + xCenter;
ypos = ypos + yCenter;
baseRect = [0 0 gabor_dim_pix gabor_dim_pix];
allRects1 = CenterRectOnPointd(baseRect, xpos1, ypos)';
allRects2 = CenterRectOnPointd(baseRect, xpos2, ypos)';
degPerSec = 360 * driftspeed;
degPerFrame =  degPerSec * ifi;
gaborAngles = gabor_angle;
propertiesMat1 = [0, freq, sigma, reference_contrast, 1, 0, 0, 0];
propertiesMat2 = [0, freq, sigma, reference_contrast, 1, 0, 0, 0];


%% Baseline Delay period
% Draw the fixation point
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('FillOval', window, black, fix.pos);
Screen('FillOval', window, bg, fix.posin);

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

while ~((GetSecs - stimulus_onset) >= (length(contrast_samples1)*duration-1*ifi))
    
    % Set the right blend function for drawing the gabors
    Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
    
    % Batch draw all of the Gabors to screen
    Screen('DrawTextures', window, gabortex, [], allRects1, gaborAngles - 90,...
        [], [], [], [], kPsychDontDoRotation, propertiesMat1');
    
    Screen('DrawTextures', window, gabortex, [], allRects2, gaborAngles - 90,...
        [], [], [], [], kPsychDontDoRotation, propertiesMat2');
    
    
    % Change the blend function to draw an antialiased fixation point
    % in the centre of the array
    % Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Draw the fixation point
    Screen('FillOval', window, black, fix.pos);
    Screen('FillOval', window, bg, fix.posin);
    
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
        % Gabor 1 (left)
        propertiesMat1(:,4) = contrast_samples1(cnt);
        
        % Gabor 2 (right)
        propertiesMat2(:,4) = contrast_samples2(cnt);
        
        start = GetSecs;
        cnt = cnt+1;
    end
    
    % Increment the phase of our Gabors
    propertiesMat1(:, 1) =  propertiesMat1(:, 1) + degPerFrame;
    propertiesMat2(:, 1) =  propertiesMat2(:, 1) + degPerFrame;
    
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

% return to empty screen
Screen('FillOval', window, black, fix.pos);
Screen('FillOval', window, bg, fix.posin);
vbl = Screen('Flip', window, vbl + (1 - 0.5) * ifi);


%% response phase

% wait some time before the subject is asked to provide an answer
Screen('FillOval', window, ResponseDotColor, fix.pos);
Screen('FillOval', window, bg, fix.posin);
vbl = Screen('Flip', window, vbl + (floor(decision_delay/ifi)-0.5)*ifi);
timing.response_cue = vbl;

if  strcmp(eyetracker,'y')
    Eyelink('Message', 'response_cue');
end

start = GetSecs;
rt_choice = nan;
key_pressed = false;
while (GetSecs-start) < response_duration
    [tmp, RT, keyCode] = KbCheck;
    if keyCode(quit)
        throw(MException('EXP:Quit', 'User request quit'));
    end
    if keyCode(resp_L_conf_H) || keyCode(resp_L_conf_L) ...
            || keyCode(resp_R_conf_L) || keyCode(resp_R_conf_H)
        
        % get response type: Left / right
        if keyCode(resp_L_conf_H) || keyCode(resp_L_conf_L)
            response = 1;
        else
            response = 0;
        end
        
        % estimate if correct or not
        if is_left_gabor_max == response
            correct = 1;
        else
            correct = 0;
        end
        
        % get confidence level
        if keyCode(resp_L_conf_H) || keyCode(resp_R_conf_H)
            confidence = 1;
        else
            confidence = 0;
        end
        
        % get response time
        rt_choice = RT-start;
        key_pressed = true;
        break;
    end
end
if ~key_pressed
    Screen('FillOval', window, black, fix.pos);
    Screen('FillOval', window, bg, fix.posin);

    vbl = Screen('Flip', window);
    wait_period = delay_before_fb + feedback_delay;
    WaitSecs(wait_period);
    correct = nan;
    response = nan;
    confidence = nan;
    rt_choice = nan;
    return
end

% turn fixation dot to white when the answer is provided
Screen('FillOval', window, [.75 .75 .75], fix.pos);
Screen('FillOval', window, bg, fix.posin);

vbl = Screen('Flip', window);

%% Provide Feedback

% display feedback after a delay period
if correct
    Screen('FillOval', window, [0 0.5 0], fix.pos);
    Screen('FillOval', window, bg, fix.posin);

else
    Screen('FillOval', window, [1 0 0], fix.pos);
    Screen('FillOval', window, bg, fix.posin);

end
vbl = Screen('Flip', window, vbl + (floor(delay_before_fb/ifi)-0.5)*ifi);
timing.feedback= vbl;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'feedback');
end

% remove feedback
Screen('FillOval', window, black, fix.pos);
Screen('FillOval', window, bg, fix.posin);

vbl = Screen('Flip', window, vbl + (floor(feedback_delay/ifi)-0.5)*ifi);
timing.feedback_end = vbl;
if  strcmp(eyetracker,'y')
    Eyelink('Message', 'feedback_end');
end

if  strcmp(eyetracker,'y')
    Eyelink('Message', 'trial_end');
end
