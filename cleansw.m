function cleansw(cfg, subj)
%CLEANSW reject slow wave events if they are too noisy
%
% CFG
%  .data: path of /data1/projects/PROJ/subjects/
%  .nick: NICK in /data1/projects/PROJ/subjects/0001/MOD/NICK/
%  .mod: modality, MOD in /data1/projects/PROJ/subjects/0001/MOD/NICK/
%  .endname: includes preprocessing steps (e.g. '_seldata_gclean')
%
%  .log: name of the file and directory to save log
%
%  .cleansw.auto(1).met: method to automatically find bad
%                                    channels ('var' 'range' 'diff')
%  .cleansw.auto(1).thr: in microvolts (10000, 3000, 1000)
%
% IN
%  data in /data1/projects/PROJ/subjects/SUBJ/MOD/NICK/
%
% OUT
%  data, where noisy events have been rejected
%  but if all the epochs are rejected, it does not save data at all
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
dname = sprintf('%s_%s_%04d_%s_%s_*%s.mat', cfg.nick, cfg.rec, subj, cfg.mod, 'sleep', cfg.endname);
dnames = dir([ddir dname]);

if numel(dnames) == 0
  warning(sprintf('could not find any (%s) matching file in %s', dname, ddir))
  return
end
%---------------------------%

%-----------------------------------------------%
%-loop over files
for i = 1:numel(dnames)
  
  %--------------------------%
  %-data file
  dfile = dnames(i).name;
  load([ddir dfile], 'data')
  
  basicname = dfile(1:strfind(dfile, cfg.endname)-1);
  outputfile = [basicname cfg.endname '_' mfilename];
  
  output = sprintf('%s\n%s\n', output, dfile);
  %--------------------------%
  
  %-------------------------------------%
  %-loop over epoch
  oktrial = true(numel(data.trial), 3);
  val = NaN(numel(data.trial), 3); % three methods
  
  for e = 1:numel(data.trial)
    
    %--------------------------%
    %-reject channels with difference methods
    for m = 1:numel(cfg.cleansw.auto)
      
      %------------------%
      %-automatic (above threshold in variance)
      switch cfg.cleansw.auto(m).met
        case 'var'
          %-------%
          %-compute var
          allchan = std([data.trial{e}], [], 2).^2;
          %-------%
          
        case 'range'
          %-------%
          %-compute range
          alldat = [data.trial{e}];
          allchan = range(alldat,2);
          %-------%
          
        case 'diff'
          %-------%
          %-compute range
          alldat = [data.trial{e}];
          allchan = max(abs(diff(alldat')))';
          %-------%
          
      end
      %------------------%
      
      %------------------%
      %-check threshold
      val(e, m) = allchan;
      if allchan > cfg.cleansw.auto(m).thr
        oktrial(e, m) = false;
      end
      %------------------%
      
    end
    %--------------------------%
    
  end
  %-------------------------------------%
  
  %--------------------------%
  %-output
  for m = 1:numel(cfg.cleansw.auto)
    
    outtmp = sprintf('    with %s (% 6d), rejected epochs #% 4d out of% 4d (min % 5.2f, median % 5.2f, mean % 5.2f, std % 5.2f, max % 5.2f)\n', ...
      cfg.cleansw.auto(m).met, cfg.cleansw.auto(m).thr, numel(find(~oktrial(:,m))), numel(oktrial(:,m)), ...
      min(val(:,m)), median(val(:,m)), mean(val(:,m)), std(val(:,m)), max(val(:,m)));
    output = [output outtmp];
    
  end
  %--------------------------%
  
  %--------------------------%
  %-get good trials
  oktrial = all(oktrial,2);
  if ~any(oktrial)
    output = sprintf('%sThe whole dataset of% 4d epochs was rejected!!!\n', output, numel(data.trial));
    return
  end
  output = sprintf('%s  good epochs #% 5d, bad epochs #% 5d\n', ...
    output, numel(find(oktrial)), numel(find(~oktrial)));
  %--------------------------%
  
  %--------------------------%
  %-clean up data
  data.trial = data.trial(oktrial);
  data.time = data.time(oktrial);
  data.sampleinfo = data.sampleinfo(oktrial,:);
  data.trialinfo = data.trialinfo(oktrial,:);
  %--------------------------%
  
  %--------------------------%
  %-save
  save([ddir outputfile], 'data')
  %--------------------------%
  
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
fid = fopen([cfg.log '.txt'], 'a');
fwrite(fid, output);
fclose(fid);
%-----------------%
%---------------------------%