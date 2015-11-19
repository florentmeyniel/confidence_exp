% Define the key code

quit = KbName('ESCAPE');

if IsfMRI == 0
    resp_L_conf_H = KbName('a');
    resp_L_conf_L = KbName('z');
    resp_R_conf_L = KbName('o');
    resp_R_conf_H = KbName('p');
else
    resp_L_conf_H = KbName(',<'); % this is the comma key, after 'UnifyKeyNames
    resp_L_conf_L = KbName('r');
    resp_R_conf_L = KbName('g');
    resp_R_conf_H = KbName('y');
    key_scanOnset = KbName('t');
end
