function count_sw(info, opt, subj)
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
%  .ndetmet: n of methods to detect bad epochs

%---------------------------%
%-start log
output = sprintf('%s (%04d) began at %s on %s\n', ...
  mfilename, subj, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%---------------------------%
%-constants
STAGES = {'unknown', 'WAKE', 'NREM1', 'NREM2', 'NREM3', 'NREM4', 'REM'};
ARTIFACTS = {'yes', 'no'};
%---------------------------%

%---------------------------%
%-dir and files
ddir = sprintf('%s%04d/%s/%s/', info.data, subj, info.mod, info.nick); % data
dname = sprintf('%s_%s_%04d_%s_%s_*%s.mat', info.nick, info.rec, subj, info.mod, 'sleep', '_A');
dnames = dir([ddir dname]);

if numel(dnames) == 0
  warning(sprintf('could not find any (%s) matching file in %s', dname, ddir))
  return
end
%---------------------------%

%-----------------------------------------------%
if numel(dnames) > 1
  warning(sprintf('found more than one (%s) matching file in %s', dname, ddir))
end

dname = dnames(1).name;
subj_cond = dname(21:27);
load([ddir dname], 'data');

for i_chan = 1:size(data.label, 1)
 chan = data.label{i_chan};

 cfg = [];
 cfg.channel = chan;
 data_chan = ft_selectdata(cfg, data);

 fid = fopen([info.dpsd 'psd_' sprintf('%03d', subj) subj_cond '_' chan '.csv'], 'w');

 n_trl = size(data_chan.trial, 2);
 for i_trl = 1:n_trl

	cfg = [];
	cfg.trials = i_trl;
	cfg.length = 2;
	cfg.overlap = 0.5;

	i_data = ft_redefinetrial(cfg, data_chan);

	cfg = [];
	cfg.method = 'mtmfft';
	cfg.taper = 'hanning';
	freq = ft_freqanalysis(cfg, i_data);

	if i_trl == 1
	 csv_output = ['time, stage, artifact' sprintf(', %.2f', freq.freq) sprintf('\n')];
	 fwrite(fid, csv_output);
	end

	csv_output = [datestr(data_chan.trialinfo(i_trl, 1)) ', '];
  csv_output = [csv_output STAGES{data_chan.trialinfo(i_trl, 2) + 2} ', '];
  csv_output = [csv_output ARTIFACTS{data_chan.trialinfo(i_trl, 3) + 1}];
	csv_output = [csv_output sprintf(', %f', freq.powspctrm(1, :)) sprintf('\n')];

	fwrite(fid, csv_output);
 end

fclose(fid);
end
%-----------------------------------------------%

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
