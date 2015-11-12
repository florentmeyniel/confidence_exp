Screen('Preference', 'SkipSyncTests', 0);
screenid = max(Screen('Screens'));
win = Screen('OpenWindow', screenid, 0,[512 384 1024 768]);   
%win = Screen('OpenWindow', screenid, 0);   

LoadIdentityClut(win);
1
% WaitSecs(1);

% load mygammatable
% Screen('LoadNormalizedGammaTable', win, mygammatable);
% 2
% % WaitSecs(1);
% 
% identitygammatable=repmat((0:255)/255,3,1)';
% Screen('LoadNormalizedGammaTable', win, identitygammatable);
% 3
% WaitSecs(1);

Screen('CloseAll')
