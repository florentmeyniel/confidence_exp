function ppd = estimate_pixels_per_degree(screenNumber, distance, IsfMRI)
% for backwark compatibility
if nargin == 2
    IsfMRI = 0;
end

if IsfMRI
    [w, h] = [100 100]; % size of the fMRI screen, in mm (100 is a pure guess!!)
else
    [w, h] = Screen('DisplaySize', screenNumber); % size of the monitor in mm
end
w = w/10;
h = h/10;
stats = Screen('Resolution', screenNumber);
o = tan(0.5*pi/180) *distance;
ppd = 2 * o*stats.width/w;
end