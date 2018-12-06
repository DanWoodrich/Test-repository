function playCLIP(butt,PngFolder,WaveFolder,fileMTX,PNGrslts_MetaData,CheckNum,n,m,filT,f2)

%v3.0 12/28/12 - multiple species review now
% v2.2 3/6/12 - changed to work on 2 row pngs
% v2.1 2/23/12 - changed to go across rows and to select in between rows.
% Also filters sound based on selected frequency limits if selected.

% v2.0 12/29/11 Changed so selection can spill into margins to get min/max
% frequency range.

% v1.2  5/9/11
if get(butt.play1x,'Value') == 1;
    X = 1;
elseif get(butt.play1xfilt,'Value') == 1;
    X = 1;
elseif get(butt.playXx,'Value') == 1;
    X = inputBOX('Enter speed (e.g.: 4, 0.5, etc)',1);
elseif get(butt.playXxfilt,'Value') == 1;
    X = inputBOX('Enter speed (e.g.: 4, 0.5, etc)',1);
end
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
if numrows == 4;   
    rowX = [.1364 .9009];
    rowY = [.0764 .2302; .2931 .4539; .5133 .6741; .7318 .8925];
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
% plot(maxX*nX,maxY*nY,'ro');
Getvars = get(f2,'WindowKeyPressFcn');
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
cd(mo)
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

extime = (pngDateTime -wavsDateTime(thisWav)).*24.*3600;
wavfile = wavs(thisWav,:);
% add on base time for that png file:
wavtimeMIN = xtimemn+extime; % in seconds.
wavtimeMAX = xtimemx+extime; % in seconds.

% apply filters where needed.

 [sc,fs,nbits] = wavread(wavfile,1);

 soundclip = wavread(wavfile,[floor(wavtimeMIN*fs) ceil(wavtimeMAX*fs)]);
 if filT == 1;

     N = 800;
     b = fir1(N, [max(yHzmn,1) yHzmx]/(fs/2),'DC-0');
     soundclip1 = fftfilt(b,soundclip);
 else
     soundclip1 = soundclip;
 end
soundsc(soundclip1,fs*X)
cd(PngFolder)
      