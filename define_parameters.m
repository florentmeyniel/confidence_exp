% PARAMETERS FOR THE LUMINANCE / LOCALIZER EXPERIMENT

% Script to define the options and parameters of the experiment.

% QUEST Parameters
pThreshold              = .75;          % Expected performance level
threshold_guess         = 0.25;         % initial guess for the subject's threshold (this is the difference in contrast between patches)
threshold_guess_sigma   = 0.5;          % standard dev. for threshold_guess
beta                    = 3.5;
delta                   = 0.01;
gamma                   = 0.15;

% Parameters for sampling the contrast + contrast noise
noise_sigma             = 0.1;          % 0.1 variance of the Gaussian dist from which contrast is sampled.
reference_contrast      = 0.5;          % mean contrast level (the 2 Gabors are above and below this value)

% rendering and options
fullscreen              = 1;            % 1 for fullscreen, 0 for window (debugging)
IsfMRI                  = 1;            % 1 to wait for the trigger, 0 to initiate on the keyboard
num_trials              = [65 72];      % How many trials [1st session, other sessions]
bg                      = 0.5;          % background color (range: 0-1)
datadir                 = '../../data'; % directory to save data
colText                 = 0.8*[1 1 1];  % text color
fix.w                   = 10;           % diameter of the fixation dot in pixels
fix.in                  = 4;            % diameter of the inner circle
x_excentricity          = 4;            % excentricity in visual angle (deg) of the Gabor wrt. fixation
NumOfFrame              = 10;           % number of frame
eyetracker              ='n'; 
dummy_scans             = 4;
gabor_dim_deg           = 4;            % Size of the gabor in visual angle

% color of fixation
ResponseDotColor        = [.75 .75 .75];
RespCorrect             = [0 0.5 0];
RespError               = [1 0 0];

if IsfMRI == 1
    dist2screen = 98; 		% distance to the screen in cm (10 cm to the mirror + 88 cm to the screen)
    ScreenSize = [42 42]; 	% [w, h] in cm
    gamma_lookup_table = ...
	'~/PostDoc/manip/LumiConfidence/Stimulation_v2/CalibrateLuminance/data/laptop_MRIscreen_VisualCalib_linthd_smoothdark.mat';
else
    gamma_lookup_table = ...
        '~/PostDoc/manip/LumiConfidence/Stimulation_v2/CalibrateLuminance/data/laptop_Screen_maxLum_CalibPhotometer.mat';
    dist2screen = 50;      % distance in cm between observer and screen
    ScreenSize = [30.6 17.4]; % [w, h] in cm
end

% timing options (in second)
dur.bl                  = 0.5;          % duration of the baseline cue indicating that a new trial starts
dur.jit.bl              = 0;
dur.each_frame          = 0.105;        % put 105ms so that it falls on 100ms is the 60Hz refresh rate
dur.decision            = 1;            % waiting time before answer should be provided.
dur.response            = 2;            % time window for the subject to answer
dur.bef_fb              = [1 2];        % waiting time before the fb is displayed [1st session, other sessions]
dur.fb                  = 1;            % duration for fb on screen
dur.jit.fb              = 0;
dur.ITI                 = [0 2.5];      % the actual duraction is dur.ITI + dur.response - RT +/-jit. [1st session, other sessions]
dur.jit.ITI             = [0 1];        % [1st session, other sessions]


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
    'bg',                   bg, ...
    'driftspeed',           5 ...                   % 5 how fast the gabors drift (units not clear yet)
    'dist2screen',          dist2screen, ...
    'ScreenSize',           ScreenSize, ...
    'ResponseDotColor',     ResponseDotColor, ...
    'RespCorrect',          RespCorrect, ...
    'RespError',            RespError
    };

% Parameters specific to the localize
alphabet_s = {'a', 'z', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'q', ...
    'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'w', 'x', 'c', 'v', 'b', 'n'};

loc.dur.letter      = 0.1;      % duraction (s) of each letter
loc.dur.isi         = 0.15;     % duraction (s) of isi
loc.dur.fix         = 0.7;      % duration (s) of the fixation
loc.fracletter      = 1/10;     % proportion of target (level 's')

loc.patch.on        = 15;       % target duration (s) of patch on screen
loc.patch.off       = 5;        % target duration (s) of blank
loc.patch.freq.min  = 4;        % minimum spatial frequency of the checkerboard
loc.patch.freq.max  = 8;        % maximum spatial frequency of the checkerboard
loc.patch.ang.min   = 0;        % minimum angle tilt
loc.patch.ang.max   = 90;       % maximum angle tilt

loc.dur.total       = 6 * 60;   % total duration in seconds
