% Define the key code

quit = KbName('ESCAPE');

if ~IsfMRI
    resp_L_conf_H = KbName('a');
    resp_L_conf_L = KbName('z');
    resp_R_conf_L = KbName('o');
    resp_R_conf_H = KbName('p');
else
    resp_L_conf_H = ',<'; % this is the comma key, after 'UnifyKeyNames
    resp_L_conf_L = 'r';
    resp_R_conf_L = 'g';
    resp_R_conf_H = 'y';
end
