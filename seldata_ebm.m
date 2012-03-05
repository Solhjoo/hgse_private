function seldata_ebm(cfg, subj)
%SELDATA_EBM read children's data and convert them into fieldtrip format
% It creates the normal subject structure.
% The file names contains information on the condition the child was
% assigned to (c) and the unit of the child (u)
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
dfile = sprintf('%s_%04.f_%s_%s_c%1.f_u%02.f', cfg.proj, subj, cfg.mod, 'sleep', cond, unit);
%---------------------------%

%---------------------------%
%-read data
data = ebm2ft(subj, cfg.recs);
save([ddir dfile], 'data')
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

