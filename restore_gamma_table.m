function restore_gamma_table

% A work-around to restore the original gamma table.

Screen('Preference', 'SkipSyncTests', 0);
screenid = max(Screen('Screens'));
win = Screen('OpenWindow', screenid, 0,[512 384 1024 768]);   
%win = Screen('OpenWindow', screenid, 0);   

LoadIdentityClut(win);
Screen('CloseAll')
