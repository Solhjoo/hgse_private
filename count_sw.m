function count_sw(info, opt)
%COUNT_SW count number of slow waves
%
% INFO
%  .log
%
% OPT
%  .grp: a struct with fields
%    .subj: index of the subjects
%    .name: name of the group
%  .stage: stage of interest [2 3 4]

%---------------------------%
%-start log
output = sprintf('%s began at %s on %s\n', ...
  mfilename,  datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%-----------------------------------------------%
%-loop over groups
for g = 1:numel(opt.grp)
  
  s_ep_all = nan(numel(opt.stage), numel(opt.grp(g).subj));
  s_ep_good = nan(numel(opt.stage), numel(opt.grp(g).subj));
  s_ep_bad = nan(numel(opt.stage), numel(opt.grp(g).subj));
  s_ep_percent = nan(numel(opt.stage), numel(opt.grp(g).subj));
  
  s_sw_Fpz_ep = nan(numel(opt.stage), numel(opt.grp(g).subj)); % epochs with slow waves
  s_sw_Fpz = nan(numel(opt.stage), numel(opt.grp(g).subj));
  s_sw_Fpz_good = nan(numel(opt.stage), numel(opt.grp(g).subj));
  
  s_sw_Cz_ep = nan(numel(opt.stage), numel(opt.grp(g).subj)); % epochs with slow waves
  s_sw_Cz = nan(numel(opt.stage), numel(opt.grp(g).subj));
  s_sw_Cz_good = nan(numel(opt.stage), numel(opt.grp(g).subj));
  
  %-------------------------------------%
  %-loop over subjects
  for s = 1:numel(opt.grp(g).subj)
    ddir = sprintf('/data1/projects/hgse/hgsesubj/%04d/eeg/hgse/', opt.grp(g).subj(s));
    
    %---------------------------%
    %-full scoring
    dfile = dir([ddir '*_A.mat']);
    load([ddir dfile(1).name])
    
    for st = 1:numel(opt.stage)
      s_ep_all(st,s) = numel(find(data.trialinfo(:,2) == opt.stage(st))); % all epochs
      s_ep_good(st,s) = numel(find(data.trialinfo(:,2) == opt.stage(st) & data.trialinfo(:,3) == 1)); % good epochs
      s_ep_bad(st,s) = s_ep_all(st,s) - s_ep_good(st,s); % bad epochs
      s_ep_percent(st,s) = s_ep_bad(st,s) / s_ep_all(st,s) * 100; % percentage bad
    end
    %---------------------------%
    
    %---------------------------%
    %-slow wave detected
    dfile = dir([ddir '*-Fpz_A_B.mat']);
    if ~isempty(dfile)
      load([ddir dfile(1).name])
      for st = 1:numel(opt.stage)
        s_sw_Fpz_ep(st,s) = numel(unique(data.trialinfo( data.trialinfo(:,2) == opt.stage(st),1))); % number of epochs with slow waves
        s_sw_Fpz(st,s) = numel(find(data.trialinfo(:,2) == opt.stage(st)));
      end
    end
    
    dfile = dir([ddir '*-Cz_A_B.mat']);
    if ~isempty(dfile)
      load([ddir dfile(1).name])
      for st = 1:numel(opt.stage)
        s_sw_Cz_ep(st,s) = numel(unique(data.trialinfo( data.trialinfo(:,2) == opt.stage(st),1))); % number of epochs with slow waves
        s_sw_Cz(st,s) = numel(find(data.trialinfo(:,2) == opt.stage(st)));
      end
    end
    %---------------------------%
    
    %---------------------------%
    %-only good slow waves
    dfile = dir([ddir '*-Fpz_A_B_C.mat']);
    if ~isempty(dfile)
      load([ddir dfile(1).name])
      for st = 1:numel(opt.stage)
        s_sw_Fpz_good(st,s) = numel(find(data.trialinfo(:,2) == opt.stage(st)));
      end
    end
    
    dfile = dir([ddir '*-Cz_A_B_C.mat']);
    if ~isempty(dfile)
      load([ddir dfile(1).name])
      for st = 1:numel(opt.stage)
        s_sw_Cz_good(st,s) = numel(find(data.trialinfo(:,2) == opt.stage(st)));
      end
    end
    %---------------------------%
    
  end
  %-------------------------------------%
  
  %-------------------------------------%
  %-output
  output = [output sprintf('\n--------------------------------------------------\n')];
  output = [output sprintf('GROUP SUMMARY: %s\n', opt.grp(g).name)];
  output = [output sprintf('--------------------------------------------------\n')];
  
  for st = 1:numel(opt.stage)
    
    chan = {'Fpz' ' Cz'};
    
    %---------------------------%
    %-values
    scored_min{1} = s_ep_good(st,:) / 2;
    scored_min{2} = s_ep_good(st,:) / 2; % identical for both electrodes
    sw_min{1} = s_sw_Fpz_ep(st,:) / 2;
    sw_num{1} = s_sw_Fpz(st,:);
    sw_den{1} = sw_num{1} ./ sw_min{1};
    sw_min{2} = s_sw_Cz_ep(st,:) / 2;
    sw_num{2} = s_sw_Cz(st,:);
    sw_den{2} = sw_num{2} ./ sw_min{2};
    
    goodsw_num{1} = s_sw_Fpz_good(st,:);
    goodsw_num{2} = s_sw_Cz_good(st,:);
    rejerate{1} = (sw_num{1} - goodsw_num{1}) ./ sw_num{1} * 100;
    rejerate{2} = (sw_num{2} - goodsw_num{2}) ./ sw_num{2} * 100;
    %---------------------------%
    
    for c = 1:numel(chan)
      
      %---------------------------%
      %-header
      output = [output sprintf('---\nSTAGE %d / Chan %s\n', opt.stage(st), chan{c})];
      output = [output sprintf(['Scored min (    s.d.,  n) ' ...
        '- %s sw min (    s.d.,  n) - %s sw num (    s.d.,  n) - %s density (   s.d.,  n) - %s goodsw (    s.d.,  n) - %s reject (    s.d.,  n)'], ...
        chan{c}, chan{c}, chan{c}, chan{c})];
      output = [output sprintf('\n')];
      %---------------------------%
      
      %---------------------------%
      %-values printed
      output = [output sprintf('  % 8.2f (% 8.2f,% 3d)', ...
        nanmean(scored_min{c},3), nanstd(scored_min{c},[],3), numel(find(~isnan(scored_min{c}))))];
      output = [output sprintf(' -   % 8.2f (% 8.2f,% 3d)', ...
        nanmean(sw_min{c},3), nanstd(sw_min{c},[],3), numel(find(~isnan(sw_min{c}))))];
      output = [output sprintf(' -   % 8.2f (% 8.2f,% 3d)', ...
        nanmean(sw_num{c},3), nanstd(sw_num{c},[],3), numel(find(~isnan(sw_num{c}))))];
      output = [output sprintf(' -   % 8.2f (% 8.2f,% 3d)', ...
        nanmean(sw_den{c},3), nanstd(sw_den{c},[],3), numel(find(~isnan(sw_den{c}))))];
      output = [output sprintf(' -   % 8.2f (% 8.2f,% 3d)', ...
        nanmean(goodsw_num{c},3), nanstd(goodsw_num{c},[],3), numel(find(~isnan(goodsw_num{c}))))];
      output = [output sprintf(' -   % 8.2f (% 8.2f,% 3d)', ...
        nanmean(rejerate{c},3), nanstd(rejerate{c},[],3), numel(find(~isnan(rejerate{c}))))];
      
      output = [output sprintf('\n')];
      %---------------------------%
      
    end
    
  end
  %-------------------------------------%
  
  %-------------------------------------%
  %-output for excel
  output = [output sprintf('\n--------------------------------------------------\n')];
  output = [output sprintf('GROUP EXCEL: %s\n', opt.grp(g).name)];
  output = [output sprintf('--------------------------------------------------\n')];
  
  sw_col = [opt.grp(g).subj
    sum(s_ep_all)
    sum(s_ep_good)
    sum(s_ep_bad)
    sum(s_ep_percent)
    sum(s_sw_Fpz_ep)
    sum(s_sw_Fpz)
    (sum(s_sw_Fpz) ./ sum(s_sw_Fpz_ep) /2)
    sum(s_sw_Fpz_good)
    ((sum(s_sw_Fpz) - sum(s_sw_Fpz_good)) ./ sum(s_sw_Fpz) * 100)
    sum(s_sw_Cz_ep)
    sum(s_sw_Cz)
    (sum(s_sw_Cz) ./ sum(s_sw_Cz_ep) /2)
    sum(s_sw_Cz_good)
    ((sum(s_sw_Cz) - sum(s_sw_Cz_good)) ./ sum(s_sw_Cz) * 100)
    ];
  output = [output sprintf(['subjid\tscored epochs\tscored epochs (good)\tscored epochs (bad)\tpercent bad epochs\t' ...
    'epochs with at least one Fpz sw\tn sw at Fpz\tsw density at Fpz (sw per min)\tn good sw at Fpz\tn percent bad sw at Fpz\t', ...
    'epochs with at least one Cz sw\tn sw at Cz\tsw density at Cz (sw per min)\tn good sw at Cz\tn percent bad sw at Cz\n'])];
  output = [output sprintf('% 5d\t% 5d\t% 5d\t% 5d\t% 6.2f\t% 5d\t% 5d\t% 6.2f\t% 5d\t% 6.2f\t% 5d\t% 5d\t% 6.2f\t% 5d\t% 6.2f\n', sw_col)];
  %-------------------------------------%
  
end
%-----------------------------------------------%

%---------------------------%
%-end log
toc_t = toc(tic_t);
outtmp = sprintf('%s ended at %s on %s after %s\n\n', ...
  mfilename, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'), ...
  datestr( datenum(0, 0, 0, 0, 0, toc_t), 'HH:MM:SS'));
output = [output outtmp];

%-----------------%
fprintf(output)
fid = fopen([info.log '.txt'], 'a');
fwrite(fid, output);
fclose(fid);
%-----------------%
%---------------------------%