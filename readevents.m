function events=readevents(fname)

if nargin<1
    [fname pname]=uigetfile('*.txt', 'Open an events file')
    fname=[pname fname];
end

fid=fopen(fname, 'r');

prevdatenum=1e12;
days=-1;

for n=1:25
    line=fgetl(fid);
    if length(line)>0
        a=strread(line, '%s', 'delimiter', '\t');
        t=a{1};
        if length(a)>1
            d=a{2};
        end
        switch t
            case 'Patient:'
                header.patient=d;
            case 'Patient ID:'
                header.patientID=sscanf(d, '%f');
            case 'Recording Date:'
                if 1 % Dutch date settings
                    dat=sscanf(d, '%i-%i-%i');
                    header.recdate=datenum(dat(3), dat(2), dat(1));
                else
                    header.recdate=datenum(d);
                end
                header.recdatedescr=datestr(header.recdate, 1);
            case 'Scorer Name:'
                header.scorername=d;
            case 'Scoring Time:'
                % Skip this field for the moment
            case 'Sleep Stage'
                break % We arrived at the stage scoring section
        end
    end
end

events.header=header;

n=0;
line=fgetl(fid);
while line~=-1
    a=strread(line, '%s', 'delimiter', '\t ');
    statedescr=a{1};
    switch upper(statedescr)
        case 'WAKE'
            state=0;
        case 'S1'
            state=1;
        case 'S2'
            state=2;
        case 'S3'
            state=3;
        case 'S4'
            state=4;
        case 'REM'
            state=5;
        case 'MT'
            state=-1;
        otherwise
            state=-10;
    end
    duration=sscanf((char(a{4})), '%i');
    if duration>=10
        n=n+1;
        states(n)=state;
        statedescriptions(n)={statedescr};
        timedescriptions(n)={sprintf('%s %s', header.recdatedescr, char(a{2}))};
        timenums(n)=datenum(timedescriptions(n))+days;
		if timenums(n)<prevdatenum
			days=days+1;
			timenums(n)=datenum(timedescriptions(n))+days;
			prevdatenum=timenums(n);
		end
    else % Analysis start/stop?
        statedescr=a{3};
        switch upper(statedescr)
            case 'ANALYSIS-START'
                events.startepoch=max(1, n);
            case 'ANALYSIS-STOP'
                events.stopepoch=n-1;
        end
    end
    if n>2000   % avoid an infinite loop
        break
    end
    line=fgetl(fid);
end

fclose(fid);

events.state=states(events.startepoch:events.stopepoch);
events.statedescription=statedescriptions(events.startepoch:events.stopepoch);
events.timestamp=timenums(events.startepoch:events.stopepoch);
events.timedescription=timedescriptions(events.startepoch:events.stopepoch);
%{
events.state=states;
events.statedescription=statedescriptions;
events.timestamp=timenums;
events.timedescription=timedescriptions;
%}