function [output] = export_info(cfg)
%EXPORT_INFO: export info on slow wave detection for hgse

output = '';
output = [output sprintf(' %d', cfg.redefsw.stage) ','];
output = [output sprintf(' %d,', cfg.redefsw.rejart)];

output = [output sprintf(' %s, %1.f,', cfg.redefsw.sw.preproc.lpfilter, cfg.redefsw.sw.preproc.lpfreq)];
output = [output sprintf(' %s, %1.f,', cfg.redefsw.sw.preproc.hpfilter, cfg.redefsw.sw.preproc.hpfreq)];

output = [output sprintf(' %d,', cfg.redefsw.sw.negthr)];
output = [output sprintf(' %d,', cfg.redefsw.sw.p2p)];
output = [output sprintf(' %1.f-%1.f,', cfg.redefsw.sw.zcr(1), cfg.redefsw.sw.zcr(2))];
output = [output sprintf(' %d,', cfg.redefsw.sw.zeropad)];

output = [output sprintf(' %s,', cfg.redefsw.event)];
output = [output sprintf(' %d,', cfg.redefsw.dur)];

for i = 1:numel(cfg.cleansw.auto)
  output = [output sprintf(' %s,', cfg.cleansw.auto(i).met)];
  output = [output sprintf(' %d,', cfg.cleansw.auto(i).thr)];
end

