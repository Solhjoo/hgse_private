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
  
  summary = nan(numel(opt.stage), 8, numel(opt.grp(g).subj));
  
  %-------------------------------------%
  %-loop over subjects
  for s = 1:numel(opt.grp(g).subj)
    ddir = sprintf('/data1/projects/hgse/hgsesubj/%04d/eeg/hgse/', opt.grp(g).subj(s));
    
    %---------------------------%
    %-full scoring
    dfile = dir([ddir '*_A.mat']);
    load([ddir dfile(1).name])
    
    for st = 1:numel(opt.stage)
      summary(st,1,s) = opt.stage(st); % stage
      summary(st,2,s) = numel(find(data.trialinfo(:,2) == opt.stage(st))); % all epochs
    end
    %---------------------------%
    
    %---------------------------%
    %-slow wave detected
    dfile = dir([ddir '*-Fpz_A_B.mat']);
    if ~isempty(dfile)
      load([ddir dfile(1).name])
      for st = 1:numel(opt.stage)
        summary(st,3,s) = numel(unique(data.trialinfo( data.trialinfo(:,2) == opt.stage(st),1))); % number of epochs with slow waves
        summary(st,4,s) = numel(find(data.trialinfo(:,2) == opt.stage(st)));
      end
    end
    
    dfile = dir([ddir '*-Cz_A_B.mat']);
    if ~isempty(dfile)
      load([ddir dfile(1).name])
      for st = 1:numel(opt.stage)
        summary(st,5,s) = numel(unique(data.trialinfo( data.trialinfo(:,2) == opt.stage(st),1))); % number of epochs with slow waves
        summary(st,6,s) = numel(find(data.trialinfo(:,2) == opt.stage(st)));
      end
    end
    %---------------------------%
    
    %---------------------------%
    %-only good slow waves
    dfile = dir([ddir '*-Fpz_A_B_C.mat']);
    if ~isempty(dfile)
      load([ddir dfile(1).name])
      for st = 1:numel(opt.stage)
        summary(st,7,s) = numel(find(data.trialinfo(:,2) == opt.stage(st)));
      end
    end
    
    dfile = dir([ddir '*-Cz_A_B_C.mat']);
    if ~isempty(dfile)
      load([ddir dfile(1).name])
      for st = 1:numel(opt.stage)
        summary(st,8,s) = numel(find(data.trialinfo(:,2) == opt.stage(st)));
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
    scored_min{1} = summary(st,2,:) * 2;
    scored_min{2} = summary(st,2,:) * 2; % identical for both electrodes
    sw_min{1} = summary(st,3,:) * 2;
    sw_num{1} = summary(st,4,:);
    sw_den{1} = sw_num{1} ./ sw_min{1};
    sw_min{2}  = summary(st,5,:) * 2;
    sw_num{2}  = summary(st,6,:);
    sw_den{2}  = sw_num{2} ./ sw_min{2};
    
    goodsw_num{1} = summary(st,7,:);
    goodsw_num{2} = summary(st,8,:);
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
  
  %---------------------------%
  %-all slow waves
  sw_all{1} = squeeze(sum(summary(:,4,:),1));
  sw_all{2} = squeeze(sum(summary(:,6,:),1));
  
  for c = 1:numel(chan)
    output = [output sprintf('---\nChan %s\n', chan{c})];
    id_sw = cat(1, opt.grp(g).subj, squeeze(sw_all{c})');
    output = [output sprintf('% 5d\t% 5d\n', id_sw)];
  end
  %---------------------------%
  
  %---------------------------%
  %-only good slow waves
  sw_good{1} = squeeze(sum(summary(:,7,:),1));
  sw_good{2} = squeeze(sum(summary(:,8,:),1));
  for c = 1:numel(chan)
    output = [output sprintf('---\nChan %s\n', chan{c})];
    id_sw = cat(1, opt.grp(g).subj, squeeze(sw_all{c})');
    output = [output sprintf('% 5d\t% 5d\n', id_sw)];
  end
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