function redefsw(info, opt, subj)
%REDEFSW detect slow waves and create trials around them
%
% INFO
%  .rec: name of the recording (it's '')
%  .data: name of projects/PROJ/subjects/
%  .mod: name of the modality used in recordings and projects
%  .nick: name to be used in projects/PROJ/subjects/0001/MOD/NICK/
%
% OPT
%  .redefsw.stage: stage of interest
%  .redefsw.rejart: reject artifacts or not (logical)
% 
%  .redefsw.sw: a structure, used for slow wave detection as detect_slowwave(opt.redefsw.sw, data)
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
ddir = sprintf('%s%04d/%s/%s/', info.data, subj, info.mod, info.nick); % data
dname = sprintf('%s_%s_%04d_%s_%s_*%s.mat', info.nick, info.rec, subj, info.mod, 'sleep', 'A');
dnames = dir([ddir dname]);

if numel(dnames) ~= 0
  dfile = dnames(1).name;
  load([ddir dfile], 'data')
  basicname = dfile(1:end-6);
else
  warning(sprintf('could not find any (%s) matching file in %s', dname, ddir))
  return
end
%---------------------------%

%---------------------------%
%-stage, no artifacts
%-----------------%
%-count epochs
ep = ismember(data.trialinfo(:,2), opt.redefsw.stage);
n_ep = numel(find(ep));

epa = ep & data.trialinfo(:,3) == 1; % ep, with OK epochs
n_epa = numel(find(epa));

outtmp = sprintf('Epochs in stages of interest:% 4d\nEpochs without artifacts:%4d\n', n_ep, n_epa);
output = [output outtmp];
%-----------------%

%-----------------%
%-select epochs
cfg = [];
if opt.redefsw.rejart
  cfg.trials = epa; % without artifacts
else
  cfg.trials = ep; % with artifact
end
data = ft_redefinetrial(cfg, data);
%-----------------%
%---------------------------%

%---------------------------%
%-detect slow wave (per channel)
for i = 1:numel(data.label)
  
  cfg = opt.redefsw.sw;
  
  cfg.roi(1).name = data.label{i};
  cfg.roi(1).chan = data.label(i);
  
  sw{i} = detect_slowwave(cfg, data);
  
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
  trl(:,1) = [sw{i}.(opt.redefsw.event)]' - .5 * dataorig.fsample * opt.redefsw.dur;
  trl(:,2) = [sw{i}.(opt.redefsw.event)]' + .5 * dataorig.fsample * opt.redefsw.dur - 1;
  trl(:,3) = - .5 * dataorig.fsample * opt.redefsw.dur;
  %-----------------%
  
  %-----------------%
  %-only keep trials which are in the data
  goodtrl = false(size(trl,1), 1);
  for t = 1:size(trl,1)
    goodtrl(t) = any(trl(t,1) >= dataorig.sampleinfo(:,1) & trl(t,2) <= dataorig.sampleinfo(:,2));
  end
  trl = trl(goodtrl,:);
  
  data = ft_selectdata(dataorig, 'channel', i);
  cfg = [];
  cfg.trl = trl;
  data = ft_redefinetrial(cfg, data);
  %-----------------%
  
  %-------%
  %-feedback
  outtmp = sprintf('final number of trials at channel %s:% 4d\n', dataorig.label{i}, size(trl,1));
  output = [output outtmp];
  %-------%
  
  %-----------------%
  %-save
  outputfile = [basicname '-' dataorig.label{i} '_A_B'];
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
fid = fopen([info.log '.txt'], 'a');
fwrite(fid, output);
fclose(fid);
%-----------------%
%---------------------------%