function [PNGrslts_MetaData,currentContrast,n,m,pngCounter,resltMTX] = ...
    lighten(butt,PngFolder,WaveFolder, fileMTX,n,m,currentContrast, ...
    f1,f2,PNGrslts_MetaData,pngCounter,resltMTX,whoMTX,CheckNum, ...
    ResultsFolder,Recorder,handleMTX,WhoRan)
%v4.0 04/04/13 - keyboard shortcuts for lighten/darken/done
%v3.0 12/28/12 - multiple species review now
% v2.0  12/27/11 - darken/lighten stays until changed.

Getvars = get(f2,'WindowKeyPressFcn');
reviewCntr = Getvars{21};  % this will take the counter from either the key or the button.
resltMTX = Getvars{12};
whoMTX = Getvars{13};
butt = Getvars{2};
currentContrast = Getvars{8};
n = Getvars{6};
m = Getvars{7};

% v1.0 11/16/11
if get(butt.light,'Value') == 1;  %YES
    % pull up a more contrast-y version of the png.
    findSlashes = findstr('\', PngFolder);
    endslash = findSlashes(end);
    baseDB = str2num(PngFolder(endslash+7:endslash+9));
    cd(PngFolder(1:endslash));
    ldBs = dir('png*');
    ldBs = char(ldBs.name);
    PngType = PngFolder(size(PngFolder,2)-9:size(PngFolder,2)-7);
    justThese = strmatch(['png' PngType],ldBs);
    ldBs = ldBs(justThese,:);
    
    otherDB = str2num(ldBs(:,7:8));
    currentContrastNUM = max(find(otherDB < currentContrast));
    if isempty(currentContrastNUM)==1;
        currentContrastNUM = find(otherDB == baseDB);
    end
    currentContrast = otherDB(currentContrastNUM);
    assignin('base','currentContrast',currentContrast);
    thisFile = fileMTX{m}(n,:);
       
    thisDash = strfind(thisFile,'-');
    thisFile(thisDash(4)+1:thisDash(4)+2) = num2str(currentContrast,'%02.0f');
    
    thisMonth = datestr(datenum(thisFile(thisDash(2)+1:thisDash(3)-1), ...
        'yymmdd'),'mm_yyyy');
    thisDay = thisFile(thisDash(2)+1:thisDash(3)-1);
    cd ([deblank(ldBs(currentContrastNUM,:)) '\' thisMonth '\' thisDay]);
    pngImage = imread(thisFile);
    f2 = figure(2);
    f1 = figure(1);
    im =imagesc(pngImage);
        Getvars{21} = reviewCntr;
Getvars{12} =  resltMTX;
Getvars{13} = whoMTX;
Getvars{2} = butt;
Getvars{8} = currentContrast;
  set(f2,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
 set(f1,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button


    set(gca,'Position',[.01 .01 .97 .97]);
    set(im,'EraseMode','background');
    
    axis off

end

