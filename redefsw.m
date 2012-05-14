function redefsw(cfg, subj)
%REDEFSW detect slow waves and create trials around them
%
% CFG
%  .proj: project name
%  .data: name of projects/PROJ/subjects/
%  .mod: name of the modality used in recordings and projects
%  .nick: name to be used in projects/PROJ/subjects/0001/MOD/NICK/
%
%  .redefsw.stage: stage of interest
%  .redefsw.rejart: reject artifacts or not (logical)
% 
%  .redefsw.sw: a structure, used for slow wave detection as detect_slowwave(cfg.redefsw.sw, data)
%  .redefsw.event: 'negpeak_iabs' (take it from detect_slowwave, should end in '_iabs')
%  .redefsw.dur: total duration of the trial
%
% Part of HGSE_PRIVATE
% See also SELEBM, REDEFSW, CLEANSW

%---------------------------%
%-start log
output = sprintf('%s (%04d) began at %s on %s\n', ...
  mfilename, subj, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%---------------------------%
%-dir and files
ddir = sprintf('%s%04d/%s/%s/', cfg.data, subj, cfg.mod, cfg.nick); % data
dname = sprintf('%s_%04d_%s_%s_*%s.mat', cfg.proj, subj, cfg.mod, 'sleep', cfg.endname);
dnames = dir([ddir dname]);

if numel(dnames) ~= 0
  dfile = dnames(1).name;
  load([ddir dfile], 'data')
  basicname = dfile(1:strfind(dfile, cfg.endname)-1);
else
  warning(sprintf('could not find any (%s) matching file in %s', dname, ddir))
  return
end
%---------------------------%

%---------------------------%
%-stage, no artifacts
%-----------------%
%-count epochs
ep = ismember(data.trialinfo(:,2), cfg.redefsw.stage);
n_ep = numel(find(ep));

epa = ep & data.trialinfo(:,3) ~= 1; % ep, no artifacts
n_epa = numel(find(epa));

outtmp = sprintf('Epochs in stages of interest:% 4d\nEpochs without artifacts:%4d\n', n_ep, n_epa);
output = [output outtmp];
%-----------------%

%-----------------%
%-select epochs
cfg1 = [];
if cfg.redefsw.rejart
  cfg1.trials = epa; % without artifacts
else
  cfg1.trials = ep; % with artifact
end
data = ft_redefinetrial(cfg1, data);
%-----------------%
%---------------------------%

%---------------------------%
%-detect slow wave (per channel)
for i = 1:numel(data.label)
  
  cfg2 = cfg.redefsw.sw;
  
  cfg2.roi(1).name = data.label{i};
  cfg2.roi(1).chan = data.label(i);
  
  sw{i} = detect_slowwave(cfg2, data);
  
  %-------%
  %-feedback
  outtmp = sprintf('% 4d slow waves in %s\n', numel(sw{i}), data.label{i});
  output = [output outtmp];
  %-------%
  
end
%---------------------------%

%---------------------------%
%-create events
dataorig = data;
for i = 1:numel(dataorig.label)
  
  %-----------------%
  %-create trials
  trl = [];
  trl(:,1) = [sw{i}.(cfg.redefsw.event)]' - .5 * dataorig.fsample * cfg.redefsw.dur;
  trl(:,2) = [sw{i}.(cfg.redefsw.event)]' + .5 * dataorig.fsample * cfg.redefsw.dur - 1;
  trl(:,3) = - .5 * dataorig.fsample * cfg.redefsw.dur;
  %-----------------%
  
  %-----------------%
  %-only keep trials which are in the data
  goodtrl = false(size(trl,1), 1);
  for t = 1:size(trl,1)
    goodtrl(t) = any(trl(t,1) >= dataorig.sampleinfo(:,1) & trl(t,2) <= dataorig.sampleinfo(:,2));
  end
  trl = trl(goodtrl,:);
  
  data = ft_selectdata(dataorig, 'channel', i);
  cfg3 = [];
  cfg3.trl = trl;
  data = ft_redefinetrial(cfg3, data);
  %-----------------%
  
  %-------%
  %-feedback
  outtmp = sprintf('final number of trials at channel %s:% 4d\n', dataorig.label{i}, size(trl,1));
  output = [output outtmp];
  %-------%
  
  %-----------------%
  %-save
  outputfile = [basicname '-' dataorig.label{i} cfg.endname '_' mfilename];
  save([ddir outputfile], 'data')
  %-----------------%
  
end
%---------------------------%

%---------------------------%
%-end log
toc_t = toc(tic_t);
outtmp = sprintf('%s (%04d) ended at %s on %s after %s\n\n', ...
  mfilename, subj, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'), ...
  datestr( datenum(0, 0, 0, 0, 0, toc_t), 'HH:MM:SS'));
output = [output outtmp];

%-----------------%
fprintf(output)
fid = fopen([cfg.log '.txt'], 'a');
fwrite(fid, output);
fclose(fid);
%-----------------%
%---------------------------%