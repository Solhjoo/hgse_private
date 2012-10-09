function count_sw(cfg)
%COUNT_SW count number of slow waves

%---------------------------%
%-start log
output = sprintf('%s began at %s on %s\n', ...
  mfilename,  datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

for g = 1:numel(cfg.count.grp)
  
  sw = nan(numel(cfg.count.grp(g).subj), numel(cfg.count.chan));
  
  %-------------------------------------%
  %-loop over subjects
  cnt = 0;
  for subj = cfg.count.grp(g).subj
    cnt = cnt + 1;
    
    ddir = sprintf('%s%04d/%s/%s/', cfg.data, subj, cfg.mod, cfg.nick); % data
    beginname = sprintf('%s_%s_%04d_%s_', cfg.nick, cfg.rec, subj, cfg.mod); % beginning of datafile
    
    %---------------------------%
    %-loop over channels
    for c = 1:numel(cfg.count.chan)
      
      %-----------------%
      %-read data and count slow waves
      endname = [cfg.count.chan{c} cfg.endname];
      filename = dir([ddir beginname '*' endname '.mat']);
      
      if ~isempty(filename)
        load([ddir filename(1).name], 'data');
        sw(cnt, c) = numel(data.trial);
      end
      %-----------------%
      
    end
    %---------------------------%
    
  end
  %-------------------------------------%
  
  %-------------------------------------%
  %-write to output
  %---------------------------%
  %-loop over channels
  output = [output sprintf('\n\t%s\n', cfg.count.grp(g).name)];
  for c = 1:numel(cfg.count.chan)
    
    sw_chan = sw(:,c);
    sw_chan(isnan(sw_chan)) = [];
    output = [output sprintf('\t\t%s\t# % 2d\tmean % 8.2f\t s.d. % 8.2f\n', ...
      cfg.count.chan{c}, numel(sw_chan), mean(sw_chan), std(sw_chan))];
    
  end
  %---------------------------%
  %-------------------------------------%
  
end

%---------------------------%
%-end log
toc_t = toc(tic_t);
outtmp = sprintf('%s ended at %s on %s after %s\n\n', ...
  mfilename, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'), ...
  datestr( datenum(0, 0, 0, 0, 0, toc_t), 'HH:MM:SS'));
output = [output outtmp];

%-----------------%
fprintf(output)
fid = fopen([cfg.log '.txt'], 'a');
fwrite(fid, output);
fclose(fid);
%-----------------%
%---------------------------%