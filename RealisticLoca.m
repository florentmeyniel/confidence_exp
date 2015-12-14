%% Confidence experiment
%
% Runs one session of the confidence experiment to serve as a "localizer"
% of the contrast in visual regions.
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

%% ---COMPLETE SETTINGS---
% ############################

% COMPUTE TIMINGS OF THE LOCALIZER
% duration of "1 cycle" (isi fix isi letter)
cycle_dur = loc.dur.letter + loc.dur.fix + 2*loc.dur.isi;

% duration, in cycle of on & off peripheric patched
on_dur_cycle = round(loc.patch.on / cycle_dur);
off_dur_cycle = round(loc.patch.off / cycle_dur);
minibloc_dur_cycle = on_dur_cycle + off_dur_cycle;

% number of LRminibloc (onL off onR off)
LRminibloc_n = floor(loc.dur.total / (2*minibloc_dur_cycle*cycle_dur));

% compute the number of cycle (hence, of letters)
loc.numletter       = LRminibloc_n*2*minibloc_dur_cycle;       

% compute number of angles and frequencies
n_patch_freq = floor(sqrt(minibloc_dur_cycle*LRminibloc_n));
n_patch_angl = floor(sqrt(minibloc_dur_cycle*LRminibloc_n));

% Compute type for each cycle (left / right / blank)
PatchType = repmat([...
    1*ones(1, on_dur_cycle), 0*ones(1, off_dur_cycle), ... % Right patch
    2*ones(1, on_dur_cycle), 0*ones(1, off_dur_cycle), ... % Left patch
    ], [1, LRminibloc_n]);


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

tot_dur = cycle_dur * loc.numletter;
tot_dur_min_s_text = sprintf('%2.0f min %2.0f s', floor(tot_dur/60),(tot_dur/60 - floor(tot_dur/60))*60);

% check if everything is correct
fprintf('\n total dur: %d s (%s) <=> %d TR\n\n', ...
    round(tot_dur), tot_dur_min_s_text, ceil(tot_dur/2))
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

% get different in contrast from the last session of the contrast task.
diff_cont = min(1, max(0, (QuestMean(q))));

% Compute specific timing of this localizer
patch_freq = 10; % Hz: number of frames per second
NumOfFrameDuringLetter = round(loc.dur.letter*patch_freq);
NumOfFrameDuringISI = round(loc.dur.isi*patch_freq);
NumOfFrameDuringFix = round(loc.dur.fix*patch_freq);

% various options for the Gabor patches
num_cycles          = default_arguments(opts, 'num_cycles');
ypos                = default_arguments(opts, 'ypos');
driftspeed          = default_arguments(opts, 'driftspeed');
duration            = default_arguments(opts, 'duration');
ifi                 = Screen('GetFlipInterval', window);
freq                = num_cycles / gabor_dim_pix;
xpos1               = -x_excentricity*ppd;
xpos2               = x_excentricity*ppd;
ypos                = ypos*ppd;
[xCenter, yCenter]  = RectCenter(windowRect);
xpos1               = xpos1 + xCenter;
xpos2               = xpos2 + xCenter;
ypos                = ypos + yCenter;
baseRect            = [0 0 gabor_dim_pix gabor_dim_pix];
allRects1           = CenterRectOnPointd(baseRect, xpos1, ypos)';
allRects2           = CenterRectOnPointd(baseRect, xpos2, ypos)';
degPerSec           = 360 * driftspeed;
degPerFrame         = degPerSec * ifi;
gaborAngles         = 90;
sigma               = gabor_dim_pix/6;
propertiesMat1      = [0, freq, sigma, 0, 1, 0, 0, 0];
propertiesMat2      = [0, freq, sigma, 0, 1, 0, 0, 0];

% RANDOMIZE LETTER PRESENTATION
seq = cell(1, loc.numletter);
num_target = ceil(loc.numletter*loc.fracletter);

% sample the position of target (with the constraint that they should not
% be consequentive
while true
    rand_pos = randperm(numel(seq));
    target_pos = rand_pos(1:num_target);
    if all(abs(diff(target_pos)) ~= 1)
        break
    end
end

% fill the sequence
n_nt = numel(alphabet_s);
for k = 1:numel(seq)
    if ismember(k, target_pos)
        seq{k} = 's';
    else
        seq{k} = alphabet_s{ceil(rand*n_nt)};
    end
end

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

%% -- loop over trials ---
% ########################

t = GetSecs;
save_timing_PatchOnset = zeros(1, loc.numletter);
vbl = GetSecs;
for k = 1:loc.numletter
    if exittask == 1; break; end
    
    % draw letter
    NumOfFrame = NumOfFrameDuringLetter;
    TaskMoment = 'LetterPresentation';
    Realisticloc_drawPatchTexture
    save_timing_PatchOnset(k) = Gabor_onset(1);
    if exittask == 1; break; end
    
    % blank
    NumOfFrame = NumOfFrameDuringISI;
    TaskMoment = 'Blank';
    Realisticloc_drawPatchTexture
    if exittask == 1; break; end
    
    % draw fixation
    NumOfFrame = NumOfFrameDuringFix;
    TaskMoment = 'Fix';
    Realisticloc_drawPatchTexture
    if exittask == 1; break; end
    
    % blank
    NumOfFrame = NumOfFrameDuringISI;
    TaskMoment = 'Blank';
    Realisticloc_drawPatchTexture
end


text = 'Fin de la session';
[w, h] = RectSize(Screen('TextBounds', window, text));
Screen('DrawText', window, text, round(crossX-w/2), round(crossY-h/2), colText);
Screen(window,'Flip');
WaitSecs(0.5);
sca

% Save data
filename = sprintf('realisticfunclocalizer_%s.mat', datestr(clock, 'yyyy-mm-dd_HH-MM-SS'));
if IsOctave
    save('-mat7-binary', fullfile(datadir, filename))
else
    save(fullfile(datadir, filename))
end
toc
fprintf('\nNumber of s: %d\n', num_target)
