% Get the directory where data are saved (from the workspace) and get key
% statistics for checking between sessions.

if ~exist('datadir', 'var')
    fprintf('datadir is unknown!!')
    return
end

dirlist = dir([datadir, '/session_results_sess_*.mat']);
dirname = arrayfun(@(x) x.name, dirlist, 'UniformOutput', false);
dirdate = arrayfun(@(x) x.datenum, dirlist);
lastestfile = dirname(dirdate == max(dirdate));
dat = load([datadir, '/', lastestfile{1}]);
fprintf('\n\n QUICK SUMMARY for file:\n\t%s\n', lastestfile{1})

% (perf, thd, % rep R, RT)
% get structure of results
results = dat.session_struct.results;

% get mean RT
RT = arrayfun(@(x) x.choice_rt, results);
fprintf('\n mean RT ...... %3.2f', nanmean(RT));

% get last threshold
fprintf('\n last thd: .... %4.3f', results(end).diff_cont)

% get performance
correct = arrayfun(@(x) x.correct, results);
fprintf('\n perf: ........ %3.2f', nanmean(correct))

% get fraction of left rest
left_resp = arrayfun(@(x) x.response, results);
fprintf('\n fract. L resp: %3.2f', nanmean(left_resp));

% get fraction of high conf
h_conf = arrayfun(@(x) x.confidence, results);
fprintf('\n fract. H conf: %3.2f', nanmean(h_conf));

% get number of miss responses
fprintf('\n fract. miss:   %3.2f', mean(isnan(left_resp)));


% get distribution of rest
LH = sum(left_resp(~isnan(left_resp))  & h_conf(~isnan(left_resp)));
LL = sum(left_resp(~isnan(left_resp))  & ~h_conf(~isnan(left_resp)));
RH = sum(~left_resp(~isnan(left_resp)) & h_conf(~isnan(left_resp)));
RL = sum(~left_resp(~isnan(left_resp)) & ~h_conf(~isnan(left_resp)));
fprintf('\n distrubition Lh_Hc Lh_Lc Rh_Lc Rh_Hc')
fprintf('\n             %4.0f  %4.0f  %4.0f  %4.0f \n', LH, LL, RL, RH) 






