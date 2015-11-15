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
eyetracker='n';
diary('mylog.txt')
diary on

num_trials = 2; % How many trials?
datadir = '../../data';

% QUEST Parameters
pThreshold = .75; % Performance level and other QUEST parameters
beta = 3.5;
delta = 0.01;
gamma = 0.15;

% Parameters for sampling the contrast + contrast noise
noise_sigma             = 0.1; % variance of the Gaussian dist from which contrast is sampled.
reference_contrast      = 0.5; % ???
threshold_guess         = 0.5; %
threshold_guess_sigma   = 0.5; %

% rendering and options
fullscreen = 0; % 1 for fullscreen, 0 for window (debugging)
IsfMRI = 0; % 1 to wait for the trigger, 0 to initiate on the keyboard
bg = 0.5; % background color (range: 0-1)
gamma_lookup_table = '~/PostDoc/manip/LumiConfidence/Stimulation_v2/CalibrateLuminance/data/laptop_Screen_maxLum_CalibPhotometer.mat';
colText                 = 0.8*[1 1 1];      % text color


% Size of the gabor
gabor_dim_pix = 100;

% Parameters that control appearance of the gabors that are constant over
% trials
opts = {'sigma', gabor_dim_pix/6,...
    'num_cycles', 5,...
    'duration', .1,...
    'x_excentricity', 3, ...                        % in visual angle
    'distance_to_screen', 60, ...                   %
    'IsfMRI', IsfMRI, ...
    'ypos', 0,...                                   % in visual angle, Position Gabors in the lower hemifield to get activation in the dorsal pathaway
    'reference_contrast',reference_contrast};

% Define the IsOctave command if run in Matlab
try IsOctave
catch IsOctave = 0;
end


%% Ask for some subject details and load old QUEST parameters
initials = input('Initials? ', 's');
datadir = fullfile(datadir, initials);
mkdir(datadir);
quest_file = fullfile(datadir, 'quest_results.mat');
session_struct = struct('q', [], 'results', [], 'date', datestr(clock));
results_struct = session_struct;
session_number=1;

append_data = false;
repeat_last_session=false;
if exist(quest_file, 'file') == 2
    if strcmp(input('There is previous data for this subject. Load last QUEST parameters? [y/n] ', 's'), 'y')
        [tmp, results_struct, threshold_guess, threshold_guess_sigma] = load_subject(quest_file);
        append_data = true;
        session_number=1+length(results_struct);
        
        % Comment this part to avoid miskate (we don't want repetition
        % in the fMRI, but leave it in case one wants to change.
        %             do_repeat_last_session = input('Repeat last session? [y/n] ', 's');
        %             if strcmp(do_repeat_last_session, 'y')
        %                 repeat_last_session=1;
        %                 results_last_session=results_struct(end).results;
        %                 num_trials=length(results_last_session);
        %                 fprintf('Repeating last session, %d trials\n',num_trials)
        %             end
    end
end

fprintf('Session number: %d\n', session_number)

eye_filename=sprintf('%s_%03d',initials,session_number);
fprintf('Eye_filename: %s\n', eye_filename)

fprintf('QUEST Parameters\n----------------\nThreshold Guess: %1.4f\nSigma Guess: %1.4f\n', threshold_guess, threshold_guess_sigma)
if ~strcmp(input('OK? [y/n] ', 's'), 'y')
    throw(MException('EXP:Quit', 'User request quit'));
    
end


% Initialize eye
if strcmp(eyetracker,'y')
    PARAMS      = struct('calBACKGROUND', 128,'calFOREGROUND',0);
    edfFile = eyelink_ini(eye_filename,PARAMS);
    sca;
end

%% Some Setup
AssertOpenGL;
PsychDefaultSetup(2);

timings = {};

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
        [windowPtr, windowRect] = PsychImaging('OpenWindow', 0, bg, [1 1 1+0.5*w_px 1+0.5*h_px]);
    end
    w_px = windowRect(3);
    h_px = windowRect(4);
end

% get screen center coordinates
crossY = 1/2*h_px;
crossX = 1/2*w_px;

% Make a back up of the current clut table (to restore it at the
% end)
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
results = struct('response', [], 'is_left_gabor_max', [], 'choice_rt', [], 'correct', [],...
    'contrast', [], 'contrast_samples', [], ...
    'confidence', [], 'confidence_rt', [],'timings',[],'trial_options_struct',[]);

% randomize the position of the most contrasted gabor
is_left_gabor_max = [ones(1, floor(num_trials/2)), zeros(1, ceil(num_trials/2))];
is_left_gabor_max = is_left_gabor_max(randperm(num_trials));
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
        
        if isKeyDown && keyCode(KbName(key_scanOnset));
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

%%
% #################################

for trial = 1:num_trials
        % Sample contrasts.
        if repeat_last_session %if repeating last session, take all these values from last session
            
            % CURRENTLY NOT SUPPORTED!!!
            
            noise_sigma=results_last_session(trial).trial_options_struct.noise_sigma;
            contrast = results_last_session(trial).contrast;
            is_left_gabor_max = results_last_session(trial).is_left_gabor_max;
            contrast_samples = results_last_session(trial).contrast_samples;
            gabor_angle=results_last_session(trial).trial_options_struct.gabor_angle;
            reference_gabor_angle=results_last_session(trial).trial_options_struct.reference_gabor_angle;
            baseline_delay=results_last_session(trial).trial_options_struct.baseline_delay;
            confidence_delay=results_last_session(trial).trial_options_struct.confidence_delay;
            feedback_delay=results_last_session(trial).trial_options_struct.feedback_delay;
            reference_dur=results_last_session(trial).trial_options_struct.reference_dur;
            inter_dur=results_last_session(trial).trial_options_struct.inter_dur;
        else %if not repeating last session, choose randmly and/or from quest
            
            % get the difficulty (which is the difference in contrast
            % between the two patch, between 0 and 1)
            diff_cont = min(1, max(0, (QuestQuantile(q, 0.5))));
            
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
            
            % Add a gaussian noise
            contrast_samples1 = randn(1,10)*noise_sigma + contrast1;
            contrast_samples2 = randn(1,10)*noise_sigma + contrast2;
            
            % check that the Gaussian noise does not reverse the sign of
            % the difference
            while sign(mean(contrast_samples1) - mean(contrast_samples2)) ...
                    ~= sign(is_left_gabor_max(trial)-0.5)
                contrast_samples1 = randn(1,10)*noise_sigma + contrast1;
                contrast_samples2 = randn(1,10)*noise_sigma + contrast2;
            end
            
            % tmp
            contrast = min(1, max(0, (QuestQuantile(q, 0.5))));
            contrast_samples = sample_contrast(contrast, noise_sigma, reference_contrast, 1);
            
            % randomize (or not) the gabor angle
            gabor_angle             = 90;%rand*180;
            reference_gabor_angle   = 90; %rand*180;
            
            % temporal jitters
            baseline_delay          = 1 + rand*0.5;
            confidence_delay        = 0.5 + rand*1;
            feedback_delay          = 0.5 + rand*1;
            reference_dur           = 0.4;
            inter_dur               = 0.5;
            
        end
        % Set options that are valid only for this trial.
        trial_options = [opts, {             ...
            'noise_sigma', noise_sigma       ,...
            'contrast_samples',contrast_samples,...
            'contrast_samples1',contrast_samples1,...
            'contrast_samples2',contrast_samples2,...
            'gabor_angle', gabor_angle      ,...
            'reference_gabor_angle', reference_gabor_angle      ,...
            'baseline_delay', baseline_delay,...
            'confidence_delay', confidence_delay, ...
            'feedback_delay', feedback_delay,...
            'reference_dur', reference_dur, ...
            'inter_dur', inter_dur, ...
            'rest_delay', 0.5               ,...
            'eyetracker',eyetracker         ,...
            }];
        
        [correct, response, confidence, rt_choice, rt_conf, timing] = one_trial(window, windowRect,...
            screenNumber, is_left_gabor_max, gabortex, gabor_dim_pix, trial_options);
        
        timings{trial} = timing;
        if ~isnan(correct)
            q = QuestUpdate(q, contrast, correct);
        end
        %convert trial_options to matlab structure
        trial_options_struct=cell2struct(trial_options(2:2:end)',trial_options(1:2:end)',1); % octave need DIM (=1 here) to be specified)
        results(trial) = struct('response', response, 'is_left_gabor_max', is_left_gabor_max(trial), 'choice_rt', rt_choice, 'correct', correct,...
            'contrast', contrast, 'contrast_samples', contrast_samples,...
            'confidence', confidence, 'confidence_rt', rt_conf,'timings',timing,'trial_options_struct',trial_options_struct);
end

% Save data
WaitSecs(1);
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
text = 'Fin de l''experience';
[w, h] = RectSize(Screen('TextBounds', window, text));
Screen('DrawText', window, text, round(crossX-w/2), round(crossY-h/2), colText);
Screen(window,'Flip');
WaitSecs(0.5);
sca
% restore_gamma_table

if  strcmp(eyetracker,'y')
    disp('Receiving eyetracker data')
    eyelink_end;
end
disp('Done!')
diary off
