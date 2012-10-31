function [data] = ebm2ft(subj, recdir)
%EBM2FT read embla folder and transform into fieldtrip dataset
% Use as:
%   [data] = ebm2ft(subj)
% where subj is the number of the subject
%
% Optionally, you can use as:
%   [data] = ebm2ft(subj, recdir)
% where recdir specifies the directory with the data

epdur = 30;
scaling = 1e6; % V into uV

%-------------------------------------%
%-dir and files
if nargin == 1
  recdir = '/data/projects/hgse/BLIND/';
end
channels = {'Fpz' 'Cz'};

sdir = sprintf('%s%02.f/', recdir, subj);
%-------------------------------------%

%-------------------------------------%
%-read events
evt = readevents([sdir 'Events.txt']);
art = readevents([sdir 'Eventa.txt']);

if ~isempty(setxor([evt.timestamp], [art.timestamp]))
  %-----------------%
  %-remove missing timestamps
  n_evt = numel([evt.timestamp]);
  n_art = numel([art.timestamp]);
  
  [~, e, a] = intersect([evt.timestamp], [art.timestamp]);
  evt.state = evt.state(e);
  evt.statedescription = evt.statedescription(e);
  evt.timestamp = evt.timestamp(e);
  evt.timedescription = evt.timedescription(e);
  
  artstate = art.state(e);
  art.statedescription = art.statedescription(e);
  art.timestamp = art.timestamp(e);
  art.timedescription = art.timedescription(e);
  %-----------------%
  
  warning(sprintf(['time stamps of Events.txt and Eventa.txt do not match\n' ...
    'There were% 4.f events and% 4.f artifacts, now% 4.f events and% 4.f artifacts\n'], ...
    n_evt, n_art, numel(evt.timestamp), numel(art.timestamp)))
end
%-------------------------------------%

%-------------------------------------%
%-subj 12, at 7:00:40, time is repeated:
% S2	07:00:40	SLEEP-S2	30
% S2	07:00:40	SLEEP-S0	30
% Also note the discrepancy between 'S2' in the 1st column and 'SLEEP-S0'
% in the 3rd column
d_evt = find(diff(evt.timestamp) == 0);

if ~isempty(d_evt)
  evt.timestamp(d_evt) = [];
  evt.state(d_evt) = [];
  evt.timedescription(d_evt) = [];
  evt.statedescription(d_evt) = [];
  evt.stopepoch = evt.stopepoch - numel(d_evt);
  
  warning('removed %d duplicated epoch', numel(d_evt));
  
end
%-------------------------------------%

%-------------------------------------%
%-read data for each channels
for c = 1:numel(channels)
  
  chanfile = dir([sdir channels{c} '*.ebm']);
  if ~isempty(chanfile)
    [dat{c}, hdr] = ebmread( [sdir chanfile(1).name]);
  end
end

fs = hdr.samplingrate;
%-------------------------------------%

%-------------------------------------%
%-create fieldtrip data
data = [];
data.fsample = fs;

for c = 1:numel(dat)
  data.label{c,1} = channels{c};
end

%-----------------%
%-trial loop
for i = 1:numel(evt.state)
  
  offsec = ceil(date2sec( evt.timestamp(i) - hdr.starttime)); % offset in seconds
  begsmp = offsec * hdr.samplingrate + 1;
  endsmp = (offsec + epdur) * hdr.samplingrate;

  for c = 1:numel(dat)
    data.trial{i}(c, :) = dat{c}(begsmp:endsmp) * scaling;
  end
  data.time{i} = offsec + (0:1/fs: (epdur-1/fs));
  
  data.sampleinfo(i, :) = [begsmp endsmp];
  data.trialinfo(i, :) = [evt.timestamp(i) evt.state(i) art.state(i)];
  
end
%-----------------%
%-------------------------------------%

function [sec] = date2sec(fulldate)
sec = 24*60*60*fulldate;