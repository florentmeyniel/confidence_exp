% Script to plot the animation loop with Gabor patches and letter task

% INITIALIZE PROPERTIES
% Compute contrast of the Gabor patches
nImg = NumOfFrame;
if PatchType(k) == 1 % Right
    contrast1 = reference_contrast - diff_cont/2;
    contrast2 = reference_contrast + diff_cont/2;
    contrast_samples1 = randn(1, NumOfFrame)*noise_sigma + contrast1;
    contrast_samples2 = randn(1, NumOfFrame)*noise_sigma + contrast2;
    
    % clip in the [0 1] range
    contrast_samples1(contrast_samples1<0) = 0;
    contrast_samples1(contrast_samples1>1) = 1;
    contrast_samples2(contrast_samples2<0) = 0;
    contrast_samples2(contrast_samples2>1) = 1;
    
elseif PatchType(k) == 2 % Left
    contrast1 = reference_contrast + diff_cont/2;
    contrast2 = reference_contrast - diff_cont/2;
    contrast_samples1 = randn(1, NumOfFrame)*noise_sigma + contrast1;
    contrast_samples2 = randn(1, NumOfFrame)*noise_sigma + contrast2;
    
    % clip in the [0 1] range
    contrast_samples1(contrast_samples1<0) = 0;
    contrast_samples1(contrast_samples1>1) = 1;
    contrast_samples2(contrast_samples2<0) = 0;
    contrast_samples2(contrast_samples2>1) = 1;
    
elseif PatchType(k) == 0 % Blank
    contrast_samples1 = zeros(1, NumOfFrame);
    contrast_samples2 = zeros(1, NumOfFrame);
    
    % reset the phase of the gabor
    propertiesMat1      = [0, freq, sigma, 0, 1, 0, 0, 0];
    propertiesMat2      = [0, freq, sigma, 0, 1, 0, 0, 0];
end

Gabor_onset = zeros(1, nImg);

% DRAW OTHER IMAGES
for iImg = 1:nImg
    
    % test escape key
    [isKeyDown, keyTime, keyCode] = KbCheck;
    if isKeyDown && keyCode(KbName('ESCAPE')); % press escape to quit the experiment
        exittask = 1;
        break
    end
    
    % Set the contrast of the Gabor for this round
    propertiesMat1(4) = contrast_samples1(iImg); % left
    propertiesMat2(4) = contrast_samples2(iImg); % right
    
    % Increment the phase of our Gabors
    propertiesMat1(1) =  propertiesMat1(1) - degPerFrame;
    propertiesMat2(1) =  propertiesMat2(1) + degPerFrame;
    
    % Set the right blend function for drawing the gabors
    Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
    
    % Batch draw all of the Gabors to screen
    Screen('DrawTexture', window, gabortex, [], allRects1, gaborAngles - 90,...
        [], [], [], [], kPsychDontDoRotation, propertiesMat1');
    
    Screen('DrawTexture', window, gabortex, [], allRects2, gaborAngles - 90,...
        [], [], [], [], kPsychDontDoRotation, propertiesMat2');
    
    % Draw letter at the fixation
    Realisticloc_PlotLetterTask
    
    % Flip our drawing to the screen
    vbl = Screen('Flip', window, vbl + (floor(duration/ifi)-0.5)*ifi);
    Gabor_onset(iImg) = vbl;
end
