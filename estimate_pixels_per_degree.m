function ppd = estimate_pixels_per_degree(screenNumber, distance, IsfMRI, ScreenSize)
% Compute the number of pixel per degree of visual angle, as a function of 
% the resoluation of the screen (automatically collected by this function),
% the distance to the screen and the screen size (in mm).
% NB: if IsfMRI = 1, the ScreenSize [w, h] must be provided.

% for backwark compatibility
if nargin == 2
    IsfMRI = 0;
end

if IsfMRI
    % size of the fMRI screen, in mm 
    w = ScreenSize(1);
    h = ScreenSize(2);
else
    [w, h] = Screen('DisplaySize', screenNumber); % size of the monitor in mm
end
w = w/10;
h = h/10;
stats = Screen('Resolution', screenNumber);
o = tan(0.5*pi/180) *distance;
ppd = 2 * o*stats.width/w;
end