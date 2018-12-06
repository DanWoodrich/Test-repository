function [MAvgDates, MAvgData,NaNlimits] = MovAvgNan(DATA, DATES,windowSize);

a = 1;
b = ones(1,windowSize)/windowSize;

% fill in between with NANs to keep spurious lines out of plots.
f = ~isnan(DATA);
df = diff(f);
stp = find(df > 0);  % these are the segment starts:
enp = find(df < 0); % these are the segment ends.
stp = stp+1;
if f(1) == 1; % then the data start on the first date
    if isempty(stp)
        stp = 1;
    else
        stp = [1 stp];
    end
end
if f(end) == 1; % then the data end on the last date
    enp = [enp size(DATA,1)];
end
stp = stp(:);
enp = enp(:);
limits = [stp enp];

% calculate the segments without data here - so you can draw the no data
% lines later.
NaNlimits = [];
if limits(1,1) ~= 1;
    NaNlimits = [NaNlimits; [1 limits(1,1)-1]];
end
for n = 1:size(limits,1)-1;
    NaNlimits = [NaNlimits; [limits(n,2)+1 limits(n+1)-1]];
end
if limits(size(limits,1),2) ~= size(DATA,1);
    NaNlimits = [[NaNlimits; limits(size(limits,1),2)+1 size(DATA,1)]];
end
MAvgData = [];
MAvgDates = [];

if limits(1,1) ~= 1;  % you have a gap at the start.
    MAvgData = [MAvgData; ones(limits(1,1)-1,1).*nan];
    MAvgDates = [MAvgDates; ones(limits(1,1)-1,1).*nan];
end

for l = 1:size(limits,1);
    % need to get some mirrored data so ends aren't left hanging
    extra = (windowSize-1)/2;
    DATAclump = DATA(limits(l,1):limits(l,2));
    if extra > 0;
        % but if the size of the DATAclump is less than the extra needed,
        % you have to add zeros here
        szData = size(DATAclump(:),1);
        szextrabits = 0;
        extrabits = [];
        zerobits = [];
        szzerobits = 0;
        if szData <= extra;
            % get extra bits here:
            extrabits = DATAclump(szData:-1:2);  % if nothing there, will be blank
            szextrabits = size(extrabits,2);
            zerobits = zeros(extra-szextrabits,1);
            szzerobits = size(zerobits,1);
            Data2use = [zerobits;  extrabits; DATAclump; extrabits; zerobits];
        else % just get mirrored data
            Data2use = [DATAclump(1+extra:-1:2); DATAclump; DATAclump(end-extra:-1:end-1)];
        end
    else
        Data2use = DATAclump;
        szData = size(DATAclump(:),1);
        szextrabits = 0;
        extrabits = [];
        zerobits = [];
        szzerobits = 0;
    end
    
    if size(Data2use,1) > 3*windowSize;
        MApercentCalling = filtfilt(b,a, Data2use);
        % now clip it back down;
        MApercentCalling = ...
            MApercentCalling(1+extra+szextrabits+szzerobits:end-extra-szextrabits-szzerobits);
        
    else
        
        % need to add extra zeros in if it is too small
        extraneeded = ceil((3*windowSize+1 -size(Data2use,1))/2);
        
        
        MApercentCalling = filtfilt(b,a, ...
            [zeros(extraneeded,1); Data2use; zeros(extraneeded,1)]);
        
        % trim off extra
        MApercentCalling = MApercentCalling(1+extra+extraneeded:end-extraneeded-extra);
        
    end
    MAvgData = [MAvgData; MApercentCalling];
    D = DATES(limits(l,1):limits(l,2));
    D = D(:);
    MAvgDates = [MAvgDates; D ];
   MAvgData =  MAvgData(:);
  MAvgDates =  MAvgDates(:);
    if l < size(limits,1);
        MAvgData = [MAvgData; ones(limits(l+1,1)-limits(l,2)-1,1).*nan];
        MAvgDates = [MAvgDates; ones(limits(l+1,1)-limits(l,2)-1,1).*nan];
    elseif l == size(limits,1);
        if limits(l,2) ~= size(DATA,1);
            O = ones(size(DATA,1)-limits(l,2),1).*nan;
            Odates = ones(size(DATA,1)-limits(l,2),1).*nan;

            MAvgData = [MAvgData; O];
            MAvgDates = [MAvgDates; Odates];
        end        
    end
end