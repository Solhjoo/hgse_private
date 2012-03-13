function spindlepeak(cfg)
%SPINDLEPEAK detect peak in spindle power at single subject-level
%
% CFG
%  .log: name of the file and directory with analysis log
%  .test: a cell with the condition defined by redef. This function will loop over cfg.test
%  .log: name of the file and directory with analysis log
%  .rslt: directory images are saved into
%  .dpow: directory to save POW data
% 
%  .sppeak.freq: two values with limits for frequency
%  .sppeak.time: two values with limits for time
% 
% OUT
%  [cfg.dpow 'spindlepeak']: peak for each subj in freq, time and ampl
% 
% FIGURES
%  spindlepeak_timefreq: plot for each subj/channel on time/freq
%  spindlepeak_freqampl: plot for each subj/channel on freq/ampl
%  spindlepeak_timeampl: plot for each subj/channel on time/ampl
% 
% Part of HGSE_PRIVATE

%---------------------------%
%-start log
output = sprintf('%s started at %s on %s\n', ...
  mfilename,  datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%-------------------------------------%
%-loop over conditions
amplpeak = nan(numel(cfg.test), max(cfg.subjall));
freqpeak = nan(numel(cfg.test), max(cfg.subjall));
timepeak = nan(numel(cfg.test), max(cfg.subjall));

for k = 1:numel(cfg.test)
  
  %-----------------%
  %-test info
  output = [output sprintf('\nSpindle peaks for test %s\n', cfg.test{k})];
  condname = regexprep(cfg.test{k}, '*', '');
  %-----------------%
  
  %---------------------------%
  %-loop over subjects
  for subj = cfg.subjall
    
    %-----------------%
    %-load data
    freqfile = sprintf('pow_%02.f_%s.mat', subj, condname);
    
    if exist([cfg.dpow freqfile], 'file')
      load([cfg.dpow freqfile], 'freq')
    else
      output = [output sprintf('   %02.f: %s does not exist in %s\n', subj, freqfile, cfg.dpow)];
      continue
    end
    %-----------------%
    
    %-----------------%
    %-select time and freq of interest
    i_f1 = nearest(freq.freq, cfg.sppeak.freq(1));
    i_f2 = nearest(freq.freq, cfg.sppeak.freq(2));
    i_f = i_f1:i_f2;
    
    i_t1 = nearest(freq.time, cfg.sppeak.time(1));
    i_t2 = nearest(freq.time, cfg.sppeak.time(2));
    i_t = i_t1:i_t2;
    %-----------------%
    
    %-----------------%
    %-find max
    powspctrm = freq.powspctrm(:, i_f, i_t);
    
    [ampl, imax] = max(powspctrm(:));
    [x y z] = ind2sub(size(powspctrm), imax);
    
    amplpeak(k, subj) = ampl;
    freqpeak(k, subj) = freq.freq(i_f(y));
    timepeak(k, subj) = freq.time(i_t(z));
    %-----------------%
    
    %-----------------%
    %-output
    output = [output sprintf('   %02.f: peak at% 5.1fHz % 3.1fs with value:%6.1f\n', ...
      subj, freq.freq(i_f(y)), freq.time(i_t(z)), ampl)];
    %-----------------%
    
  end
  %---------------------------%
  
end
%-------------------------------------%

save([cfg.dpow 'spindlepeak'], 'amplpeak', 'freqpeak', 'timepeak')

%-------------------------------------%
%-figures
subjname = cellfun(@num2str, num2cell(1:max(cfg.subjall)), 'uni', 0);
colors = {'b' 'r' 'k' 'g'};

%---------------------------%
%-freq/time plot
h = figure;
hold on

for k = 1:numel(cfg.test)
  plot(timepeak(k,:), freqpeak(k,:), '.', 'Color', colors{k})
  text(timepeak(k,:), freqpeak(k,:), subjname)
end

title('spindle peaks: time and freq')
xlabel('time')
xlim(freq.time([i_t1 i_t2]))
ylabel('freq')
ylim(freq.freq([i_f1 i_f2]))

%--------%
%-save and link
pngname = 'spindlepeak_timefreq';
saveas(h, [cfg.log filesep pngname '.png'])
close(h); drawnow

[~, logfile] = fileparts(cfg.log);
system(['ln ' cfg.log filesep pngname '.png ' cfg.rslt pngname '_' logfile '.png']);
%--------%
%---------------------------%

%---------------------------%
%-freq/ampl plot
h = figure;
hold on

for k = 1:numel(cfg.test)
  plot(freqpeak(k,:), amplpeak(k,:), '.', 'Color', colors{k})
  text(freqpeak(k,:), amplpeak(k,:), subjname)
end

title('spindle peaks: freq and ampl')
xlabel('freq')
xlim(freq.freq([i_f1 i_f2]))
ylabel('ampl')

%--------%
%-save and link
pngname = 'spindlepeak_freqampl';
saveas(h, [cfg.log filesep pngname '.png'])
close(h); drawnow

[~, logfile] = fileparts(cfg.log);
system(['ln ' cfg.log filesep pngname '.png ' cfg.rslt pngname '_' logfile '.png']);
%--------%
%---------------------------%

%---------------------------%
%-time/ampl plot
h = figure;
hold on

for k = 1:numel(cfg.test)
  plot(timepeak(k,:), amplpeak(k,:), '.', 'Color', colors{k})
  text(timepeak(k,:), amplpeak(k,:), subjname)
end

title('spindle peaks: time and ampl')
xlabel('time')
xlim(freq.time([i_t1 i_t2]))
ylabel('ampl')

%--------%
%-save and link
pngname = 'spindlepeak_timeampl';
saveas(h, [cfg.log filesep pngname '.png'])
close(h); drawnow

[~, logfile] = fileparts(cfg.log);
system(['ln ' cfg.log filesep pngname '.png ' cfg.rslt pngname '_' logfile '.png']);
%--------%
%---------------------------%
%-------------------------------------%

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
