function ppd = estimate_pixels_per_degree(screenNumber, distance, ScreenSize)
% Compute the number of pixel per degree of visual angle, as a function of 
% the resoluation of the screen (automatically collected by this function),
% the distance to the screen and the screen size (both should be in the
% same unit).

w = ScreenSize(1); % size in cm

stats = Screen('Resolution', screenNumber); % size in px

Half_screen_w = w/2;
Half_screen_w_deg = atan(Half_screen_w / distance)*180/pi;
Half_screen_w_px = stats.width/2;

ppd = Half_screen_w_px / Half_screen_w_deg;



end