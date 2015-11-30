%% Confidence experiment
%
% Runs one session of the confidence experiment.
%

%% Global parameters.

% Initialize random generators (and use a workaround when rng is not
% re-cognized, e.g. by Octave)
try
    rng('shuffle')
catch
    rand('twister',sum(100*clock))
end

clear all
tic

% open the diary
diary('mylog.txt')
diary on

% define parameters (stored in a separate script)
define_parameters

% Define the IsOctave command if run in Matlab
try IsOctave
catch
    IsOctave = 0;
end

%% Ask for some subject details and load old QUEST parameters

if IsfMRI == 1
    fprintf('\n fMRI setting enabled\n')
else
    fprintf('\n fMRI setting disabled\n')
end

% get subject name and create a specific directory
initials = input('Initials? ', 's');
datadir = fullfile(datadir, initials);
mkdir(datadir);

% try to load a previous QUEST structure, otherwise initialize it
quest_file = fullfile(datadir, 'quest_results.mat');
session_struct = struct('q', [], 'results', [], 'date', datestr(clock));
results_struct = session_struct;
session_number=1;

% ask whether to append data if a previous structure is found
append_data = false;
if exist(quest_file, 'file') == 2
    if strcmp(input('There is previous data for this subject. Load last QUEST parameters? [y/n] ', 's'), 'y')
        [tmp, results_struct, threshold_guess, threshold_guess_sigma] = load_subject(quest_file);
        append_data = true;
        session_number=1+length(results_struct);
    end
end
fprintf('Session number: %d\n', session_number)

eye_filename=sprintf('%s_%03d',initials,session_number);
fprintf('Eye_filename: %s\n', eye_filename)

% get number of trial
if session_number == 1
    num_trials_this_sess = num_trials(1);
else
    num_trials_this_sess = num_trials(2);
end

% get total duration
if session_number == 1
    n_tmp = 1;
else
    n_tmp = 2;
end
tot_dur = num_trials(n_tmp) * ...
    (dur.bl + (dur.each_frame-0.005)*NumOfFrame + ...
    dur.decision + dur.response + ...
    dur.bef_fb(n_tmp) + dur.fb + dur.ITI(n_tmp));
tot_dur_min_s_text = sprintf('%2.0f min %2.0f s', floor(tot_dur/60),(tot_dur/60 - floor(tot_dur/60))*60);

% check if everything is correct
fprintf('\n N trial: %d \n total dur: %d s (%s) <=> %d TR\n\n', ...
    num_trials_this_sess, round(tot_dur), tot_dur_min_s_text, ceil(tot_dur/2))
fprintf('QUEST Parameters\n----------------\nThreshold Guess: %1.4f\nSigma Guess: %1.4f\n', ...
    threshold_guess, threshold_guess_sigma)
if ~strcmp(input('OK? [y/n] ', 's'), 'y')
    return;
    
end

% Initialize eye
if strcmp(eyetracker,'y')
    PARAMS      = struct('calBACKGROUND', 128,'calFOREGROUND',0);
    edfFile = eyelink_ini(eye_filename,PARAMS);
    sca;
end

%% ---SETUP SCREEN AND QUEST---
% #############################

AssertOpenGL;
PsychDefaultSetup(2);

screenNumber = max(Screen('Screens'));

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

% Compute position of the fixation dot
fix.pos = CenterRectOnPoint([0 0 fix.w fix.w], crossX, crossY);
fix.posin = CenterRectOnPoint([0 0 fix.in fix.in], crossX, crossY);

% compute size of the gabor in px
ppd = estimate_pixels_per_degree(window, dist2screen, ScreenSize);
fprintf('\n\n ppd = %5.5f \n\n', ppd)
gabor_dim_pix = round(gabor_dim_deg*ppd);

% Make a back up of the current clut table (to restore it at the end)
LoadIdentityClut(window);
load(gamma_lookup_table)
Screen('LoadNormalizedGammaTable', window, mygammatable);

Screen('Flip', window);

% Make gabortexture
gabortex = make_gabor(window, 'gabor_dim_pix', gabor_dim_pix, 'bgcolor', [bg*ones(1,3), 0]);

% Maximum priority level
topPriorityLevel = MaxPriority(window);

% Set font
Screen('TextSize', window, 21);
Screen('TextFont', window, 'Arial');

% Initialize screen BEFORE making texture (otherwise, it does not work...)
text = '...';
[w, h] = RectSize(Screen('TextBounds', window, text));
Screen('DrawText', window, text, round(crossX-w/2), round(crossY-h*3/2), colText);
Screen(window,'Flip');

% Set up QUEST
q = QuestCreate(threshold_guess, threshold_guess_sigma, pThreshold, beta, delta, gamma);
q.updatePdf = 1;

% A structure to save results.
results = struct(...
    'response', [], ...
    'is_left_gabor_max', [], ...
    'choice_rt', [], ...
    'correct', [], ...
    'diff_cont', [], ...
    'contrast_samples1', [], ...
    'contrast_samples2', [], ...
    'contrast1', [], ...
    'contrast2', [], ...
    'confidence', [], ...
    'timings', [], ...
    'trial_options_struct',[]);
timings = {};

% randomize the position of the most contrasted gabor
is_left_gabor_max = [ones(1, floor(num_trials_this_sess/2)), zeros(1, ceil(num_trials_this_sess/2))];
is_left_gabor_max = is_left_gabor_max(randperm(num_trials_this_sess));
is_left_gabor_max = logical(is_left_gabor_max);

%% ---WAIT START SIGNAL---
% ########################
exittask = 0;

% ready to start screen
Screen(window, 'Flip');
text = 'PRET';
[w, h] = RectSize(Screen('TextBounds', window, text));
Screen('DrawText', window, text, ceil(crossX-w/2), ceil(crossY-h/2), colText);
Screen(window,'Flip');
get_key_code
if IsfMRI
    % The start signal is the scanner trigger
    ScanCount = 0;
    fprintf('\n Waiting for the scanner triggers...')
    while true
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown && keyCode(KbName('ESCAPE')); % press escape to quit the experiment
            exittask = 1;
            break
        end
        
        if isKeyDown && keyCode(key_scanOnset);
            % key_scanOnset is sent when the 1st slice of a new volume in
            % aquiered.
            ScanCount = ScanCount+1;
            fprintf('\n dummy scan %d started', ScanCount)
            if ScanCount == 1
                fprintf(' defined at T0')
                save_T0 = keyTime;
            end
            if ScanCount == (dummy_scans+1)
                fprintf('\n ready-to-analyse fMRI scan starting now!\n')
                break
            end
            
            % wait for key up
            while isKeyDown
                isKeyDown = KbCheck;
            end
        end
    end
    if exittask==1;
        sca
        if fullscreen == 1; ShowCursor; end
        break
    end
else
    % The start signal is the User 'space' key press.
    fprintf('\n Waiting for the space bar key press...')
    while true
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown && keyCode(KbName('ESCAPE')); % press escape to quit the experiment
            exittask = 1;
            break
        end
        if isKeyDown && keyCode(KbName('space'));
            fprintf('\n Starting stimulation...\n')
            break
        end
    end
    if exittask==1;
        sca
        if fullscreen == 1; ShowCursor; end
        break
    end
end

%% --- GO SIGNAL FOR THE SUBJECT ---
% #################################
text = 'C EST PARTI!';
[w, h] = RectSize(Screen('TextBounds', window, text));
Screen('DrawText', window, text, ceil(crossX-w/2), ceil(crossY-h/2), colText);
Screen(window,'Flip');
WaitSecs(0.8);

%% -- loop over trial ---
% #######################

for trial = 1:num_trials_this_sess
    
    if exittask == 1;
        break
    end
    
    % get the difficulty (the difference in contrast between the 2
    % patches, which is between 0 and 1)
    diff_cont = min(1, max(0, (QuestMean(q))));
    
    % compute the mean of the sampling dist. for each Gabor
    % contrast
    % NB: 1=left, 2=right Gabor
    if is_left_gabor_max(trial)
        contrast1 = reference_contrast + diff_cont/2;
        contrast2 = reference_contrast - diff_cont/2;
    else
        contrast1 = reference_contrast - diff_cont/2;
        contrast2 = reference_contrast + diff_cont/2;
    end
    
    % Add gaussian noise
    contrast_samples1 = randn(1, NumOfFrame)*noise_sigma + contrast1;
    contrast_samples2 = randn(1, NumOfFrame)*noise_sigma + contrast2;
    
    % clip in the [0 1] range
    contrast_samples1(contrast_samples1<0) = 0;
    contrast_samples1(contrast_samples1>1) = 1;
    contrast_samples2(contrast_samples2<0) = 0;
    contrast_samples2(contrast_samples2>1) = 1;
    
    % check that the Gaussian noise does not reverse the sign of
    % the difference
    while sign(mean(contrast_samples1) - mean(contrast_samples2)) ...
            ~= sign(is_left_gabor_max(trial)-0.5)
        contrast_samples1 = randn(1, NumOfFrame)*noise_sigma + contrast1;
        contrast_samples2 = randn(1, NumOfFrame)*noise_sigma + contrast2;
        
        % clip in the [0 1] range
        contrast_samples1(contrast_samples1<0) = 0;
        contrast_samples1(contrast_samples1>1) = 1;
        contrast_samples2(contrast_samples2<0) = 0;
        contrast_samples2(contrast_samples2>1) = 1;
    end
    
    % randomize (or not) the gabor angle
    gabor_angle             = 90;%rand*180;
    reference_gabor_angle   = 90; %rand*180;
    
    % temporal jitters
    baseline_delay          = dur.bl + (rand-0.5)*dur.jit.bl;
    feedback_delay          = dur.fb + (rand-0.5)*dur.jit.fb;
    if session_number == 1 % trick to allow a faster pace during calibration
        ITI_delay           = dur.ITI(1) + (rand-0.5)*dur.jit.ITI(1);
        bef_fb              = dur.bef_fb(1);
    else
        ITI_delay           = dur.ITI(2) + (rand-0.5)*dur.jit.ITI(2);
        bef_fb              = dur.bef_fb(2);
    end
    
    
    % Set options that are valid only for this trial.
    trial_options = [opts, {             ...
        'sigma',                    gabor_dim_pix/6, ...                % frequency of the gabor
        'noise_sigma',              noise_sigma, ...
        'contrast_samples1',        contrast_samples1, ...
        'contrast_samples2',        contrast_samples2, ...
        'gabor_angle',              gabor_angle  ,...
        'reference_gabor_angle',    reference_gabor_angle ,...
        'baseline_delay',           baseline_delay, ...
        'delay_before_fb',          bef_fb, ...
        'feedback_delay',           feedback_delay, ...
        'ITI_delay',                ITI_delay, ...
        'eyetracker',               eyetracker, ...
        'fix',                      fix, ...
        }];
    
    [correct, response, confidence, rt_choice, timing, exittask] = ...
        one_trial(window, windowRect, screenNumber, ...
        is_left_gabor_max(trial), gabortex, gabor_dim_pix, trial_options);
    
    timings{trial} = timing;
    if ~isnan(correct)
        q = QuestUpdate(q, diff_cont, correct);
    end
    
    %convert trial_options to matlab structure
    trial_options_struct=cell2struct(trial_options(2:2:end)',trial_options(1:2:end)',1); % octave need DIM (=1 here) to be specified)
    results(trial) = struct(...
        'response', response, ...
        'is_left_gabor_max',    is_left_gabor_max(trial), ...
        'choice_rt',            rt_choice, ...
        'correct',              correct, ...
        'diff_cont',            diff_cont, ...
        'contrast_samples1',    contrast_samples1, ...
        'contrast_samples2',    contrast_samples2, ...
        'contrast1',            contrast1, ...
        'contrast2',            contrast2, ...
        'confidence',           confidence, ...
        'timings',              timing, ...
        'trial_options_struct', trial_options_struct);
end

% Save data
if exittask == 0; WaitSecs(1); end
fprintf('Saving data to %s\n', datadir)
session_struct.q = q;
session_struct.results = results;
filename = sprintf('session_results_sess_%d_%s.mat', session_number, datestr(clock, 'yyyy-mm-dd_HH-MM-SS'));
if IsOctave
    save('-mat7-binary', fullfile(datadir, filename))
else
    save(fullfile(datadir, filename))
end
if ~append_data
    results_struct = session_struct;
else
    disp('Trying to append')
    results_struct(length(results_struct)+1) = session_struct;
end
disp('Saving complete results')
if IsOctave
    save('-mat7-binary', fullfile(datadir, 'quest_results.mat'), 'results_struct')
else
    save(fullfile(datadir, 'quest_results.mat'), 'results_struct')
end

% Close screen
text = 'Fin de la session';
[w, h] = RectSize(Screen('TextBounds', window, text));
Screen('DrawText', window, text, round(crossX-w/2), round(crossY-h/2), colText);
Screen(window,'Flip');
if exittask == 0; WaitSecs(0.5); end
sca

if  strcmp(eyetracker,'y')
    disp('Receiving eyetracker data')
    eyelink_end;
end
disp('Done!')
toc
diary off

QuickCheckLastSession
