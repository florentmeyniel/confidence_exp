% Initialize random generators (and use a workaround when rng is not
% re-cognized, e.g. by Octave)
try
    rng('shuffle')
catch
    rand('twister',sum(100*clock))
end

clear all
tic

% define parameters (stored in a separate script)
define_parameters

%% ---COMPLETE SETTINGS---
% ############################

% compute the duration of mini block

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
WithinPatch1count = cumsum(PatchType == 1);
WithinPatch2count = cumsum(PatchType == 2);

% compute period: when a number of cycles first match a number of TR
TR = 2;
period = 0;
while period < loc.dur.total/TR
    period = period+1;
    if abs((period*cycle_dur/TR - round(period*cycle_dur/TR))) < eps; 
        break; 
    end
end

%% ---ASK SUBJECT ID---
% ########################

% get subject name and create a specific directory

% Ask for input
while true
    clc;
    if IsfMRI == 1
        fprintf('\n fMRI setting enabled\n')
    else
        fprintf('\n fMRI setting disabled\n')
    end
    fprintf('\n cycle dur: %3.2fs, TR: %3.2fs, T=%d TR\n', cycle_dur, TR, period)
    
    tot_dur = cycle_dur * loc.numletter;
    tot_dur_min_s_text = sprintf('%2.0f min %2.0f s', floor(tot_dur/60),(tot_dur/60 - floor(tot_dur/60))*60);
    fprintf('\n total dur: %d s (%s) <=> %d TR\n\n', ...
    round(tot_dur), tot_dur_min_s_text, ceil(tot_dur/2))
    
    initials = input('Initials? ', 's');
    
    if strcmp(initials, 'test'); 
        break; 
    end
    
    fprintf('\n\n \t CHECK THE DATA YOU SPECIFIED\n')
    fprintf('\n \t      Subject ID: %s', initials)
    
    fprintf('\n \t IS IT CORRECT? \n')
    correct = input(' (press the ''y'' or ''n'' key and then the ''enter'' key for yes or no)   ', 's');
    
    if correct=='y'
        break
    end
end
datadir = fullfile(datadir, initials);
if ~exist(datadir, 'dir')
    mkdir(datadir)
    fprintf('\n create new directory\n')
end


%% ---SETUP SCREEN---
% ######################

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
gabor_dim_pix = round(gabor_dim_deg*ppd);

% Make a back up of the current clut table (to restore it at the end)
LoadIdentityClut(window);
load(gamma_lookup_table)
Screen('LoadNormalizedGammaTable', window, mygammatable);

Screen('Flip', window);

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

% MAKE TEXTURE FOR THE LOCALIZERS
% Properties of the gabor
xpos1               = -x_excentricity*ppd;
xpos2               = x_excentricity*ppd;
ypos                = ppd*default_arguments(opts, 'ypos');
[xCenter, yCenter]  = RectCenter(windowRect);
xpos1               = xpos1 + xCenter;
xpos2               = xpos2 + xCenter;
ypos                = ypos + yCenter;
baseRect            = [0 0 gabor_dim_pix gabor_dim_pix];
allRects1           = CenterRectOnPointd(baseRect, xpos1, ypos)';
allRects2           = CenterRectOnPointd(baseRect, xpos2, ypos)';

% Compute list of angles and frequencies
angl_list = linspace(loc.patch.ang.min, loc.patch.ang.max, n_patch_angl);
freq_list = linspace(loc.patch.freq.min, loc.patch.freq.max, n_patch_angl);

% precompute frequencies
PatchTex = cell(1, numel(freq_list));
for kFreq = 1:numel(freq_list)
    PatchTex{kFreq} = loc_MakePatchTexture(gabor_dim_pix, freq_list(kFreq), window);
end

% Allow transparency
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% RANDOMIZE FREQUENCY AND ANGLE LIST
nrep = n_patch_freq;
[angl_order, freq_order] = meshgrid(1:nrep, 1:nrep); % make sure than each combination is shown at least once

angl_order_all = cell(1,2);
freq_order_all = cell(1,2);
for k = 1:2
    % Assign values to left and right (independently)
    rand_ind = randperm(nrep*nrep);
    angl_order_all{k} = angl_order(rand_ind);
    freq_order_all{k} = freq_order(rand_ind);
    
    % append with more randmon sample
    n_missing = minibloc_dur_cycle*LRminibloc_n - nrep*nrep;
    angl_order_all{k} = [angl_order_all{k}, ceil(rand(1,n_missing)*nrep)];
    freq_order_all{k} = [freq_order_all{k}, ceil(rand(1,n_missing)*nrep)];    
end

%% ---WAIT START SIGNAL---
% ############################
exittask = 0;
get_key_code
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

%% ---TASK---
% #############
t = GetSecs;
save_timing_PatchOnset = zeros(1, loc.numletter);
for k = 1:loc.numletter
    if exittask == 1; break; end
    
    % draw letter
    text = seq{k};
    [w, h] = RectSize(Screen('TextBounds', window, text));
    Screen('DrawText', window, text, round(crossX-w/2), round(crossY-h/2), colText);
    loc_drawPatchTexture
    t = Screen('Flip', window);
    save_timing_PatchOnset(k) = t;
    while (GetSecs-t) < loc.dur.letter
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown && keyCode(KbName('ESCAPE')); % press escape to quit the experiment
            exittask = 1;
            break
        end
    end
    if exittask == 1; break; end
    
    % blank
    loc_drawPatchTexture
    t = Screen('Flip', window);
    while (GetSecs-t) < loc.dur.isi
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown && keyCode(KbName('ESCAPE')); % press escape to quit the experiment
            exittask = 1;
            break
        end
    end
    if exittask == 1; break; end
    
    % draw fixation
    loc_drawPatchTexture
    Screen('FillOval', window, colText, fix.pos);
    Screen('FillOval', window, bg, fix.posin);
    t = Screen('Flip', window);    
    while (GetSecs-t) < loc.dur.fix
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown && keyCode(KbName('ESCAPE')); % press escape to quit the experiment
            exittask = 1;
            break
        end
    end
    if exittask == 1; break; end
    
    % blank
    loc_drawPatchTexture
    t = Screen('Flip', window);
    while (GetSecs-t) < loc.dur.isi
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown && keyCode(KbName('ESCAPE')); % press escape to quit the experiment
            exittask = 1;
            break
        end
    end
end


%% ---END / SAVE---
% ####################

text = 'Fin de l''experience';
[w, h] = RectSize(Screen('TextBounds', window, text));
Screen('DrawText', window, text, round(crossX-w/2), round(crossY-h/2), colText);
Screen(window,'Flip');
WaitSecs(0.5);
sca

filename = sprintf('funclocalizer_%s.mat', datestr(clock, 'yyyy-mm-dd_HH-MM-SS'));
if IsOctave
    save('-mat7-binary', fullfile(datadir, filename))
else
    save(fullfile(datadir, filename))
end
toc
fprintf('\nNumber of s: %d\n', num_target)

