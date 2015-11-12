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
baseline_contrasts = [0.5];
noise_sigmas = [.05 .1 .15];
reference_contrast = 0.5;
threshold_guess = 0.5;
threshold_guess_sigma = 0.5;
% Size of the gabor
gabor_dim_pix = 500;
% Parameters that control appearance of the gabors that are constant over
% trials
opts = {'sigma', gabor_dim_pix/6,...
    'num_cycles', 5,...
    'duration', .1,...
    'xpos', [0],...
    'ypos', [0],...
    'reference_contrast',reference_contrast}; % Position Gabors in the lower hemifield to get activation in the dorsal pathaway

fullscreen = 0; % 1 for fullscreen, 0 for window (debugging)
bg = 0.5; % background color (range: 0-1)
gamma_lookup_table = '~/PostDoc/manip/LumiConfidence/Stimulation_v2/CalibrateLuminance/laptop_Screen_maxLum_CalibPhotometer.mat';

try
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

            if strcmp(input('Repeat last session? [y/n] ', 's'), 'y')
                repeat_last_session=1;            
                results_last_session=results_struct(end).results;
                num_trials=length(results_last_session);
                fprintf('Repeating last session, %d trials\n',num_trials)
            end        
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
%         transfiere_imagen_eyetracker;
    end
    
    %% Some Setup
    AssertOpenGL;
    sca;
    PsychDefaultSetup(2);
%     InitializePsychSound;
%     pahandle = PsychPortAudio('Open', [], [], 0);
    pahandle=nan;
    
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
            [window, windowRect] = PsychImaging('OpenWindow', 0, bg, [1 1 1+0.2*w_px 1+0.5*h_px]);
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
    
    % Make a back up of the current clut table (to restore it at the
    % end)
    LoadIdentityClut(window);
    load(gamma_lookup_table)
    Screen('LoadNormalizedGammaTable', window, mygammatable);
    
    Screen('Flip', window);
    
    % Make gabortexture
    gabortex = make_gabor(window, 'gabor_dim_pix', gabor_dim_pix);
    % Maximum priority level
    topPriorityLevel = MaxPriority(window);
          
    % Set up QUEST
    q = QuestCreate(threshold_guess, threshold_guess_sigma, pThreshold, beta, delta, gamma);
    q.updatePdf = 1;
    
    % A structure to save results.
    results = struct('response', [], 'side', [], 'choice_rt', [], 'correct', [],...
        'contrast', [], 'contrast_samples', [], ...
        'confidence', [], 'confidence_rt', [],'timings',[],'trial_options_struct',[]);
        
    %% Do Experiment
    for trial = 1:num_trials
        try
            %pause every 100 trials
            if ismember(trial,[100 200 300 400])
                instrucciones='Pausa:\n\n\nPulse una tecla para continuar';               
                DrawFormattedText(window,instrucciones, 'center','center',[0 0 0])
                Screen('Flip', window);  
                
                %wait for keypress
                while ~KbCheck;WaitSecs(0.005);end
                
%                 [width, height]=Screen('WindowSize', window);    
                DrawFormattedText(window,'.', 'center','center',[0 0 0])
%                 Screen('DrawDots', window, [width/2; height/2], 10, [0 0 0], [], 1);
                Screen('Flip', window);  
                
                %wait for key release
                while KbCheck;WaitSecs(0.005);end
            end
            
            
            % Sample contrasts.
            if repeat_last_session %if repeating last session, take all these values from last session
                noise_sigma=results_last_session(trial).trial_options_struct.noise_sigma;
                contrast = results_last_session(trial).contrast;
                side = results_last_session(trial).side;
                contrast_samples = results_last_session(trial).contrast_samples;
                gabor_angle=results_last_session(trial).trial_options_struct.gabor_angle;
                reference_gabor_angle=results_last_session(trial).trial_options_struct.reference_gabor_angle;
                baseline_delay=results_last_session(trial).trial_options_struct.baseline_delay;
                confidence_delay=results_last_session(trial).trial_options_struct.confidence_delay;
                feedback_delay=results_last_session(trial).trial_options_struct.feedback_delay;
                reference_dur=results_last_session(trial).trial_options_struct.reference_dur;
                inter_dur=results_last_session(trial).trial_options_struct.inter_dur;
            else %if not repeating last session, choose randmly and/or from quest
                noise_sigma=noise_sigmas(ceil(rand*numel(noise_sigmas))); % workaround for randsample in octave
                contrast = min(1, max(0, (QuestQuantile(q, 0.5))));
                side = sign(rand-0.5); % workaround for randsample([1n -1], 1) in octave
                contrast_samples = sample_contrast(contrast, noise_sigma, reference_contrast,side);                
                gabor_angle=90;%rand*180;                
                reference_gabor_angle=90;%rand*180;
                baseline_delay=1 + rand*0.5;
                confidence_delay=0.5 + rand*1;
                feedback_delay=0.5 + rand*1;
                reference_dur=0.4;
                inter_dur=0.5;
            end
            % Set options that are valid only for this trial.
            trial_options = [opts, {             ...
                'noise_sigma',noise_sigma       ,...
                'contrast_samples',contrast_samples,...
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
                screenNumber, side, gabortex, gabor_dim_pix, pahandle, trial_options);
            
            timings{trial} = timing;
            if ~isnan(correct)
                q = QuestUpdate(q, contrast, correct);
            end
            %convert trial_options to matlab structure
            trial_options_struct=cell2struct(trial_options(2:2:end)',trial_options(1:2:end)',1); % octave need DIM (=1 here) to be specified)            
            results(trial) = struct('response', response, 'side', side, 'choice_rt', rt_choice, 'correct', correct,...
               'contrast', contrast, 'contrast_samples', contrast_samples,...
               'confidence', confidence, 'confidence_rt', rt_conf,'timings',timing,'trial_options_struct',trial_options_struct);
        catch
            ME = lasterror; % work around for Octave
            if (strcmp(ME,'EXP:Quit'))
                break
            else
                rethrow(ME);
            end
%             if exist('window','var')
%                 LoadIdentityClut(window);
%             end
            sca            
            diary off
            keyboard
        end
    end
catch 
    ME = lasterror; % work around for Octave
%     if exist('window','var')
%         LoadIdentityClut(window);
%     end
    if (strcmp(ME.identifier,'EXP:Quit'))
        return
    else
        rethrow(ME);
    end
    %PsychPortAudio('Close');
    disp(getReport(ME,'extended'));
    if  strcmp(eyetracker,'y')
        disp('Receiving eyetracker data')
        eyelink_end;
%         eyelink_receive_file(eye_filename);
    end        
    diary off
end
if exist('window','var')
    LoadIdentityClut(window);
end
%PsychPortAudio('Close');
WaitSecs(1);
fprintf('Saving data to %s\n', datadir)
session_struct.q = q;
session_struct.results = results;
% session_struct.results = struct2table(results);
disp('Saving session results')
filename=sprintf('session_results_%s.mat',datestr(clock, 'yyyy-mm-dd_HH-MM-SS.FFF'));
save(fullfile(datadir, filename), 'session_struct')
if ~append_data
    results_struct = session_struct;
else
    disp('Trying to append')
    results_struct(length(results_struct)+1) = session_struct;    
end
disp('Saving complete results')
save(fullfile(datadir, 'quest_results.mat'), 'results_struct')
% writetable(session_struct.results, fullfile(datadir, sprintf('%s_%s_results.csv', initials, datestr(clock))));

%fin del experimento
% Screen('FillRect', window, 128)
DrawFormattedText(window, 'Fin del experimento', 'center', 'center' , 0); 
Screen('flip',window);       
WaitSecs(0.5);
sca
restore_gamma_table

if  strcmp(eyetracker,'y')
    disp('Receiving eyetracker data')
    eyelink_end;
%     eyelink_receive_file(eye_filename);
end
disp('Done!')
diary off
