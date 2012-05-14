function selebm(cfg, subj)
%SELEBM read children's data and convert them into fieldtrip format
% It creates the normal subject structure.
% The file names contains information on the condition the child was
% assigned to (c) and the unit of the child (u)
%
% CFG
%  .rec: name of the recording (it's '')
%  .data: name of projects/PROJ/subjects/
%  .mod: name of the modality used in recordings and projects
%  .nick name to be used in projects/PROJ/subjects/0001/MOD/NICK/
%  .recs: folder with the original children's recordings
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
if isdir(ddir); rmdir(ddir, 's'); end
mkdir(ddir)

[cond unit] = getblind(subj);
dfile = sprintf('%s_%s_%04d_%s_%s_c%1d_u%02d_%s', cfg.nick, cfg.rec, subj, cfg.mod, 'sleep', cond, unit, mfilename);
%---------------------------%

%---------------------------%
%-read data
data = ebm2ft(subj, cfg.recs);
save([ddir dfile], 'data')
%---------------------------%

%---------------------------%
%-some feedback
outtmp = sprintf('stage awake:% 4d\nstage NREM1:% 4d\nstage NREM2:% 4d\nstage NREM3:% 4d\nstage NREM4:% 4d\nstage REM  :% 4d\nmovement   :% 4d\n\n', ...
  numel(find(data.trialinfo(:,2)==0)), ...
  numel(find(data.trialinfo(:,2)==1)), ...
  numel(find(data.trialinfo(:,2)==2)), ...
  numel(find(data.trialinfo(:,2)==3)), ...
  numel(find(data.trialinfo(:,2)==4)), ...
  numel(find(data.trialinfo(:,2)==5)), ...
  numel(find(data.trialinfo(:,2)==6)));
output = [output outtmp];

outtmp = sprintf('good epochs:% 4d\n bad epochs:% 4d\n\n', ...
  numel(find(data.trialinfo(:,3)==0)), ...
  numel(find(data.trialinfo(:,3)==1)));
output = [output outtmp];
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

%---------------------------%
%-subjfunction
function [cond unit] = getblind(subj)

blind = [1	31
2	27
3	12
11	17
12	14
13	16
21	21
22	30
23	9
31	7
32	3
33	22
41	25
42	15
43	23
51	19
52	11
53	4
61	28
62	18
63	10
71	2
72	6
73	24
81	5
82	26
83	20
91	29
92	32
93	8
111	13
112	1];

i = blind(:,2) == subj;

unit = floor(blind(i,1)/ 10);
cond = mod(blind(i,1), 10);
%---------------------------%
