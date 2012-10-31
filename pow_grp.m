function pow_grp(cfg)
%POW_GRP compare power between two groups of subjects
%
% CFG
%-Average
%  .nick: NICK to save files specific to each NICK
%  .log: name of the file and directory with analysis log
%  .subjall: index of the number of subjects
%
%  .dpow: directory with ERP data
%  .pow.cond: conditions to make averages
%
%  Baseline correction at the single-subject level:
%  .pow.bl: if empty, no baseline. Otherwise:
%  .pow.bl.baseline: two scalars with baseline windows
%  .pow.bl.baselinetype: type of baseline ('relchange')
%
%-Statistics
%  .gpow.comp: cells within cell (e.g. {{'cond1' 'cond2'} {'cond1'} {'cond2'}})
%        but you cannot have more than 2 conditions (it's always a t-test).
%   If empty, not statistics.
%   If stats,
%     .gpow.stat.time: time limit for statistics (two scalars)
%     .gpow.stat.freq: freq limit for statistics (two scalars)
%     .cluster.thr: threshold to consider clusters are erppeaks
%
%-Plot
%  .gpow.bline: two scalars indicating the time window for baseline in s
%  .gpow.chan(1).name: 'name_of_channels'
%  .gpow.chan(1).chan: cell with labels of channels of interest
%  .gpow.freq(1).name: 'name_of_frequency'
%  .gpow.freq(1).freq: two scalars with the frequency limits
%
%  .sens.layout: file with layout. It should be a mat containing 'layout'
%                If empty, it does not plot topo.
%
%  .rslt: directory images are saved into
%
% IN
%  [cfg.dpow 'pow_SUBJ_COND'] 'pow_subj': timelock analysis for single-subject
%
% OUT
%  [cfg.dpow 'pow_COND'] 'pow': power analysis for all subjects
%  [cfg.dpow 'pow_peak_COMP'] 'pow_peak': significant peaks in the POW for the comparison
%
% FIGURES (saved in cfg.log and, if not empty, cfg.rslt)
%
% Part of EVENTBASED group-analysis
% see also ERP_SUBJ, ERP_GRAND,
% ERPSOURCE_SUBJ, ERPSOURCE_GRAND, ERPSTAT_SUBJ, ERPSTAT_GRAND,
% POW_SUBJ, POW_GRAND, POWCORR_SUBJ, POWCORR_GRAND,
% POWSOURCE_SUBJ, POWSOURCE_GRAND, POWSTAT_SUBJ, POWSTAT_GRAND,
% CONN_SUBJ, CONN_GRAND, CONN_STAT

%---------------------------%
%-start log
output = sprintf('%s began at %s on %s\n', ...
  mfilename,  datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%-----------------------------------------------%
%-stats and plots
if ~isempty(cfg.sens.layout)
  load(cfg.sens.layout, 'layout');
end

%-loop over groups
for g = 1:numel(cfg.grppow.grp)
  
  %-------------------------------------%
  %-loop over statistics conditions
  for t = 1:numel(cfg.grppow.comp)
    clear pow
    
    %-----------------%
    %-compare two conditions
    cond1 = cfg.grppow.comp{t};
    condname = regexprep(cond1, '*', '');
    comp = [condname '_' cfg.grppow.grp(g).name];
    output = sprintf('%s\n   COMPARISON %s between groups %s\n', output, cond1, cfg.grppow.grp(g).name);
    
    %-------%
    %-pow over subj
    tmpcfg = cfg;
    tmpcfg.subjall = cfg.grppow.grp(g).grp1;
    [outtmp data1] = load_subj(tmpcfg, 'pow', cfg.grppow.comp{t});
    output = [output outtmp];
    if isempty(data1); continue; end
    
    tmpcfg = cfg;
    tmpcfg.subjall = cfg.grppow.grp(g).grp2;
    [outtmp data2] = load_subj(tmpcfg, 'pow', cfg.grppow.comp{t});
    output = [output outtmp];
    if isempty(data2); continue; end
    
    cfg1 = [];
    pow{1} = ft_freqgrandaverage(cfg1, data1{:});
    pow{2} = ft_freqgrandaverage(cfg1, data2{:});
    cfg1.keepindividual = 'yes';
    gpowall1 = ft_freqgrandaverage(cfg1, data1{:});
    gpowall2 = ft_freqgrandaverage(cfg1, data2{:});
    %-------%
    
    %-------%
    %-data for plot
    gplot = pow{2};
    if isempty(cfg.pow.bl)
      gplot.powspctrm = log(pow{2}.powspctrm ./ pow{1}.powspctrm);
    else % with baseline correction, take the difference
      gplot.powspctrm = pow{2}.powspctrm - pow{1}.powspctrm;
    end
    %-------%
    
    [pow_peak stat outtmp] = reportcluster(cfg, gpowall1, gpowall2, false);
    %-----------------%
    
    save([cfg.dpow 'pow_peak_grp_' comp], 'pow_peak', 'stat', 'gplot')
    output = [output outtmp];
    %---------------------------%
    
    %---------------------------%
    %-loop over channels
    for c = 1:numel(cfg.gpow.chan)
      
      %-----------------%
      %-figure
      h = figure;
      set(h, 'Renderer', 'painters')
      
      %--------%
      %-options
      cfg3 = [];
      cfg3.channel = cfg.gpow.chan(c).chan;
      cfg3.zlim = 'maxabs';
      cfg3.parameter = 'powspctrm';
      ft_singleplotTFR(cfg3, gplot);
      colorbar
      
      title([comp ' ' cfg.gpow.chan(c).name], 'Interpreter', 'none')
      %--------%
      %-----------------%
      
      %-----------------%
      %-save and link
      pngname = sprintf('gpow_tfr_%s_%s', comp, cfg.gpow.chan(c).name);
      saveas(gcf, [cfg.log filesep pngname '.png'])
      close(gcf); drawnow
      
      [~, logfile] = fileparts(cfg.log);
      system(['ln ' cfg.log filesep pngname '.png ' cfg.rslt pngname '_' logfile '.png']);
      %-----------------%
      
    end
    %---------------------------%
    
    %---------------------------%
    %-topoplotTFR (loop over tests)
    if ~isempty(cfg.sens.layout)
      
      %-loop over freq
      for f = 1:numel(cfg.gpow.freq)
        
        %-----------------%
        %-figure
        h = figure;
        set(h, 'Renderer', 'painters')
        
        %--------%
        %-options
        cfg5 = [];
        cfg5.parameter = 'powspctrm';
        cfg5.layout = layout;
        
        cfg5.ylim = cfg.gpow.freq(f).freq;
        
        %-color scaling specific to each frequency band
        i_freq1 = nearest(pow{1}.freq, cfg.gpow.freq(f).freq(1));
        i_freq2 = nearest(pow{1}.freq, cfg.gpow.freq(f).freq(2));
        powspctrm = gplot.powspctrm(:, i_freq1:i_freq2, :);
        cfg5.zlim = [-1 1] * max(powspctrm(:));
        
        cfg5.style = 'straight';
        cfg5.marker = 'off';
        cfg5.comment = 'xlim';
        cfg5.commentpos = 'title';
        
        %-no topoplot if the data contains NaN
        onedat = squeeze(pow{1}.powspctrm(1, i_freq1, :)); % take one example, lowest frequency
        cfg5.xlim = pow{1}.time(~isnan(onedat));
        
        ft_topoplotER(cfg5, gplot);
        %--------%
        
        %--------%
        colorbar
        %--------%
        %-----------------%
        
        %-----------------%
        %-save and link
        pngname = sprintf('gpow_topo_%s_%s', condname, cfg.gpow.freq(f).name);
        saveas(gcf, [cfg.log filesep pngname '.png'])
        close(gcf); drawnow
        
        [~, logfile] = fileparts(cfg.log);
        system(['ln ' cfg.log filesep pngname '.png ' cfg.rslt pngname '_' logfile '.png']);
        %-----------------%
        
      end
      
    end
    %---------------------------%
    
    %---------------------------%
    %-singleplotER (multiple conditions at once)
    for c = 1:numel(cfg.gpow.chan)
      
      %-loop over freq
      for f = 1:numel(cfg.gpow.freq)
        
        %-----------------%
        %-figure
        h = figure;
        set(h, 'Renderer', 'painters')
        
        %--------%
        %-plot
        cfg4 = [];
        cfg4.channel = cfg.gpow.chan(c).chan;
        cfg4.parameter = 'powspctrm';
        cfg4.zlim = cfg.gpow.freq(f).freq;
        ft_singleplotER(cfg4, pow{:});
        
        legend('cond1', 'cond2')
        ylabel(cfg4.parameter)
        
        title([comp ' ' cfg.gpow.chan(c).name ' ' cfg.gpow.freq(f).name], 'Interpreter', 'none')
        %--------%
        %-----------------%
        
        %-----------------%
        %-save and link
        pngname = sprintf('gpow_val_%s_%s_%s', comp, cfg.gpow.chan(c).name, cfg.gpow.freq(f).name);
        saveas(gcf, [cfg.log filesep pngname '.png'])
        close(gcf); drawnow
        
        [~, logfile] = fileparts(cfg.log);
        system(['ln ' cfg.log filesep pngname '.png ' cfg.rslt pngname '_' logfile '.png']);
        %-----------------%
        
      end
      %-----------------%
      
    end
    %---------------------------%
    
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
fid = fopen([cfg.log '.txt'], 'a');
fwrite(fid, output);
fclose(fid);
%-----------------%
%---------------------------%
