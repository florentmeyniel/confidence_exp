% number of frame

eyetracker='n';

% QUEST Parameters
pThreshold = .75; % Performance level and other QUEST parameters
beta = 3.5;
delta = 0.01;
gamma = 0.15;

% Parameters for sampling the contrast + contrast noise
noise_sigma             = 0.1; % variance of the Gaussian dist from which contrast is sampled.
reference_contrast      = 0.5; % mean contrast level (the 2 Gabors are above and below this value)
threshold_guess         = 0.5; % initial guess for the subject's threshold (this is the difference in contrast between patches)
threshold_guess_sigma   = 0.5; % standard dev. for threshold_guess

% rendering and options
fullscreen = 1; % 1 for fullscreen, 0 for window (debugging)
IsfMRI = 0; % 1 to wait for the trigger, 0 to initiate on the keyboard
bg = 0.5; % background color (range: 0-1)
gamma_lookup_table = '~/PostDoc/manip/LumiConfidence/Stimulation_v2/CalibrateLuminance/data/laptop_Screen_maxLum_CalibPhotometer.mat';
colText                 = 0.8*[1 1 1];      % text color
fix.w                   = 10;               % diameter of the fixation dot in pixels
fix.in                  = 4;                % diameter of the inner circle
x_excentricity = 6;
if IsfMRI == 1
    dist2screen = 60; % distance to the screen in cm
    ScreenSize = [100 100]; 
else
    dist2screen = 30;
    ScreenSize = NaN;
end

% timing options
dur.bl = 1;
dur.jit.bl = 0.5;
dur.each_frame = 0.1;
dur.decision = 2; % time before answer should be provided.
dur.response = 2; % time window for the subject to answer
dur.bef_fb = 1; % time before the fb is displayed
dur.fb = 1; % duration for fb on screen
dur.jit.fb = 0.5;

dummy_scans             = 4;

% Size of the gabor
gabor_dim_deg = 5;


% Parameters that control appearance of the gabors that are constant over
% trials
opts = {'num_cycles', 5,...                             % spatial frequency of the gabor
    'x_excentricity', x_excentricity, ...                        % in visual angle
    'distance_to_screen', 60, ...                   %
    'IsfMRI', IsfMRI, ...                           
    'ypos', 0,...                                   % in visual angle, Position Gabors in the lower hemifield to get activation in the dorsal pathaway
    'reference_contrast',reference_contrast, ...
    'duration', dur.each_frame ...                  % duration (s) of each frame
    'decision_delay', dur.decision, ...
    'response_duration', dur.response, ...
    'delay_before_fb', dur.bef_fb, ...
    'bg', bg, ...
    'driftspeed', 1 ... % how fast the gabors drift (units not clear yet)
    'dist2screen', dist2screen, ...
    'ScreenSize', ScreenSize
    };
