
%SoundChecker.m
%
%v 4.1 05/10/16 - added a hold button to carry choices over to next png.
%v4.0 04/04/13 - keyboard shortcuts for lighten/darken/done.  Notes fixed
%for multi-lines
% v3.0 12/28/12 - multiple species review now
% v2.8 4/25/12 - fixed so it will work with non-haruphones.  :(
% v2.7 4/18/12 - another fix to the subsampling of haruphones. sigh.
% v2.6 4/17/12 - Fixed to subsample haruphone data correctly.
% v2.5 4/4/12   - fixed to save metadata if stopping right after backing
% up.  Also put in better changes questioning - won't ask if no changes
% exists.
% v2.4 3/23/12 - put in 999's to skip pngs in haruphone runs & also to
% subsample a new run.  And put in review mode function to change answers -
% saves new answers in Changes file in pngResults Folder.
% v2.3 3/6/12 - changed to work on 2 row pngs on SHI
% v2.2  2/23/12 - buttons for filtered sound playback.
% v2.1 2/17/12  - added automatic folder paths
% v2.0  12/27/11 - darken/lighten stays until changed.
% v1.2  6/10/11
% changed on 3/1/2011 to make zoom function better
%
% This program checks wav files for the presence/absence of a given call
% type
%
%
% results are stored as a matrix of numbers: 1 = Yes, 2 = maybe, 0 = No,
% 8 = autodetector hit, 9 = not checked yet.

% 10/15/2010  CLB

%
clear all
close all
clc



pngCounter = 0;
%________________________________________________________________
% Choose recorder to process - switch to correct analysis folder.
Quiz = input('Quiz? (y/n)','s');
if Quiz == 'n';
    load('MyFolderSettings');
else
    
    load('MyQuizFolderSettings');
end
AnalysisFolder =  whereAnalysis;
PngFolder = uigetdir(wherePngs,'Where are the *BASE* PNG file  month folders?');
WaveFolder = uigetdir(whereWavs, 'Where are the WAVE file month folders?');
RecTypeNum = input('Which type of recorder?: 1)AURAL, 2)EAR, 3)HARUPHONE 4)SONOBUOY 5)Pop-Up');
RecTypeList = ['AURL'; 'EAR '; 'HARU'; 'SONO';'MARU'];
ProjectCode = upper(input('Enter 2 letter Project Code (e.g. RW,BF,CZ,IP,NP, etc.)','s'));
tic

clear where*
% get mooring/recorder info from wavefolder:
PC = strfind(WaveFolder,'\');
Recorder = WaveFolder(PC(end)+1:end);
ResultsFolder = [AnalysisFolder '\' Recorder];
%
if RecTypeNum == 3;  % Using a Haruphone?
    % ask if you want to subsample like an AURAL?
    downSmpAURAL = input('Would you like to downsample like an AURAL? [y/n] (ask CLB if unsure)','s');
    if downSmpAURAL == 'y';
        dsAURon = 9*60;
        dsAURper = 30*60;
        HaruLong = 10*60;
        if strmatch(Recorder,'BS08_HA_04a')== 1;
            monthStart = [3 4 5 6 7 8 14];
        else
            monthStart = 1;
        end
        pngLong = input('How long is your png (s)');
        pngsPerWav = ceil(dsAURon/pngLong);
        Wavs2skip = ceil(dsAURper/HaruLong);
        skipNum = pngsPerWav*Wavs2skip;
        % now get the wav files you want to use:
        currentDir = cd;
        cd(WaveFolder);
        months = ls;
        months = months(3:end,:);
        dm = datenum(months,'mm_yyyy');
        sdm = sort(dm);
        months = datestr(sdm,'mm_yyyy');
        monthstuff = ones(size(months,1));
        for ms = 1:size(months,1);
            cd(months(ms,:));
            d = dir('*.wav');
            wavsD = char(d.name);
            monthstuff(ms).allwaves = wavsD;
            wavs = 1:Wavs2skip:size(wavsD,1);
            monthstuff(ms).wavsuse = wavsD(wavs,:);
            dbytes = [d.bytes];
            mxbytes = max(dbytes)*.95;
            dbytesuse = dbytes(wavs);
            monthstuff(ms).partialfiles = find(dbytesuse <mxbytes);
            cd(WaveFolder)
        end
        cd(currentDir)
    else
        
        skipNum = 1;
    end
else
    downSmpAURAL = 'n';
    skipNum = 1;
end

if exist(ResultsFolder,'dir') ~= 7;
    mkdir(ResultsFolder)
end
cd(ResultsFolder)
%________________________________________________________________
% set up matrix for soundtypes - Work with CLB to add to these so everyone
% can get updated code and be consistent with categories.


Sounds(1).Bandwidth = [0 250];
Sounds(2).Bandwidth = [0 800];
Sounds(3).Bandwidth = [0 8000];

Sounds(1).Spp = {'fin','gray','blue','wtf'};
Sounds(2).Spp = {'right', 'bowhead','gunshot','humpback','minke',...
    'gray','walrus','genPinni','vessel','airguns','wtf'};
Sounds(3).Spp = {'beluga','bearded','orca','ice','sperm','boing','ribbon','wtf'};

%--------------------------------------------------------------------------
% Figure out what sort of check you want to run

CheckNum = input('Which band to check?: 1) Low: 0-250 2)Mid: 0-800 3)High: fullband [enter #]');

if CheckNum == 1;
    PngType = 'LOW';
elseif CheckNum == 2;
    PngType = 'MID';
elseif CheckNum == 3;
    PngType = 'SHI';
end

CheckBand = Sounds(CheckNum).Bandwidth;

fprintf(1,'\n');

CheckSpp = Sounds(CheckNum).Spp;

%--------------------------------------------------------------------------
% going to create a matrix of who is who.
WhoRan = upper(input('Enter 3 initials of analyst','s'));
if size(WhoRan,2) <3;
    WhoRan = upper(input('Enter 3 initials of analyst','s'));
end
notesFile = [ResultsFolder '\'  WaveFolder(PC(end)+1:end) '_Check' num2str(CheckNum) '_NOTES.csv'];
%--------------------------------------------------------------------------

% now see if that Check has already been run for that unit
% navigate to the results window here
checkfiles = dir('PNG*.mat');
if size(checkfiles,1) > 0;
    rsltFiles = char(checkfiles.name);
    ranChecks = str2num(rsltFiles(:,end-4));
    findCheck = find(ranChecks == CheckNum);
else
    findCheck = [];
end

if isempty(findCheck); % if that check doesn't exist.
    PNGrslts_MetaData(CheckNum).CheckNum = CheckNum;
    PNGrslts_MetaData(CheckNum).CheckBand = CheckBand;
    PNGrslts_MetaData(CheckNum).CheckSpp = char(CheckSpp); % list of all poss spp.
    PNGrslts_MetaData(CheckNum).startday = 1;
    PNGrslts_MetaData(CheckNum).startpng = 1;
    
    % set up a new Check matrix
    % generate pngfile matrix :  pngfiles per day (rows) x days (cols)x spp
    % (sheets)
    PngRsltFileName = ...
        ['PNGrslts_' WaveFolder(PC(end)+1:end) '_check' num2str(CheckNum,'%02.0f') '.mat'];
    cd(PngFolder);
    PngMonths = ls;
    PngMonths = PngMonths(3:end,:);
    
    StupidThumbs2 = strmatch('Thumbs',PngMonths);
    PngMonths = PngMonths(setdiff(1:size(PngMonths,1),StupidThumbs2),:);
    slPM = sort(datenum(PngMonths,'mm_yyyy'));
    PngMonths = datestr(slPM,'mm_yyyy');
    PngDays = [];
    
    for N = 1:size(PngMonths,1);
        PngMonths(N,:);
        cd(PngFolder)
        cd(PngMonths(N,:));
        PngDaysInMonth = ls;
        StupidThumbs2 = strmatch('Thumbs',PngDaysInMonth);
        PngDaysInMonth = PngDaysInMonth(setdiff(1:size(PngDaysInMonth,1),StupidThumbs2),:);
        PngDaysInMonth = PngDaysInMonth(3:end,:);
        DayAdd = size(PngDays,1);
        PngDays = [PngDays ; PngDaysInMonth];
        
        
        for DN = 1:size(PngDaysInMonth,1);
            cd(PngDaysInMonth(DN,:));
            pngs = ls;
            pngs = pngs(3:end,:);
            StupidThumbs = strmatch('Thumbs',pngs);
            pngs = pngs(setdiff(1:size(pngs,1),StupidThumbs),:);
            if downSmpAURAL == 'y';
                PNGrslts_MetaData(CheckNum).HARU2AURAL = 1;
            else
                PNGrslts_MetaData(CheckNum).HARU2AURAL = 0;
                fileMTX{DN+DayAdd} = pngs(1:end,:);
                
                Psize(DN+DayAdd) = size(pngs,1);
            end
            cd(PngFolder)
            cd(PngMonths(N,:))
        end
        cd(PngFolder)
    end
    
    resltMTX = 99.* ones(max(Psize),size(PngDays,1), size(Sounds(CheckNum).Spp,2));
    whoM = 0.*ones(max(Psize),size(PngDays,1));
    for whoey = 1:size(fileMTX,2);
        whoMTX{whoey} = repmat('000',size(fileMTX{whoey},1),1);
    end
    % make a new notes .csv file
    
elseif ~isempty(CheckNum); % if that check exists.
    % you are using an existing run
    % load in Check matrix:
    cd(ResultsFolder);
    PngRsltFileName = ...  % load in the results matrixes
        ['PNGrslts_' WaveFolder(PC(end)+1:end) '_check' num2str(CheckNum,'%02.0f') '.mat'];
    load(PngRsltFileName)
    allFiles = char(fileMTX);
    StupidThumbs = strmatch('Thumbs',allFiles);
    allFiles = allFiles(setdiff(1:size(allFiles,1),StupidThumbs),:);
    allDashes = strfind(allFiles(1,:),'-');
    allDates = allFiles(:,allDashes(2)+1:allDashes(3)-1);
    PngMonths = unique(datestr(datenum(allDates,'yymmdd'),'mm_yyyy'),'rows');
    lPM = datenum(PngMonths,'mm_yyyy');
    slPM = sort(lPM);
    PngMonths = datestr(slPM,'mm_yyyy');
    PngDays = unique(allDates,'rows');
end
%--------------------------------------------------------------------------
cdcurr = cd;

cd(cdcurr)

toc
% get sampling rate and nbits...
tic
cd(WaveFolder)
ml = ls;
ml = ml(3:end,:);
cd(ml(1,:));
wl = ls;
wl = wl(3,:);
[w,fs,nbits] = wavread(wl,'size');
cd ..
cd ..

% Now add in the spectrogram parameters needed to interact with the pngs:

% determine if this is an adcp contaminated EAR
if RecTypeNum == 2;
    Okkonen = lower(input('Is this an Okkonen EAR?(y/n)','s')); %adcp mess
else
    Okkonen = 'n';
end

if strcmp(PngType,'LOW') == 1; %low
    
    if Okkonen == 'y';
        PNGrslts_MetaData(CheckNum).secondsPerRow = .25*60;
        PNGrslts_MetaData(CheckNum).rowsPerPlot = 5;
        PNGrslts_MetaData(CheckNum).maxHz = 250;
    else
        PNGrslts_MetaData(CheckNum).secondsPerRow = 1.25*60;
        PNGrslts_MetaData(CheckNum).rowsPerPlot = 4;
        PNGrslts_MetaData(CheckNum).maxHz = 250;
        %PNGrslts_MetaData(CheckNum).secondsPerRow = 1.25*60;
        %PNGrslts_MetaData(CheckNum).rowsPerPlot = 4;
        %PNGrslts_MetaData(CheckNum).maxHz = 100;
        
    end
elseif strcmp(PngType,'MID') == 1; % medium range used to be REG
    if Okkonen == 'y';
        PNGrslts_MetaData(CheckNum).secondsPerRow = .25*60;
        PNGrslts_MetaData(CheckNum).rowsPerPlot = 4;
        PNGrslts_MetaData(CheckNum).maxHz = 800;
    else
        PNGrslts_MetaData(CheckNum).secondsPerRow = .75*60;
        PNGrslts_MetaData(CheckNum).rowsPerPlot = 5;
        PNGrslts_MetaData(CheckNum).maxHz = 800;
    end
elseif strcmp(PngType,'SHI') == 1; % super high  % dont' need to adjust for
    %Okkonen adcp - only 1.5min long already.
    PNGrslts_MetaData(CheckNum).secondsPerRow = .75*60;
    if fs > 8192;  % there will only be 2 rows:
        PNGrslts_MetaData(CheckNum).rowsPerPlot = 2;
    else % there will be 4 rows  at 8192 or lower
        PNGrslts_MetaData(CheckNum).rowsPerPlot = 4;
    end
    PNGrslts_MetaData(CheckNum).maxHz = floor(fs/2);
end

PNGrslts_MetaData(CheckNum).PngType = PngType;
PNGrslts_MetaData(CheckNum).AutoDetectorsYN  = 'n';
PNGrslts_MetaData(CheckNum).AutoDetectors = ' ';
PNGrslts_MetaData(CheckNum).FileName = PngRsltFileName;

% ________________________________________________


DayStart = PNGrslts_MetaData(CheckNum).startday;
PngStart =   PNGrslts_MetaData(CheckNum).startpng;
totalpngs = size(char(fileMTX),1);
% sum up what has been done:
DonePngs = 0;
% for n = 1:DayStart;
%     if n < DayStart;
%         DonePngs = DonePngs + size(char(fileMTX{n}),1);
%     else
%         DonePngs = DonePngs + PngStart;
%     end
% end
% figure out the number of pngs left (can use first spp, since all are
% marked at once
sF(size(fileMTX,2)) = 0;
Rspp =  resltMTX(:,:,1);
for index5 = 1:size(fileMTX,2);
    sF(index5) = size(fileMTX{index5},1);
    fspp99 = find(Rspp(1:sF(index5),index5) == 99);% just checks 99's that have pngs
    spp99(index5) = size(fspp99,1);
end
pngs2go = sum(spp99);

fdays2go = find(spp99>0);
days2go = size(fdays2go,2);

% on Dec 31, 2014 I've decided not to use 80's and 81's anymore to indicate
% that it is an autodetector result.  The difference will be recorded in
% Tethys that it was an autodetector checked by someone vs. a manual
% detection.   That way the only results are 0, 1, 2, and 4.  No matter
% what.  I.e. autodetectors have to be checked the same as manual analysts.
%  The only difference is that the no's are probably less likely to be
%  right on the autodetector than a manual analyst, but the 'who' person
%  will be listed as LFD on the autodetector results, until they are
%  verified by a manual analyst.

% do a little summary of totals
disp(['There are ' num2str(totalpngs) ' pngs total']);
disp(['There are ' num2str(pngs2go) ' pngs that have not been checked']);
% for the days that have not been checked.
% if day has 0's or 1's  - it doesn't have to be checked.
% if the first png of the day is a 99, day hasn't been checked.
% 71, 72, 70, 74 are results that have been been checked with old soundchecker.
%  If you advance without adjusting their values they will default to that
%  value (i.e. 70 = 0, 71 = 1, 72 = 2...); - I'm not sure this 70 thing is
%  in effect at all.

if days2go >1;
    disp(['There are ' num2str(days2go) ' days that have not been checked']);
    n = PngStart;
    m = DayStart;
    doneO = 0;
elseif days2go == 1;
    disp(['There is ' num2str(days2go) ' day that has not been checked']);
    n = PngStart;
    m = DayStart;
    doneO = 0;
else
    disp('There are no days left to be checked. You may now do your victory dance, or enter review mode');
    m = size(resltMTX,2);
    n = size(fileMTX{m},1);
    revMODE = input('Do you want to enter review mode?[y/n]','s');
    if revMODE == 'y';
        doneO = 0;
    else
        doneO = 1;
    end
end
%_________________________________________________

figPosn1 = [0.0155    0.0552    0.6476    0.8581];
figPosn2 = [0.6762    0.4781    0.3113    0.4352];
f1 = figure('Visible','on','units','normalized','Position',figPosn1);
f2 = figure('Visible','on','units','normalized','Position',figPosn2);
findSlashes = findstr('\', PngFolder);
% baseDB = str2num(PngFolder(findSlashes(3)+7:findSlashes(3)+9));

baseDB = str2num(PngFolder(size(PngFolder,2)-6:size(PngFolder,2)-4));
currentContrast = baseDB;
[n,m,currentContrast] = pngPLOT(fileMTX,PngFolder,n,m,currentContrast);
set(f2,'UserData','ndone');

butt.obj0 = uicontrol('Parent',f1,'Style','Text', ...
    'String', num2str(pngCounter),'backgroundcolor',[1 1 1], ...
    'Units','normalized','Position',[.92 .92 .05 .025]);

butt.obj1 = uicontrol('Parent',f2,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.02 .925 .15 .07],...
    'String', '<<< $#%!@*&', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['[resltMTX,butt,n,m,currentContrast,PNGrslts_MetaData, pngCounter,f1] = lastFILE(fileMTX,' ...
    'ResultsFolder,PngFolder, CheckNum,' ...
    'resltMTX,butt,n,m,currentContrast,PNGrslts_MetaData,handleMTX,whoMTX, pngCounter,f1,f2,WaveFolder,' ...
    'Recorder,WhoRan);']);

%-------------------------
butt.objpnl = uipanel('Parent',f2, ...
    'FontSize',12, 'BackgroundColor','white', 'Position',[0.05 0.02 .85 .895]);
% Create radio buttons in the button group for each species of that freq band.

a1 = uibuttongroup('Parent',butt.objpnl,'visible','on',...
    'position',[0 1-.09 1 .09]);
eval(['butt.objgrp' num2str(n) '= a1;']);
a2a = uicontrol('Parent',a1,'visible','on', 'Style','text',...
    'String','Species','units','normalized','pos',...
    [0.05 0.01 .2 .95],'HandleVisibility','on','fontsize',14);
eval('butt.objHead1 = a2a;');

a2b = uicontrol('Parent',a1,'visible','on', 'Style','text',...
    'String','Yes','units','normalized','pos',...
    [.4 0.01 .10 .95],'HandleVisibility','on','fontsize',14);
eval('butt.objHead2 = a2b;');

a2c = uicontrol('Parent',a1,'visible','on', 'Style','text',...
    'String','Maybe','units','normalized','pos',...
    [.52 0.01 .15 .95],'HandleVisibility','on','fontsize',14);
eval('butt.objHead3 = a2c;');


% The no button - pushing it selects all spp in line
a2d = uicontrol('Parent',a1,'visible','on', 'Style','pushbutton',...
    'String','No','units','normalized','pos',...
    [.70  0.01 .1 .95],'HandleVisibility','on','fontsize',14, ...
    'Enable','on', 'Callback','butt.objHead4 = a2d; [butt] = noAll(handleMTX,butt);')';
eval('butt.objHead4 = a2d;');

% The no-with-noise button - pushing it selects all spp in line
a2e = uicontrol('Parent',a1,'visible','on', 'Style',...
    'pushbutton','String','nWn','units','normalized','pos',...
    [.85 0.01 .10 .95],'HandleVisibility','on','fontsize',14, ...
    'Enable','on', 'Callback','butt.objHead5 = a2e; [butt] = nwnAll(handleMTX,butt);')';
eval('butt.objHead5 = a2e;');


% set up the matrix of handles for this run
handleMTX = zeros(size(Sounds(CheckNum).Spp,2),4);


for o = 1:size(handleMTX,1);  % for each species make a button group
    
    a1 = uibuttongroup('Parent',butt.objpnl,'visible','on',...
        'position',[0 .91-.082*o 1 .08]);
    eval(['butt.objgrp' num2str(o) '= a1;']);
    
    a3 = uicontrol('Parent', eval(['butt.objgrp' num2str(o)]),'visible','on',...
        'Style','pushbutton','String',Sounds(CheckNum).Spp(:,o),...
        'units','normalized','pos',[0 0.01 .35 .95],'HandleVisibility', ...
        'on','UserData',o,'fontsize',14,'Enable','on', ...
        'SelectionHighlight','off', 'Callback', ...
        'if exist(''excelFlag'',''var''); var1 = excelApp; var2 = excelWorkbook; else; var1 = 1; var2 = 2; end; [excelApp, excelWorkbook,excelFlag] = notes(notesFile,fileMTX,n,m,Sounds,CheckNum,WhoRan,butt,var1,var2)');
    eval('butt.objSpp(num2str(o)) = a3;');
    
    a4 = uicontrol('Parent',a1,'Style', 'Radio',...
        'visible','on', 'units','normalized','pos',[.45 .25 .035 .55],'HandleVisibility', ...
        'on','fontsize',14);
    handleMTX(o,1) = a4;
    eval(['butt.objYes' num2str(o) '= a4;']);
    
    a5 = uicontrol('Parent',a1,'Style', 'Radio',...
        'visible','on', 'units','normalized','pos',[.6 .25 .035 .55],'HandleVisibility', ...
        'on','fontsize',14);
    handleMTX(o,2) = a5;
    eval(['butt.objMaybe' num2str(o) '= a5;']);
    
    a6 = uicontrol('Parent',a1,'Style', 'Radio',...
        'visible','on', 'units','normalized','pos',[.75 .25 .035 .55],'HandleVisibility', ...
        'on','fontsize',14);
    handleMTX(o,3) = a6;
    eval(['butt.objNo' num2str(o) '= a6;']);
    
    % No with noise button
    a7 = uicontrol('Parent',a1,'Style', 'Radio',...
        'visible','on', 'units','normalized','pos',[.9 .25 .035 .55],'HandleVisibility', ...
        'on','fontsize',14);
    handleMTX(o,4) = a7;
    eval(['butt.objNwn' num2str(o) '= a7;']);
    
    %find what original selection is and set buttons
    if  resltMTX(n,m,o) == 99;
        set(eval(['butt.objgrp' num2str(o)]),'SelectedObject', ...
            handleMTX(o,3));  % No is selection
    else
        if resltMTX(n,m,o) ~=0;
            set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,resltMTX(n,m,o)));
        else
            set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));
        end
    end
    set(a1,'Visible','on');
    
end

butt.obj2 = uicontrol('Parent', f2,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.55 .925 .12 .07],...
    'String', 'DONE','Fontsize',8, ...
    'Enable','on','Callback', ...
    ['[resltMTX,whoMTX,butt,n,m,currentContrast,' ...
    ' PNGrslts_MetaData,pngCounter,f1,f2] = button(resltMTX, fileMTX, whoMTX,' ...
    'CheckNum,WaveFolder,ResultsFolder, PngFolder, butt,n,m,Recorder,' ...
    'PNGrslts_MetaData,currentContrast,handleMTX,WhoRan,pngCounter,f1,f2);']);

butt.obj5 = uicontrol('Parent', f2,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.55 .925 .1 .05],...
    'String', '<<<', 'FontSize',8,...
    'Enable','on','Visible','off','Callback',...
    ['[butt,resltMTX, currentContrast, PNGrslts_MetaData,reviewCntr,n,m,f1,f2,whoMTX] = reviewSCROLL(fileMTX,' ...
    'PngFolder, resltMTX,handleMTX,PNGrslts_MetaData,CheckNum,' ...
    'butt,-1,currentContrast,Sounds,reviewCntr,strtRevCntr,f1,f2,whoMTX,ResultsFolder);']);
butt.obj6 = uicontrol('Parent', f2,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.70 .925 .1 .05],...
    'String', '>>>', 'FontSize',8,...
    'Enable','on','Visible','off', 'Callback', ...
    ['[butt,resltMTX,currentContrast, PNGrslts_MetaData,reviewCntr,n,m,whoMTX] = reviewSCROLL(fileMTX,' ...
    'PngFolder, resltMTX,handleMTX,PNGrslts_MetaData,CheckNum,' ...
    'butt,+1,currentContrast,Sounds,reviewCntr,strtRevCntr,f1,f2,whoMTX,ResultsFolder);']);
butt.change = uicontrol('Parent', f2,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.91 .35 .1 .075],...
    'String', 'Change', 'FontSize',8,...
    'Enable','on', 'Visible','off','Callback', ...
    ['[resltMTX,whoMTX,butt,currentContrast,PNGrslts_MetaData,reviewCntr,n,m,f1,f2] =' ...
    'reviewChange(resltMTX, fileMTX, whoMTX, CheckNum,' ...
    'ResultsFolder,PngFolder, butt,Recorder,Sounds,' ...
    'PNGrslts_MetaData,currentContrast,handleMTX, WhoRan,reviewCntr,strtRevCntr,f1,f2);']);

% ------------------------

butt.review = uicontrol('Parent', f2,'Style', 'togglebutton', ...
    'Units','normalized','Position',[.85 .925 .12 .07],...
    'String', 'REVIEW', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['[currentContrast, PNGrslts_MetaData,' ...
    'resltMTX, whoMTX,butt,n,m,reviewCntr,strtRevCntr] =' ...
    ' reviewMode(butt,resltMTX,whoMTX,handleMTX,fileMTX,'...
    'PNGrslts_MetaData, CheckNum,' ...
    'PngFolder,currentContrast,Sounds,WhoRan,'...
    'ResultsFolder,Recorder,n,m,f1,f2,WaveFolder,pngCounter);']);

butt.hop_to = uicontrol('Parent', f2,'Style', 'togglebutton', ...
    'Units','normalized','Position',[.92 .725 .08 .07],...
    'String', 'Hop to', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['[currentContrast, PNGrslts_MetaData,' ...
    'resltMTX, whoMTX,butt,n,m,reviewCntr, strtRevCntr] =' ...
    ' hopToMode(butt,resltMTX,whoMTX,handleMTX,fileMTX,'...
    'PNGrslts_MetaData, CheckNum,' ...
    'PngFolder,currentContrast,Sounds,WhoRan,'...
    'ResultsFolder,Recorder,n,m,f1,f2,WaveFolder,pngCounter);']);
%--------------------------------------------

butt.hold = uicontrol('Parent', f2,'Style', 'togglebutton', ...
    'Units','normalized','Position',[.92 .65 .08 .07],...
    'String', 'Hold', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['[resltMTX, butt, handleMTX, n,m] =' ...
    ' holdMode(butt,resltMTX,handleMTX,n,m);']);



%-----------------------------------
butt.play1x = uicontrol('Parent', f1,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.92 .6 .075 .05],...
    'String', 'PLAY 1X', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['playCLIP(butt,PngFolder,WaveFolder,' ...
    'fileMTX,PNGrslts_MetaData,CheckNum,n,m,0,f2);']);
butt.play1xfilt = uicontrol('Parent', f1,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.92 .525 .075 .05],...
    'String', 'PLAY 1X Filt', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['playCLIP(butt,PngFolder,WaveFolder, fileMTX,' ...
    'PNGrslts_MetaData, CheckNum,n,m,1,f2);']);
butt.playXx = uicontrol('Parent', f1,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.92 .475 .075 .05],...
    'String', 'PLAY _X', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['playCLIP(butt,PngFolder,WaveFolder, fileMTX,' ...
    'PNGrslts_MetaData, CheckNum,n,m,0,f2);']);
butt.playXxfilt = uicontrol('Parent', f1,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.92 .425 .075 .05],...
    'String', 'PLAY _X Filt', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['playCLIP(butt,PngFolder,WaveFolder, fileMTX,' ...
    'PNGrslts_MetaData, CheckNum,n,m,1,f2);']);
%-----------------------------------
butt.zoom = uicontrol('Parent', f1,'Style', 'pushbutton', ...
    'Units','normalized','Position',[.92 .80 .08 .05],...
    'String', 'ZOOM ', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['[zoomclip,wavtimeMIN,wavtimeMAX,fs,yHzmn,yHzmx] =' ...
    'zoomCLIPdB(butt,PngFolder,WaveFolder, fileMTX,' ...
    'PNGrslts_MetaData, CheckNum,n,m,WhoRan,f2);']);

% ---------------------------------------

butt.dark = uicontrol('Parent', f2,'Style','pushbutton', ...
    'Units','normalized','Position',[.2 .925 .12 .07],...
    'String', 'Darker ', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['[PNGrslts_MetaData,currentContrast,n,m,pngCounter] = darken(butt,PngFolder,WaveFolder,' ...
    'fileMTX,n,m,currentContrast,f1,f2,PNGrslts_MetaData,pngCounter,resltMTX,whoMTX,CheckNum,' ...
    'ResultsFolder,Recorder,handleMTX,WhoRan);']);
butt.light = uicontrol('Parent', f2,'Style','pushbutton', ...
    'Units','normalized','Position',[.35 .925 .12 .07],...
    'String', 'Lighter ', 'FontSize',8,...
    'Enable','on','Callback', ...
    ['[PNGrslts_MetaData,currentContrast,n,m,pngCounter] = lighten(butt,PngFolder,WaveFolder,' ...
    'fileMTX,n,m,currentContrast,f1,f2,PNGrslts_MetaData,pngCounter,resltMTX,whoMTX,CheckNum,' ...
    'ResultsFolder,Recorder,handleMTX,WhoRan);']);

if doneO == 1;
    close all
end

if get(butt.review,'Value') ~= 1;
    reviewCntr = 0;
    strtRevCntr = 0;
    set(f2,'WindowKeyPressFcn',{@keytry2,butt,PngFolder,WaveFolder,fileMTX,n,m,currentContrast,...
        PNGrslts_MetaData,pngCounter,f1,resltMTX,whoMTX,CheckNum,ResultsFolder,Recorder,handleMTX,WhoRan,f2,Sounds,reviewCntr,strtRevCntr});
    set(f1,'WindowKeyPressFcn',{@keytry2,butt,PngFolder,WaveFolder,fileMTX,n,m,currentContrast,...
        PNGrslts_MetaData,pngCounter,f1,resltMTX,whoMTX,CheckNum,ResultsFolder,Recorder,handleMTX,WhoRan,f2,Sounds,reviewCntr,strtRevCntr});
end