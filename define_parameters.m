% Script to define the options and parameters of the experiment.

% QUEST Parameters
pThreshold              = .75;          % Expected performance level
threshold_guess         = 0.5;          % initial guess for the subject's threshold (this is the difference in contrast between patches)
threshold_guess_sigma   = 0.5;          % standard dev. for threshold_guess
beta                    = 3.5;
delta                   = 0.01;
gamma                   = 0.15;

% Parameters for sampling the contrast + contrast noise
noise_sigma             = 0.1;          % variance of the Gaussian dist from which contrast is sampled.
reference_contrast      = 0.5;          % mean contrast level (the 2 Gabors are above and below this value)

% rendering and options
fullscreen              = 0;            % 1 for fullscreen, 0 for window (debugging)
IsfMRI                  = 0;            % 1 to wait for the trigger, 0 to initiate on the keyboard
num_trials              = [45 72];      % How many trials [calib, other]
bg                      = 0.5;          % background color (range: 0-1)
gamma_lookup_table      = '~/PostDoc/manip/LumiConfidence/Stimulation_v2/CalibrateLuminance/data/laptop_Screen_maxLum_CalibPhotometer.mat';
datadir                 = '../../data'; % directory to save data
colText                 = 0.8*[1 1 1];  % text color
fix.w                   = 10;           % diameter of the fixation dot in pixels
fix.in                  = 4;            % diameter of the inner circle
x_excentricity          = 6;            % excentricity in visual angle (deg) of the Gabor wrt. fixation
NumOfFrame              = 10;           % number of frame
eyetracker              ='n'; 
dummy_scans             = 4;
gabor_dim_deg           = 5;            % Size of the gabor in visual angle

if IsfMRI == 1
    dist2screen = 60; % distance to the screen in cm
    ScreenSize = [100 100]; 
else
    dist2screen = 30;
    ScreenSize = NaN;
end

% timing options
dur.bl                  = 0.5;
dur.jit.bl              = 0;
dur.each_frame          = 0.055;        % put 55ms so that it falls on 50 is the 60Hz refresh rate
dur.decision            = 1;            % time before answer should be provided.
dur.response            = 2;            % time window for the subject to answer
dur.bef_fb              = 2;            % time before the fb is displayed
dur.fb                  = 1;            % duration for fb on screen
dur.jit.fb              = 0;
dur.ITI                 = 3;            % the actual duraction is dur.ITI+dur.response-RT +/-jit
dur.jit.ITI             = 1;


% Parameters that control appearance of the gabors that are constant over
% trials
opts = {...
    'num_cycles',           5,...                    % spatial frequency of the gabor
    'x_excentricity',       x_excentricity, ...      % in visual angle
    'distance_to_screen',   dist2screen, ...         
    'IsfMRI',               IsfMRI, ...                           
    'ypos',                 0,...                    % horizontal shift
    'duration',             dur.each_frame ...                  
    'decision_delay',       dur.decision, ...
    'response_duration',    dur.response, ...
    'delay_before_fb',      dur.bef_fb, ...
    'bg',                   bg, ...
    'driftspeed',           1 ...                   % how fast the gabors drift (units not clear yet)
    'dist2screen',          dist2screen, ...
    'ScreenSize',           ScreenSize
    };
