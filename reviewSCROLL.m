function [butt,resltMTX,currentContrast, PNGrslts_MetaData,reviewCntr,n,m,f1,f2,whoMTX] = ...
    reviewSCROLL(fileMTX,PngFolder, resltMTX,handleMTX,PNGrslts_MetaData,CheckNum, ...
    butt,dirx,currentContrast,Sounds,reviewCntr,strtRevCntr,f1,f2,whoMTX, ResultsFolder);

%v3.0 12/28/12 - multiple species review now
% v2.1 03/27/12 - added changing answer function - saves to Changes file in
% pngResults folder
% v2.0  12/27/11 - darken/lighten stays until changed.

% v1.2  5/9/11
% find what next or previous file to go to.
% m = findDay from reviewMode

Getvars = get(f2,'WindowKeyPressFcn');
reviewCntr = Getvars{21};  % this will take the counter from either the key or the button.
resltMTX = Getvars{12};
whoMTX = Getvars{13};
butt = Getvars{2};
currentContrast = Getvars{8};

nm = get(butt.review,'UserData');

choices = nm(1,1);
Rn = nm(3:end,2); % this just limits to the real date/time values
Rm = nm(3:end,1); % this just limits to the real date/time values
Rfiles = nm(3:end,3); % this just limits to the real date/time values

if dirx <0;
    reviewCntr = max(reviewCntr-1,1);
    for bn = 5:6;
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','on');
    end
elseif dirx > 0;
    reviewCntr = min(reviewCntr+1,size(Rn,1));
    
    for bn = 5:6;
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','on');
    end
end
dispRevCntr = reviewCntr-strtRevCntr;
butt.obj20 = uicontrol('Parent',f1,'Style','Text', ...
    'String', num2str(dispRevCntr),'backgroundcolor',[1 1 1], ...
   'Units','normalized','Position',[.05 .92 .05 .025]);

nm(2,3) = dirx;
set(butt.review,'UserData',nm);
n = Rn(reviewCntr);
m = Rm(reviewCntr);
Getvars{6} = n;
Getvars{7} = m;
Getvars{21} = reviewCntr;
Getvars{12} =  resltMTX;
Getvars{13} = whoMTX;
Getvars{2} = butt;
Getvars{8} = currentContrast;
  set(f2,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
 set(f1,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button

[n,m,currentContrast] = pngPLOT(fileMTX, ...
    PngFolder,n,m,currentContrast);

%find what original selection is and set buttons


for o = 1:size(handleMTX,1);
    if  resltMTX(n,m,o) == 99;
        set(eval(['butt.objgrp' num2str(o)]), ...
            'SelectedObject',handleMTX(o,3));  % No is selection
    else
        if resltMTX(n,m,o) ~=0;
            if resltMTX(n,m,o) < 99
                set(eval(['butt.objgrp' num2str(o)]), ...
                    'SelectedObject',handleMTX(o, ...
                    resltMTX(n,m,o)));
            end
        else
            set(eval(['butt.objgrp' num2str(o)]), ...
                'SelectedObject',handleMTX(o,3));
        end
    end
end
