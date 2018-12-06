function [zoomclip,wavtimeMIN,wavtimeMAX,fs,yHzmn,yHzmx] = zoomCLIPdB(butt,PngFolder,WaveFolder,...
    fileMTX,PNGrslts_MetaData,CheckNum,n,m,WhoRan,f2)
%
%v3.0 12/28/12 - multiple species review now
% v2.3 3/23/12 - added 2-stage upsampling for saving to wave files
% v2.2 3/6/12 - changed to work on 2 row pngs
% v1.4 2/23/12 - changed to go across rows and to select in between rows
% v1.3  2/17/12 - changed to accept the myINFO folder path information
% v1.2  5/9/11
%
X = 25;
set(gca,'Units','normalized');

points = ginput(2);
point1 = points(1,:);
point2 = points(2,:);

x = points(:,1);
y = points(:,2);

hold on

maxY = max(get(gca,'ylim'));
maxX = max(get(gca,'xlim'));

nX = x./maxX;
nY = y./maxY;
secperrow = PNGrslts_MetaData(CheckNum).secondsPerRow;
numrows = PNGrslts_MetaData(CheckNum).rowsPerPlot;
maxHz = PNGrslts_MetaData(CheckNum).maxHz;

% mapping out rows

% these numbers are the ginputs of the subplot corners divided by maxY and
% maxX

if numrows == 4;
    rowX = [.1364 .9009];
    rowY = [.0747 .2355; .2931 .4539; .5133 .6741; .7318 .8925];
elseif numrows == 5;
    rowX = [.1323 .9022];
    rowY = [.0747 .1970; .2477 .3735; .4189 .5448; .5920 .7178; .7650 .8908];
elseif numrows == 2;
    rowX = [.1309 .9055];
    rowY = [.0750 .4167; .5506 .8897];
end

minOFrowmin = max(find(rowY(:,1) <= min(nY)));
minOFrowmax = min(find(rowY(:,2) >=min(nY)));
minOFrow = max(intersect(minOFrowmin,minOFrowmax));

maxOFrowmin = max(find(rowY(:,1) <= max(nY)));
maxOFrowmax = min(find(rowY(:,2) >= max(nY)));
maxOFrow = min(intersect(maxOFrowmin,maxOFrowmax));

playrowStart = max( find(rowY(:,1) <= min(nY)));
playrowEnd = min(find(rowY(:,2) >= max(nY)));

if isempty(playrowStart) == 1;
    playrowStart = 0;
end

if isempty(playrowEnd) == 1;
    playrowEnd = numrows+1;
end

if isempty(minOFrow) == 1;
    if isempty(maxOFrow) == 0;
        if playrowEnd-playrowStart >1;
            playrowStart = playrowEnd-1;
        else
            playrowStart = playrowEnd;
        end
        nY(1)  = rowY(playrowStart,1);
    else isempty(maxOFrow) == 1;
        playrowStart1 = playrowStart+1;
        playrowEnd1 = playrowEnd-1;
        playrowStart =playrowStart1;
        playrowEnd  = playrowEnd1;
          clear playrowStart1;
          clear playrowEnd1;          
        nY(1)  = rowY(playrowStart,1);
        nY(2) = rowY(playrowEnd,2);
    end
elseif isempty(minOFrow) == 0;
    if isempty(maxOFrow) == 1;
        if playrowEnd-playrowStart >1;
            playrowEnd = playrowStart+1;
        else
            playrowEnd = playrowStart;
        end
       nY(2) = rowY(playrowEnd,2);
    end
end

xtimemn = (((nX(1))-min(rowX))*secperrow)/(max(rowX)-min(rowX))+((playrowStart-1)*secperrow); %sec
xtimemx = (((nX(2))-min(rowX))*secperrow)/(max(rowX)-min(rowX))+((playrowEnd-1)*secperrow);%sec

% find minimum frequency here:

Freq1 = (rowY(playrowStart,2)-nY(1))./(diff(rowY(playrowStart,:)))*maxHz;
Freq2 = (rowY(playrowEnd,2)-nY(2))./(diff(rowY(playrowEnd,:)))*maxHz;

yHzmn = min(Freq1, Freq2);
yHzmx =  max(Freq1, Freq2);

% hold on
% plot(maxX*nX,maxY*nY,'yd');
Getvars = get(f2,'WindowKeyPressFcn');  % have to pass the png/day info here from the key shortcuts
n = Getvars{6};
m = Getvars{7};
% now get the file name and subplot #
PngFileDashes = strfind(fileMTX{1}(1,:),'-');  %just look at 1st file of 1st folder.
pngfile = fileMTX{m}(n,:);
pngDateTime = datenum(pngfile(PngFileDashes(2)+1:PngFileDashes(4)-1),'yymmdd-HHMMSS');

% Find the wave month folder:
cd(WaveFolder);
mos = ls;
mos = mos(3:end,:);
mo = mos(strmatch(datestr(pngDateTime,'mm_yyyy'),mos),:);
% open that wave month folder:
cd(mo);
% no days here - it is the wave file folder.
wavs = ls;
wavs = wavs(3:end,:);

wavsDateTime =  datenum(wavs(:,PngFileDashes(2)+1:PngFileDashes(2)+ 13),'yymmdd-HHMMSS');
% now find the wave file that contains the png file

if pngfile(1:2) == 'SB';
    % have multiple channels;
    pngfileCHAN = pngfile(PngFileDashes(4)+1:PngFileDashes(4)+3);
    thisWav1 = find(wavsDateTime <= pngDateTime);
    thisWav2 = strmatch(pngfileCHAN, wavs(:,PngFileDashes(4)+1:PngFileDashes(4)+3));
    thisWav = max(intersect(thisWav1,thisWav2));
else
    thisWav = max(find(wavsDateTime <= pngDateTime));
end

extime = (pngDateTime - wavsDateTime(thisWav)).*24.*3600; % in seconds
wavfile = wavs(thisWav,:);
% add on base time for that png file:

wavtimeMIN = xtimemn+extime; % in seconds.
wavtimeMAX = xtimemx+extime; % in seconds.
[sc,fs,nbits] = wavread(wavfile,1);

zoomclip1 = wavread(wavfile, ...
    [floor(wavtimeMIN*fs) ceil(wavtimeMAX*fs)]);
Z.origclip = zoomclip1;
Z.clip = zoomclip1;
Z.origFs = fs;
Z.fs = fs;
Z.origNbits = nbits;
Z.nbits = nbits;
Z.yHzmn = yHzmn;
Z.origyHzmn = yHzmn;
Z.origyMzmx = yHzmx;
Z.yHzmx = yHzmx;
Z.maxHz =  maxHz;
maxFreq = fs/2;
nfft = 256;
nzero = 200;

novl = .95;
nfft = nfft + 1; nzero = nzero - 1;
win =[hamming(nfft);zeros(nzero,1)];
novlp = floor(novl *(nfft +nzero));


% do you need to downsample or upsample?

if maxFreq/yHzmx> 2;

    q = floor(0.5*(maxFreq/yHzmx));
    zoomclip = resample(zoomclip1,1,q);
    fs = fs/q;
    if length(zoomclip) < length(win);

        % decrease the q
        fzw = floor(length(zoomclip)/length(win));
        zoomclip = resample(Z.clip,1,floor(q/fzw));
        fs = fs*fzw;
        q = q/fzw;
    end
else

    zoomclip1 = wavread(wavfile, ...
        [floor(wavtimeMIN*fs) ceil(wavtimeMAX*fs)]);
    zoomclip = zoomclip1; % then you are reverted back to original sampling
    Z.clip = zoomclip1;
    Z.fs = fs;
    Z.nbits = nbits;
    Z.yHzmn = yHzmn;
    Z.yHzmx = yHzmx;
    Z.maxHz =  maxHz;
    maxFreq = fs/2;
    nfft = 256;
    nzero = 200;

    novl = .95;
    nfft = nfft + 1; nzero = nzero - 1;
    win =[hamming(nfft);zeros(nzero,1)];
    novlp = floor(novl *(nfft +nzero));

end

if yHzmx > 1000;
    Ffactor = 1000;
else
    Ffactor = 1;
end

[B,F,T] = spectrogram(zoomclip,win,round(novlp),length(win),fs);

figgy = imagesc(T,F./Ffactor, 20.*log10(abs(B)));
S.figgy = figure('units','normalized',...
    'position',[.05 .15 .55 .7],...
    'menubar','none',...
    'name','ZOOM',...
    'numbertitle','off',...
    'resize','on', ...
    'PaperPositionMode','auto',...
    'deletefcn',{@delete,figgy}, ...
    'UserData',Z);

imagesc(T,F./Ffactor, 20.*log10(abs(B)))

set(gca,'Ylim',([yHzmn yHzmx]./Ffactor));

axis xy
if Ffactor == 1000;
    ylabel(['Freq. (kHz)']);
else
    ylabel(['Freq. (Hz)']);
end

xlabel(['Time (s)',]);


% change date/time of zoom clip start

pngDateTimezoom = datestr(pngDateTime + ...
    datenum(0,0,0,0,0,xtimemn),'yymmdd-HHMMSS');
zoomTitle = [fileMTX{m}(n,1:PngFileDashes(2)) pngDateTimezoom ...
    fileMTX{m}(n, PngFileDashes(4):end)];
title(zoomTitle);

maxB = max(B,[],2);

ff = find(F > yHzmn & F < yHzmx);
Clim2 = 20.*log10(abs(max(maxB(ff))));
set(gca,'Clim',[Clim2-X Clim2]);
colormap(jet)
grid

cd(PngFolder)

hold on
axis manual
S.n = n;
S.m = m;
S.PngFileDashes = PngFileDashes;
S.WhoRan = WhoRan;
S.SpeciesAbbrevs = PNGrslts_MetaData(CheckNum).CheckSpp;
 S.pngDateTimezoom =  pngDateTimezoom;
 S.fileName = fileMTX{m}(n,:);

S.specs = figure('units','Normalized', ...
    'position',[.8 .65 .175 .30],...
    'menub','no',...
    'name','SPEC parameters',...
    'numbertitle','off',...
    'resize','off');
S.txt(1) = uicontrol('style','text',...
    'unit','normalized', ...
    'position',[.07 .85 .2 .065],...
    'string','FFT size','BackgroundColor',...
    [.8 .8 .8], 'FontWeight','bold', ...
    'FontSize', 10,'Value',4);
S.txt(2) = uicontrol('style','text',...
    'unit','normalized', ...
    'position',[.34 .85 .25 .065],...
    'string','Overlap %','BackgroundColor',...
    [.8 .8 .8], 'FontWeight','bold', ...
    'FontSize', 10);
S.txt(3) = uicontrol('style','text',...
    'unit','normalized', ...
    'position',[.625 .85 .275 .065],...
    'string','Smoothing x','BackgroundColor',...
    [.8 .8 .8], 'FontWeight','bold', ...
    'FontSize', 10);

S.NFFT = {'256';'32'; '64';'128';'256';'512';'1024';'2048';'4096';'8192';'16384';'32768'};
S.OVLP = {'95';'0';'25';'50';'75';'80';'85';'90';'95';'97';'98'; '99'; '99.5';'100'};
S.NZERO = {'.7813';'0';'0.5';'.75'; '.8'; '.9'; '.95'; '.975'; '.99'; '1'; '1.5'; '2'; '3'};

S.pp(1) = uicontrol('style','pop',...
    'unit','normalized',...
    'position',[.05 .575 .25 .25],...
    'string',S.NFFT);

S.pp(2) = uicontrol('style','pop',...
    'unit','normalized',...
    'position',[.35 .575 .25 .25],...
    'string',S.OVLP);
S.pp(3) = uicontrol('style','pop',...
    'unit','normalized',...
    'position',[.65 .575 .25 .25],...
    'string',S.NZERO);

S.txt(4) = uicontrol('style','text',...
    'unit','normalized', ...
    'position',[.325 .6 .3 .065],...
    'string','Contrast','BackgroundColor',...
    [.8 .8 .8], 'FontWeight','bold', ...
    'FontSize', 10);

S.pp(4) = uicontrol('style','slide',...
    'unit','normalized',...
    'position',[.1 .5 .75 .075],...
    'min',10,'max',80,'val',25);
S.txt(7) = uicontrol('style','text',...
    'unit','normalized',...
    'position',[.65 .6 .3 .065],...
    'string',X);
set([S.txt(7),S.pp(4)],'call',{@ed_call,S});  % Shared Callback.


S.txt(5) = uicontrol('style','text',...
    'unit','normalized', ...
    'position',[.1 .395 .43 .065],...
    'string','Min Frequency (Hz)','BackgroundColor',...
    [.8 .8 .8], 'FontWeight','bold', ...
    'FontSize', 10);
S.txt(6) = uicontrol('style','text',...
    'unit','normalized', ...
    'position',[.1 .29 .43 .065],...
    'string','Max Frequency (Hz)','BackgroundColor',...
    [.8 .8 .8], 'FontWeight','bold', ...
    'FontSize', 10);

S.pp(5) = uicontrol('style','edit',...
    'unit','normalized',...
    'position',[.6 .375 .3 .1],...
    'string',(Z.yHzmn));

S.pp(6) = uicontrol('style','edit',...
    'unit','normalized',...
    'position',[.6 .27 .3 .1],...
    'string',(Z.yHzmx));

S.replot = uicontrol('style','push',...
    'unit','normalized',...
    'posit',[.05 .05 .2 .15],...
    'string','REPLOT',...
    'Enable','on', ...
    'Callback',{@replot_call,S});

S.save = uicontrol('style','push',...
    'unit','normalized',...
    'posit',[.70 .05 .2 .15],...
    'string','SAVE',...
    'callback',{@save_call,S});


S.play1xfilt = uicontrol('Style', 'push', ...
    'Unit','normalized','Position',[.35 .05 .25 .15],...
    'String', 'PLAY 1X Filt', 'FontSize',8,...
    'Enable','on','Callback', ...
    'playCLIPzoom(butt,PngFolder,1,zoomclip,wavtimeMIN,wavtimeMAX,fs,yHzmn,yHzmx);');


set(figgy,'deletef',{@delete,S.specs})  % Closing one closes the other.


end

function [] = replot_call(varargin)

% Callback for pushbutton, prints out the users choices.
S = varargin{3};  % Get the structure - handles, eventdata, etc...

Z = get(S.figgy,'UserData');
params = get(S.pp(:),{'string','value'});

yHzmn = get(S.pp(1,5),{'string','value'});
yHzmn = str2num(char(yHzmn{1}));


yHzmx= get(S.pp(1,6),{'string','value'});
yHzmx= str2num(char(yHzmx{1}));

contrast = get(S.pp(1,4),{'string','value'});
contrast = contrast{2};

nfftLIST = char(params{1,1});
nfft = str2num(nfftLIST(params{1,2},:));

ovlpLIST = char(params{2,1});
novl = str2num(ovlpLIST(params{2,2},:))/100;

nzeroLIST = char(params{3,1});
nzer = nzeroLIST(params{3,2},:);

nzer = str2num(nzer(1:end));
nzero = floor(nfft*nzer);

nfft = nfft + 1; nzero = nzero - 1;
novlp = floor(novl *(nfft +nzero));
maxFreq = Z.fs/2;
win =[hamming(nfft);zeros(nzero,1)]';
delete(gca)
figure(S.figgy)
if maxFreq/yHzmx > 2;
    
    q = floor(0.5*floor(maxFreq/yHzmx));
    if q ~=1;
        zoomclip = resample(Z.clip,1,q);
        fs = Z.fs/q;
    else
        zoomclip = Z.clip;
        fs = Z.fs;
    end
 
    if length(zoomclip) < length(win);
        % decrease the q
       
        fzw = floor(length(zoomclip)/length(win));
        if fzw == 0;
            zoomclip = Z.clip;
            fs = Z.fs;
            
        else
            zoomclip = resample(Z.clip,1,floor(q/fzw));
            fs = fs*fzw;
        end
    end
else
    zoomclip = Z.origclip;
    fs = Z.origFs;
    %     maxFreq = fs/2;
end

Z.clip = zoomclip;
Z.fs = fs;
Z.yHzmn = yHzmn;
Z.yHzmx = yHzmx;

set(S.figgy,'UserData',Z);

% N = 800;
% b = fir1(N, [max(yHzmn,1) yHzmx]/(fs/2),'DC-0'); 
% zoomclip1 = fftfilt(b,zoomclip);
[B,F,T] = spectrogram(zoomclip,win,round(novlp),length(win),fs);

format bank

if yHzmx > 1000;
    Ffactor = 1000;
else
    Ffactor = 1;
end

imagesc(T,F./Ffactor, 20.*log10(abs(B)));
% if yHzmn >=yHzmx;
%     fs/2
%     yHzmn = 0;
%     yHzmx = floor(fs/2);
% end
set(gca,'Ylim',([yHzmn yHzmx]./Ffactor));
axis xy
if Ffactor == 1000;
    ylabel(['Freq. (kHz)']);
else
    ylabel(['Freq. (Hz)']);
end

xlabel(['Time (s)',]);
maxB = max(B,[],2);

ff = find(F > yHzmn & F < yHzmx);
Clim2 = 20.*log10(abs(max(maxB(ff))));
set(gca,'Clim',[Clim2-contrast Clim2]);
colormap(jet)
drawnow
end

function [] = save_call(varargin);
%,n,m,PngFileDashes, pngDataTimezoom,fileMTX,WhoRan,PNGrsltsMetaData,CheckNum)
% Callback for pushbutton, prints out the users choices.
S = varargin{3};  % Get the structure - handles, eventdata, etc...
Z = get(S.figgy,'UserData');
% enter name for file
load('MyFolderSettings');
zoomclipFolder =  whereExamples;

% working out the automated naming here
FileTitle = [S.fileName(1,1:S.PngFileDashes(2)) S.pngDateTimezoom ...
    '-' S.fileName(1, S.PngFileDashes(4)+1:S.PngFileDashes(4)+2)];
FileTitle = [FileTitle '-' S.WhoRan '-'];

for spas = 1:size(S.SpeciesAbbrevs,1);
    fprintf(1,[num2str(spas) ' ' S.SpeciesAbbrevs(spas,:) '\n']);
end
zoomclipSppName = input('Enter # for species');
extraText = input('Enter any additional text here','s');

if size(extraText,1) == 0;
    FileTitle = [FileTitle  deblank(S.SpeciesAbbrevs(zoomclipSppName,:))];
else
    FileTitle = [FileTitle  deblank(S.SpeciesAbbrevs(zoomclipSppName,:)) '-' extraText];
end

% print('-f2','-dpng','-r200', [zoomclipFolder '\' zoomclipFileName]);
print(S.figgy,'-dpng','-r200', [zoomclipFolder '\' FileTitle]);
%resample to 44.1kHZ for ease of playback. This wasn't being used.


%**************************************************************************
% The following 2 lines standardize the sampling rate to CD quality (in
% case some media players can't handle non-standard sampling rates.
% if 44100/round(Z.fs) > 2;
%     zoomclip3 = resample(Z.clip, round(Z.fs)*2,round(Z.fs)); % double the sampling rate here
%    zoomclip2 = resample(zoomclip3,44100,round(Z.fs)*2);
% else
%     zoomclip2 = resample(Z.clip,44100,round(Z.fs)*2);
% end
% Z.clip = zoomclip2;
% Z.fs = 44100;
%**************************************************************************
Z
normlz = max(abs(Z.clip))*1.01; % make it 1% larger to avoid clipping warning
wavwrite(Z.clip./normlz,round(Z.fs),Z.nbits,[zoomclipFolder '\' FileTitle '.wav'])
end

function [] = ed_call(varargin)
% Callback for the edit box and slider.
[h,S] = varargin{[1,3]};  % Get calling handle and structure.

switch h  % Who called?
    case S.txt(7)
        L = get(S.pp(4),{'min','max','value'});  % Get the slider's info.
        E = str2double(get(h,'string'));  % Numerical edit string.
        if E >= L{1} && E <= L{2}
            set(S.pp(4),'value',E)  % E falls within range of slider.
        else
            set(h,'string',L{3}) % User tried to set slider out of range.
        end
    case S.pp(4)
        set(S.txt(7),'string',get(h,'value')) % Set edit to current slider.
    otherwise
        % Do nothing, or whatever.
end

end