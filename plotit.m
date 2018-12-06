%plotit.m
% combines dataExtractNEW and quickplot to print all spp results
% in one figure

% plots results from soundchecker
% new version 4/25/2012
% fix on 11-27-2013 to account for 10 minute waves and 3 min pngs
ccc
% [PngFile,AnalysisFold] = uigetfile({'E:\ANALYSIS\*.mat'}, ...
%     'Pick a pngRESLTs file to process');

[PngFile,AnalysisFold] = uigetfile({'\\nmfs.local\AKC-NMML\CAEP\Acoustics\ANALYSIS\*.mat'}, ...
    'Pick a pngRESLTs file to process');
fprintf(1,'No review = 1.\n');
fprintf(1,'Your review completed = 2.\n');
fprintf(1,'Your review has been verified by someone = 3.\n');
reviewStage = input('Which stage of the review process are you at?\n' )

if reviewStage == 1;
    reviewWord = 'NoReview';
elseif reviewStage == 2;
    reviewWord = 'FirstReview';
elseif reviewStage == 3;
    reviewWord = 'FinalReview';
end

overRideDates = input('Do you want to extend date axis beyond data available? (y/n)','s');

if overRideDates == 'y';
    dateStartORtxt = input('Enter MM/DD/YYYY of start','s');
    dateStartOR = datenum(dateStartORtxt,'mm/dd/yyyy');
    dateEndORtxt = input('Enter MM/DD/YYYY of end','s');
    dateEndOR = datenum(dateEndORtxt,'mm/dd/yyyy');
else
    % do nothing.
end

ExcelFile = [AnalysisFold PngFile(10:end-4) '_' reviewWord '.xls'];

% now to open up the excel application so we don't have to reopen and
% close it repeatedly below.
Excel = actxserver ('Excel.Application');

if ~exist(ExcelFile,'file')
    ExcelWorkbook = Excel.workbooks.Add;
    
    ExcelWorkbook.SaveAs(ExcelFile,1);
    ExcelWorkbook.Close(false);
end

invoke(Excel.Workbooks,'Open',ExcelFile);

load([AnalysisFold PngFile]);
cn = str2num(PngFile(end-5:end-4));
extratab = [];

% need to get the right directory name here...
if AnalysisFold(1:6) == '\\nmfs';
    
    directName = strfind(AnalysisFold,'Acoustics');
    folderName = AnalysisFold(1:directName+9);
else
    folderName = AnalysisFold(1:3);
end



% now open up dutycycle excel to get duty cycle values
[nums,txts] = xlsread([folderName 'CURRENT WORKING FILES\DutyCycle.xlsx']);

moorings = char(txts(:,1));
thisMooring = strmatch(PngFile(10:end-12),moorings,'exact');
dc1 = nums(thisMooring,1);% recOnTime
dc2 = nums(thisMooring,2);% Duty Cycle

maxtimeperpng = PNGrslts_MetaData(cn).rowsPerPlot*...
    PNGrslts_MetaData(cn).secondsPerRow; %in secs
sizeWav = min(dc1,10); % ten minute waves (or smaller)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% estimate max number of pngs per day here - note: this is not #
% intervals/day - and it might be the numbr of pngs *each* day.  % this is
% just a sanity check that you know what the max could be.

% first is max # duty cycles/day:

maxDCperDay = floor((24*60)/dc2);  % treating last one as an add on

maxWavsPerDC = ceil(dc1/sizeWav);
recon = dc1;
TotalPngsPerDC = 0;
for n = 1:maxWavsPerDC;
    if  recon > sizeWav;
        numPngs = ceil((60*sizeWav)/maxtimeperpng);
    else
        numPngs = ceil((60*recon)/maxtimeperpng);
    end
    recon = recon-sizeWav;
    TotalPngsPerDC = TotalPngsPerDC+numPngs;
end

% check if record on time extends past midnight on last DC of day.
LastDCofDay = ((24*60)/dc2 - floor((24*60)/dc2))*dc2; % in minutes
if LastDCofDay == 0;
    % there is no last DC, nothing added on.
    TotalPngsPerDay = TotalPngsPerDC *(maxDCperDay);
elseif LastDCofDay >= dc1;
    % then it counts as a full record period;
    TotalPngsPerDay = TotalPngsPerDC *(maxDCperDay+1);
else
    % need to figure out how many pngs are available
    recon = abs((LastDCofDay-dc1));
    TotalPngsPerLastDC = 0;
    for n = 1:maxWavsPerDC;
        if  recon > sizeWav;
            numPngs = ceil((60*sizeWav)/maxtimeperpng);
        else
            numPngs = ceil((60*recon)/maxtimeperpng);
        end
        recon = recon-sizeWav;
        TotalPngsPerLastDC = TotalPngsPerLastDC+numPngs;
    end
    TotalPngsPerDay = TotalPngsPerDC *(maxDCperDay) + TotalPngsPerLastDC;
end

% fprintf(1,'Here are the species that can be processed:\n');
Species = PNGrslts_MetaData(cn).CheckSpp;

Sppones = 1:size(Species,1);
Spp = Species(Sppones',:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% determine time zone and time interval wanted here.

UTCorLocal = 'u';
ti = 'n';
TimeInterval = maxtimeperpng/3600;

enddate = txts(thisMooring,5);
enddate = datenum(enddate,'mm/dd/yyyy');

allDashes = strfind(fileMTX{1}(1,:),'-');

timekind = 'UTC';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gather up the pngs into one vector - because resltMTX has filler cells - can't just
% leave in matrix.

% This is going to be slow for SHI files, since there
% are so many pngs.

vectx = [];  resltx = [];
for m = 1:size(fileMTX,2); % for each day (m)
    pngs = fileMTX{m}; % compile all pngs
    timesX = datevec([pngs(:,allDashes(2)+1:allDashes(3)-1) ...
        pngs(:,allDashes(3)+1:allDashes(4)-1)], ...
        'yymmddHHMMSS');
    vectx = [vectx; datenum(timesX)];
    % need to do a resltx column for each species
    resltxS = [];
    for S = 1:size(Spp,1);
        resltxS(:,S) = [resltMTX(1:size(pngs,1),m,Sppones(S))];%only take reslts
        %with matching pngs
    end
    resltx = [resltx; resltxS];
end
vectx = round(vectx*24*3600)/24/3600; % round to nearest second here
clear timesX

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% change all times to Local or UTC if wanted;
DaylightSavings = ...
    [2007 datenum(2007,03,11,2,0,0) datenum(2007,11,4,2,0,0);...
    2008 datenum(2008,03,9,2,0,0) datenum(2008,11,2,2,0,0);...
    2009 datenum(2009,03,8,2,0,0) datenum(2009,11,1,2,0,0); ...
    2010 datenum(2010,03,14,2,0,0) datenum(2010,11,7,2,0,0);...
    2011 datenum(2011,03,13,2,0,0) datenum(2011,11,6,2,0,0);...
    2012 datenum(2012,03,11,2,0,0) datenum(2012,11,4,2,0,0); ...
    2013 datenum(2013,03,10,2,0,0) datenum(2013,11,3,0,0,0); ...
    2014 datenum(2014,03,09,2,0,0) datenum(2014,11,2,0,0,0); ...
    2015 datenum(2015,03,08,2,0,0) datenum(2015,11,1,0,0,0); ...
    2016 datenum(2016,03,13,2,0,0) datenum(2016,11,6,0,0,0)];


% have to round vectx- there are weird 1E-10 rounding errors otherwise.
vectx = round(vectx*24*3600)/24/3600; % round to the nearest second.
datevectx = datevec(vectx);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure out the time bins here.

if ti == 'n';
    % then the pngsize is the time bin - just need to count pngs per day
    TB = 0;
elseif ti == 'y';
    % figure out the start/end times of each time bin
    % it's always going to start with 0:00 on the first day of recording
    TB = 1;
    TimeBins = 0:TimeInterval:24; % in hours
end

% Now do the calculations to get # rec. intervals/day and # intervals
% w/calls for each day

% Here is the number of days:
dateonly = datenum(datevectx(:,1),datevectx(:,2),datevectx(:,3));
udays = unique(dateonly);
% first, if there has been any time zone changes - have to find all the
% pngs per day again:

for m = 1:size(udays,1); % for each day (m)
    pngs = find(dateonly == udays(m)); % compile all pngs
    % first find times of pngs in this day
    pngtimes = datenum(datestr(vectx(pngs)));
    % now determine if any pngs from previous day spill into this day.
    if m > 1;
        yesterdaypngs = find(dateonly == udays(m-1));
        lastpng = vectx(yesterdaypngs(end));
        % calculate # seconds between end of this last png on previous day and
        % start of new day
        timediff = (udays(m) - lastpng)*24*60*60;
        if maxtimeperpng > timediff;
            % then that png will be part of first interval;
            pngtimes  = [lastpng; pngtimes];
            pngs = [yesterdaypngs(end); pngs];
            extra = 1;
        else
            extra = 0;
            % no extra pngs to add - carry on as is.
        end
    end
    
    
    % calculate # of time bins available, the # with calls, and the # with
    % NWN
    if TB == 0;  % time bin is equal to the max png size (in minutes)
        % just count # of pngs available:
        totalTimeIntWrecs(m) =  size(pngs,1);
        for S = 1:size(Spp,1);
            findcalls = find(resltx(pngs,S) == 1);
            findcallsyandm = find(resltx(pngs,S) ==1 | resltx(pngs,S) ==2);
            find4s = find(resltx(pngs,S) == 4);
            totalTimeIntWcalls(m,S) = size(findcalls,1);
            totalTimeIntWcallsyandm(m,S) = size(findcallsyandm,1);
            totalTimeIntW4s(m,S) = size(find4s,1);
        end
        
    elseif TB == 1;
        % get time bins for that particular day:
        TimeEdges = udays(m) + TimeBins/24;
        % need to go bin by bin and see if there are any pngs available
        for i = 1:size(TimeBins,2)-1;
            pngsInTB = find(pngtimes >= TimeEdges(i) & pngtimes < TimeEdges(i+1));
            if isempty(pngsInTB);
                intWrecs(i) = 0;
                for S = 1:size(Spp,1);
                    intWcalls(i,S) = 0;
                    intW4s(i,S) = 0;
                end
            else
                intWrecs(i) = 1;
                % find # time bins with call and with NWN here.
                for S = 1:size(Spp,1);
                    findcalls = find(resltx(pngs(pngsInTB),S) == 1);
                    findcallsyandm = find(resltx(pngs(pngsInTB),S) ==1 | resltx(pngs(pngsInTB),S) == 2);
                    if isempty(findcalls);
                        intWcalls(i,S) = 0;
                    else
                        intWcalls(i,S) = 1;
                    end
                    if isempty(findcallsyandm);
                        intWcallsyandm(i,S) = 0;
                    else
                        intWcallsyandm(i,S) = 1;
                    end
                    find4s = find(resltx(pngs(pngsInTB),S) == 4);
                    if isempty(find4s);
                        intW4s(i,S) = 0;
                    else
                        % it needs to be every png marked as a NWN for that
                        % interval to count as a NWN
                        
                        if size(find4s,1) == size(pngsInTB,1);
                            intW4s(i,S) = 1;
                        else
                            intW4s(i,S) = 0;
                        end
                        
                    end
                end
            end
        end
        totalTimeIntWrecs(m) = sum(intWrecs);
        totalTimeIntWcalls(m,:) = sum(intWcalls,1);
        totalTimeIntWcallsyandm(m,:) = sum(intWcallsyandm,1);
        totalTimeIntW4s(m,:) = sum(intW4s,1);
        
        if totalTimeIntWrecs(m) < totalTimeIntWcalls(m);
            'bah!'
            pause
        end
        
        % pngtimes includes the last png from the previous day so you will be able to
        % see if there are any pngs available from the previous day for the
        % first interval
    end
end



% now make an excel sheet for each species:
for S = 1:size(Spp,1);
    percentCalling = 100.*[totalTimeIntWcalls(:,S)./(totalTimeIntWrecs'-totalTimeIntW4s(:,S))]; % this is per day
    percentCallingyandm = 100.*[totalTimeIntWcallsyandm(:,S)./(totalTimeIntWrecs'-totalTimeIntW4s(:,S))]; % this is per day
    % going to leave the no data ones separate from the no-with-noise ones so
    % they can be plotted however you like.
    listForExcel = [udays-693960 totalTimeIntWcalls(:,S)  totalTimeIntWrecs' totalTimeIntW4s(:,S) totalTimeIntWcallsyandm(:,S) percentCalling];
    % The 693960 is the conversion needed between matlab and excel.
    metaDataHeaders = {'RecOn      '; 'RecOff     ';'SCAnlysInt ' ; 'TimeBin    '; 'OrigTZ     '};
    metaDataForExcel = [dc1 dc2 0 round(TimeInterval*60) ]';
    
    rfname = PNGrslts_MetaData(cn).FileName;
    unders = strfind(rfname,'_');
    ExcelTab = [deblank(Spp(S,:))];
    fprintf(1,'Writing to excel file now');
    
    % Then run the new xlswrite1 function as many times as needed or in a loop
    %(for example xlswrite1(File,data,location).
    
    % Do the writing to the file
    xlswrite1(ExcelFile,{'Spp     ';'CallType'},ExcelTab,'A1')
    xlswrite1(ExcelFile,{PNGrslts_MetaData(cn).CheckSpp(Sppones(S),:)},ExcelTab,'B1')
    xlswrite1(ExcelFile,{'All'},ExcelTab,'B2')
    
    xlswrite1(ExcelFile,metaDataHeaders,ExcelTab,'A3')
    xlswrite1(ExcelFile,metaDataForExcel,ExcelTab,'B3')
    xlswrite1(ExcelFile,{'UTC'},ExcelTab,'B7')
    
    
    xlswrite1(ExcelFile,{'Date','IntWcalls','IntWrecs','IntWnoise', 'IntWcallsyandm','Call Act %'},ExcelTab,'D1')
    xlswrite1(ExcelFile,listForExcel,ExcelTab, 'D2')
    Sheet = Excel.Worksheets.get('Item',ExcelTab); % Pick the sheet you want to format
    Range = get(Sheet,'Range','D:D'); % Pick the range you want to format
    Range.NumberFormat = 'yyyy-mm-dd HH:MM:SS';  % Here is your format
end

Excel.Visible = true;
Excel.DisplayAlerts = false;
[status,sheetscalls]= xlsfinfo(ExcelFile);

if strmatch(sheetscalls(1,:),'Sheet1');
    Excel.Worksheets.Item(1).Delete; % only delete first sheet if it is 'Sheet1'
end

invoke(Excel.ActiveWorkbook,'Save');
Excel.Quit
Excel.delete
clear Excel

system('taskkill /F /IM EXCEL.EXE');

% now plot it out


iceorno = input('Overlay ice data? (y/n)','s');
if iceorno == 'y';
    'change folder paths'
    pause
    folderpathcalls = 'z:\ANALYSIS\Dana IFAW';
    folderpathice = 'z:\ANALYSIS\Dana IFAW\Sigrid Ice for DLW work\Ice Data';
    cd(folderpathcalls)
end

[status,sheetscalls]= xlsfinfo(ExcelFile);
SC = (sheetscalls)';
Scalls = char(SC);
Scalls = Scalls(1:end,:);
offset = 0.075;
LW = 1.5; %linewidth
np = 1; % this is the number of locations
fsz = 6; %fontsize for labels
timespans = 'y';
%colors
CRIMSON = [0.8594 0.0781 0.2344];
DARKVIOLET = [0.5781 0 0.8242];
DARKORANGE = [1.0000 0.5469 0];
GREEN = [0.2344 0.6992 0.4414];
DIMGRAY = [0.4102 0.4102 0.4102];
DODGERBLUE = [0.1172 0.5625 1.0000];
HOTPINK = [1.0000 0.4102 0.7031];
TEAL = [0 0.5000 0.5000];
OLIVE = [ 0.5000    0.5000         0];
DARKVIOLET = [0.5781 0 0.8242];
DARKMAGENTA = [ 0.5430 0 0.5430];
LIGHTGRAY = [0.8242 0.8242 0.8242];
DARKGRAY = [0.6602 0.6602 0.6602];
DIMGRAY = [0.4102 0.4102 0.4102];
BLACK = [ 0 0 0];
WHITE = [1 1 1];
LIGHTWHITE = .99999999999999*WHITE;%%%%%%
YELLOW = [.96 .8 0];
GOLDENROD = [0.8516    0.6445    0.1250];
GOLD = [1.0000 0.8398 0];
DARKKHAKI = [ 0.7383    0.7148    0.4180];
DARKGOLDENROD = [0.7188    0.5234    0.0430];
%Blues
LIGHTBLUE = [0.6758    0.8438    0.8984];
CORNFLOWERBLUE = [0.3906    0.5820    0.9258];
AQUA = [0 1 1];
DEEPSKYBLUE = [ 0 0.7461 1.0000];
TEAL = [0 0.5000 0.5000];
DODGERBLUE = [0.1172 0.5625 1.0000];
BLUE = [0 0 1];
MIDNIGHTBLUE = [ 0.0977    0.0977    0.4375];
SLATEBLUE = [0.4141    0.3516    0.8008];
AQUAMARINE = [0.4961    1.0000    0.8281];
CADETBLUE = [ 0.3711    0.6172    0.6250];
DARKTURQUOISE = [0    0.8047    0.8164];
MEDIUMTURQUOISE = [0.2813    0.8164    0.7969];
% Reds
RED = [1 0 0];
SALMON = [0.9792    0.5000    0.4453];
LIGHTPINK = [1.0000    0.7109    0.7539];
HOTPINK = [1.0000 0.4102 0.7031];
DEEPPINK = [1.0000    0.0781    0.5742];
INDIANRED = [0.8008    0.3594    0.3594];
CRIMSON = [0.8594 0.0781 0.2344];
DARKRED = [.543 0 0];

spacebetween = .020;
windowSize = 3;
rounder =2; % this rounds the Y axis limits to this nearest value.

if iceorno == 'y';
    % calculate ice moving average.
    ices = dir(folderpathice);
    ices = ices(3:end,:);
    Ices = char(ices.name);
else
    % do nothing
end

fprintf(1,'\n');
fprintf(1,'Here are the species that can be processed:\n');
Species = PNGrslts_MetaData(cn).CheckSpp;
disp([num2str([1:size(Species,1)]') repmat(' ', size(Species,1),1) Species])
fprintf(1,'\n');
Sppones = input('Which ones do you want to plot [1 2 3 (*enter* for all relevant)]');
if isempty(Sppones);
    if sum([PNGrslts_MetaData.CheckNum]) == 2;
        %         this is regulars - need to break into 2 groups
        Sppones = [2 3 4 6 7 9 10 8 1];
    elseif sum([PNGrslts_MetaData.CheckNum]) == 3;
        % then it's superhigh
        Sppones = [1 2 3 4 7 6 5];
    elseif sum([PNGrslts_MetaData.CheckNum]) == 1;
        % then it's low
        Sppones = [1 3]; % grays are not analyzed here.
    end
    extratextstuff = [];
else
    extratextstuff = input('Please type in some text to identify this file','s');
    extratextstuff = ['_' extratextstuff];
end
Spp = Species(Sppones',:);
figure(1)  % stem plots
ha = tight_subplot(size(Spp,1),1,spacebetween,.1,.1);


for spp = 1:size(Spp,1);
    [Ccallnum, Ccalltxt] = xlsread(ExcelFile,deblank(Spp(spp,:)));
    x = 100*Ccallnum(:,4)./(Ccallnum(:,5)-Ccallnum(:,6));
    xyandm = 100*Ccallnum(:,7)./(Ccallnum(:,5)-Ccallnum(:,6));
    if overRideDates == 'y';
        datestart = dateStartOR;
        dateend = dateEndOR;
    else
        datestart = datenum(char(Ccalltxt(2,4)));
        dateend = datenum(char(Ccalltxt(end,4)));
    end
    %     dates = datestart:1:dateend;
    dates = datenum(char(Ccalltxt(2:end,4)));
    
    if iceorno == 'y';
        if spp == 1; % only do this for the first spp, all the rest are same locn.
            findIce = strmatch(Ccalltxt(1,1+locn),Ices);
            ICE = load([folderpathice '\' Ices(findIce,:)]);
            SDate = datenum(ICE(:,1),ICE(:,2),ICE(:,3));
            SIce = ICE(:,4); % now in percent
            Spts = ICE(:,5);
            [IceMAdates, IceMAData,missingIce] = MovAvgNan(SIce, SDate, windowSize);
        else
            % info is already there
        end
    else
        % do nothing
    end
    % 999 is no data
    % 111 is where all bins in that day were NWN
    % find how many 111's there are for shading later
    ones1 = find(x == 111);
    % find how many 999's there are for shading later
    nines1 = find(x(:,1) == 999);
    % and change the 999's and 111's to 0/0's.
    f = find(x > 110);
    for xn = 1:size(f,1);
        x(f(xn)) = 0/0;
    end
    
    % generate half month intervals for ticks
    years = [str2num(datestr(datestart,'YYYY')):str2num(datestr(dateend,'YYYY'))];
    mos = 1:12;
    days = [1 15];
    stagl = 0.01;
    tickdates = [];
    for y = 1:size(years,2);
        for m = 1:size(mos,2);
            for d = 1:size(days,2);
                tickdates = [tickdates; [years(y) mos(m) days(d)]];
            end
        end
    end
    maintickdates = tickdates(1:2:end,:);
    minortickdates = tickdates(2:2:end,:);
    yg = [0 3.5];
    xx = reshape([datenum(minortickdates)'; datenum(minortickdates)'; ...
        NaN(1,size(minortickdates,1))],1,size(minortickdates,1)*3);
    yy = repmat([yg NaN],1,length(minortickdates));
    
    startingdate = datestart;
    endingdate = dateend;
    leftYlabdate = endingdate+10;
    datelims =[startingdate endingdate];
    dntickdates = datenum(maintickdates(:,1),maintickdates(:,2),maintickdates(:,3));
    startd = max(find(dntickdates <= startingdate));
    endd = min(find(dntickdates >= endingdate));
    alldates = datelims(1):1:datelims(end);
    
    dntickdates = dntickdates(startd:1:endd);
    %     if mod(size(dntickdates,1),2) == 0;
    % it is an even number and the last tick won't be included, so add it in here.
    %         ticklabels = [dntickdates(1:1:end,:); dntickdates(end,:)];
    %     else
    ticklabels = dntickdates(1:1:end,:);
    %     end
    tlab = datestr(ticklabels,'mmm-yy');
    tlabs = [];
    for tn = 1:size(tlab);
        tlabs = [tlabs (tlab(tn,:)) '|'  ];
    end
    
    axes(ha(spp)) % same as subplot ha(locn)
    if iceorno == 'y'; % ice
        % plot the yeses and maybes first
        [uu,uua(1), uua(2)] = plotyy(dates,xyandm,IceMAdates, IceMAData,'stem','plot') ;
        hold on
        % then just the yeses
        [u,ua(1), ua(2)] = plotyy(dates,x,IceMAdates, IceMAData,'stem','plot') ;
    else % no ice
        % plot the yeses and maybes first
        [uu,uua(1), uua(2)] = plotyy(dates,xyandm,dates,xyandm,'stem','stem') ;
        hold on
        % then just the yeses
        [u,ua(1), ua(2)] = plotyy(dates,x,dates,x,'stem','stem') ;
    end
    set(uu(1),'Ycolor',GREEN);
    set(u(1),'Ycolor',BLACK);
    set(get(u(1),'Ylabel'),'String', [Spp(spp,1:4)], ...
        'color',BLACK,'fontsize',fsz);
    set(get(uu(1),'Ylabel'),'String', [Spp(spp,1:4)], ...
        'color',BLACK,'fontsize',fsz);
    set(ua(1),'color',BLACK,'Linewidth',LW, 'markersize',.5);
    set(uua(1),'color',GREEN,'Linewidth',LW, 'markersize',.5);
    if iceorno == 'y';
        set(u(2),'Ycolor',DODGERBLUE); % ice coverage
        set(get(u(2),'Ylabel'),'String', '', ...
            'color',DODGERBLUE,'fontsize',fsz, ...
            'Position',[leftYlabdate,50,1]);
        set(ua(2),'color',DODGERBLUE,'Linewidth',LW, 'markersize',.5);
    else
        set(u(2),'Ycolor',WHITE); % no ice coverage
        set(uu(2),'Ycolor',WHITE); % no ice coverage
        set(get(u(2),'Ylabel'),'String', 'spp', ...
            'color',LIGHTWHITE,'fontsize',fsz, ...
            'Position',[leftYlabdate,50,1]);
        set(get(uu(2),'Ylabel'),'String', 'spp', ...
            'color',LIGHTWHITE,'fontsize',fsz, ...
            'Position',[leftYlabdate,50,1]);
        set(ua(2),'color',BLACK,'Linewidth',LW, 'markersize',.5);
        set(uua(2),'color',GREEN,'Linewidth',LW, 'markersize',.5);
    end
    if spp == 1;
        title([PngFile(10:end-12)], 'interpreter', 'none')
    end
    set(u(1),'Ylim', [0 100]);
    set(u(1),'Ytick', [0:50:100]);
    set(u(2),'YLim', [0 100]);
    set(u(2),'Ytick', [0:50:100]);
    set(u,'xlim', datelims);
    set(u,'xtick',ticklabels);
    set(uu(1),'Ylim', [0 100]);
    set(uu(1),'Ytick', [0:50:100]);
    set(uu(2),'YLim', [0 100]);
    set(uu(2),'Ytick', [0:50:100]);
    set(uu,'xlim', datelims);
    set(uu,'xtick',ticklabels);
    if spp == size(Spp,1);
        set(u,'xticklabel',tlabs,'fontsize',7); % was 7
        set(uu,'xticklabel',tlabs,'fontsize',7); % was 7
    else
        set(u,'xticklabel',[],'fontsize',7); % was 7
        set(uu,'xticklabel',[],'fontsize',7); % was 7
    end
    %     set(u,'XminorTick','on')% can fix this in 2015b+ - using ax.XAxis.MinorTickValues
    %     set(u,'tickdir','out','ticklength',[.01 0])
    h_minorgrid = line(xx,yy,'Color','k');
    set(u(1),'Box','off')
    %     set(uu,'XminorTick','on')
    %     set(uu,'tickdir','out','ticklength',[.01 0])
    %        set(uu(1),'Box','off')
    hold on
    
    % overlay the grayed areas for no data and green for not analyzed.
    nans = isnan(x);
    p = find(nans);
    
    nodata1 = setdiff(p,ones1);
    nodatadays1 = dates(nodata1);
    if isempty(nodatadays1);
        % do nothing'
    else
        bb1 = bar(nodatadays1,100*ones(size(nodatadays1)),...
            'FaceColor',[.875 .875 .875],'EdgeColor','none','BarWidth',1);
        pH = arrayfun(@(x) allchild(x),bb1);
        nodata{spp} = nans;
        %         axes(u(1))
        line([datelims(1) datelims(end)],[100 100],...
            'Color','k','Parent',u(1),'Clipping','off');
        line([datelims(end) datelims(end)],[0 100],'Color','k','Parent',u(1),'Clipping','off');
        line([datelims(1) datelims(1)],[0 100],'Color','k','Parent',u(1),'Clipping','off');
    end
end
set(gcf,'color','w');

printfilename =  [ExcelFile(1:end-4) extratextstuff];

export_fig(printfilename,'-png','-r300','-opengl')






