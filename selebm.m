function selebm(cfg, subj)
%SELEBM read children's data and convert them into fieldtrip format
% It creates the normal subject structure.
% The file names contains information on the condition the child was
% assigned to (c) and the unit of the child (u)
%
% CFG
%  .proj: project name
%  .data: name of projects/PROJNAME/subjects/
%  .mod: name of the modality used in recordings and projects
%  .cond: name to be used in projects/PROJNAME/subjects/0001/MOD/CONDNAME/
%  .recs: folder with the original children's recordings
% 
% Part of HGSE_PRIVATE
% See also EBM2FT

%---------------------------%
%-start log
output = sprintf('(p%02.f) %s started at %s on %s\n', ...
  subj, mfilename,  datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%---------------------------%
%-dir and files
ddir = sprintf('%s%04.f/%s/%s/', cfg.data, subj, cfg.mod, cfg.cond); % data
if isdir(ddir); rmdir(ddir, 's'); end
mkdir(ddir)

[cond unit] = getblind(subj);
dfile = sprintf('%s_%04.f_%s_%s_c%1.f_u%02.f_%s', cfg.proj, subj, cfg.mod, 'sleep', cond, unit, mfilename);
%---------------------------%

%---------------------------%
%-read data
data = ebm2ft(subj, cfg.recs);
save([ddir dfile], 'data')
%---------------------------%

%---------------------------%
%-some feedback
outtmp = sprintf('stage awake:% 4.f\nstage NREM1:% 4.f\nstage NREM2:% 4.f\nstage NREM3:% 4.f\nstage NREM4:% 4.f\nstage REM  :% 4.f\nmovement   :% 4.f\n\n', ...
  numel(find(data.trialinfo(:,2)==0)), ...
  numel(find(data.trialinfo(:,2)==1)), ...
  numel(find(data.trialinfo(:,2)==2)), ...
  numel(find(data.trialinfo(:,2)==3)), ...
  numel(find(data.trialinfo(:,2)==4)), ...
  numel(find(data.trialinfo(:,2)==5)), ...
  numel(find(data.trialinfo(:,2)==6)));
output = [output outtmp];

outtmp = sprintf('good epochs:% 4.f\n bad epochs:% 4.f\n\n', ...
  numel(find(data.trialinfo(:,3)==0)), ...
  numel(find(data.trialinfo(:,3)==1)));
output = [output outtmp];
%---------------------------%

%---------------------------%
%-end log
toc_t = toc(tic_t);
outtmp = sprintf('(p%02.f) %s ended at %s on %s after %s\n\n', ...
  subj, mfilename, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'), ...
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
