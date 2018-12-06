function [resltMTX,whoMTX,butt,n,m,currentContrast,PNGrslts_MetaData,pngCounter,f1,f2] = ...
    button(resltMTX, fileMTX, whoMTX, CheckNum, WaveFolder, ...
    ResultsFolder,PngFolder, butt,n,m,Recorder, ...
    PNGrslts_MetaData,currentContrast,handleMTX, WhoRan,pngCounter,f1,f2); %n is png; m is day; o is spp
%v5.1 5/10/16 - added option of holding choices over to next png
%v5.0 1/15/15 - got rid of all the special autodetection code including
%pink coloring - going to treat the autodetector as an analyst that hasn't
%been reviewed - in Tethys.  No need for special code here.These changes
%should also fix Eliza's weird NWN selections.

%v4.0 04/04/13 - keyboard shortcuts for lighten/darken/done
%v3.0 12/28/12 - multiple species review now
%v2.1  3/27/12  - adding in 999 to skip over some of the haruphone pngs
%v2.0  12/27/11 - darken/lighten stays until changed.
% v1.2  5/9/11
if exist([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName])
    load([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName], ...
        'resltMTX','whoMTX','PNGrslts_MetaData');
end


for o = 1:size(handleMTX,1);
    
    selected = get(eval(['butt.objgrp' num2str(o)]),'SelectedObject');
    answer = find(handleMTX(o,:) == selected);
    if answer ~=3;
        resltMTX(n,m,o) = answer;
    elseif answer == 3;
        resltMTX(n,m,o) = 0;
    end
end

% check to see if all your answers were nwn
resltMTXanswers = resltMTX(n,m,1:o);
urMans = unique(resltMTXanswers);

if urMans == 4;
    %all are nwn - default to this for next time;
    NWN = 1;
else
    % default to all no's.
    NWN = 0;
end

% after you choose - and original was an autodetector result -
% you must set background color back to gray.

whoMTX{m}(n,:) = WhoRan;
PngFileDashes = strfind(fileMTX{1}(1,:),'-');  %just look at 1st file of 1st folder.
for ff = 1:size(fileMTX,2);
    PngDays(ff,:) = char(fileMTX{ff}(1,PngFileDashes(2)+1:PngFileDashes(2)+6));
end

% current day/time interval is
curfile = fileMTX{m}(n,:);

% advance to next png (and its associated day) - or you are looking at
% every png file
% then check that there isn't already an answer:

checkit = 0;
while checkit == 0;
    n = n+1;
    if n > size(fileMTX{m},1); % you have run out of pngs for that day
        m = m+1; % then you are on the next day
        n = 1;   % and need to start with the first png of that day
        if m > size(PngDays,1); % you have run out of days!
            set(butt.obj2,'visible','off');
            set(butt.obj0,'String','DONE');
            pause(1.5)
            fprintf(1,'You are ALL DONE with this run!');
            
    save([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName], ...
        '*MTX','PNGrslts_MetaData');

            
        end
    end
    checkit = 1;
end

if n == 1 & m == 1;
    set(butt.obj1,'visible','off');
else
    set(butt.obj1,'visible','on');
end
% Plot out next png to examine: *****************************************
if m <= size(PngDays,1);
    
    [n,m,currentContrast] = pngPLOT(fileMTX,PngFolder,n,m,currentContrast);
    % and set the buttons back to their defaults (or pre-selected values
    % (from autodetectors or previous old runs))).
    
    % first set to defaults:
 if get(butt.hold,'Value') == 1;
     % then hold the choices
 else % then do the resetting to whatever the previous was.
    for o = 1:size(handleMTX,1);
        %find what original selection is and set buttons
        
        if  resltMTX(n,m,o) == 99;
            if NWN == 1;
                set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,4));  % NWN is selection
            else
                set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));  % No is selection
            end
        else
            if resltMTX(n,m,o) ~=0;
                set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,resltMTX(n,m,o)));
            else
                set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));
            end
        end
    end
 end 
    PNGrslts_MetaData(CheckNum).startday = m;
    PNGrslts_MetaData(CheckNum).startpng = n;
    
    % save results matrix so answer is not lost if system crashes ************
     save([ResultsFolder '\' PNGrslts_MetaData(CheckNum).FileName], ...
        '*MTX','PNGrslts_MetaData');
    
    pngCounter = pngCounter+1;
    butt.obj0 = uicontrol('Parent',f1,'Style','Text', ...
        'String', num2str(pngCounter),'backgroundcolor',[1 1 1], ...
        'Units','normalized','Position',[.92 .92 .05 .025]);
    
    assignin('base','n',n);
    assignin('base','m',m);
    
    assignin('base','pngCounter',pngCounter);
    if get(butt.review,'Value') ~= 1;
        
        Getvars = get(f2,'WindowKeyPressFcn');
        whoMTX = Getvars{13};
        %     currentContrast = Getvars{8};
        Getvars{10} = pngCounter;
        Getvars{6} = n;
        Getvars{7} = m;
        
        Getvars{2} = butt;
        set(f2,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
        set(f1,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
    end
end

