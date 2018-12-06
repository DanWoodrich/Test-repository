function [currentContrast, PNGrslts_MetaData,resltMTX,whoMTX,butt, ...
    n,m,reviewCntr,strtRevCntr] = hopToMode(butt, resltMTX,whoMTX,handleMTX,fileMTX, ...
    PNGrslts_MetaData,CheckNum,PngFolder, currentContrast, Sounds, ...
    WhoRan,ResultsFolder,Recorder,n,m, f1, f2, WaveFolder,pngCounter);
%v1.0 12/31/14 clb
% this is a short cut to review mode.
% it is just like review mode, but short cuts straight to a date/time
% this just hops you back to a particular png.  You can scroll back and forth from
% there, then it hops you back to where you just left off.
if get(butt.hop_to,'Value') == 1;  %ON
    set(butt.hop_to,'BackgroundColor',[0 1 0]);
    prompt = {'Date (yymmdd)', 'Time (hhmmss)'};
    currfile = fileMTX{m}(n,:);
    dashes = strfind(currfile,'-');
    currdate = currfile(dashes(2)+1:dashes(3)-1);
    currtime = currfile(dashes(3)+1:dashes(4)-1);
    set(butt.hop_to,'UserData',[n m] );
    def = {currdate, currtime};
    spoint = newid(prompt,'Start Point',1,def);
    for bn = [1 2 5 6];
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','off');
    end
      set(butt.hold,'Visible','off');
    % you are just going to choose all the pngs here - like choice
    % [png day spp] is what [Rn Rm Ro] are.
    choices = 7;
    
    [Rindx] = findn(resltMTX(:,:,1) <=99);
    
    % these are unique pngs/days because just looking at first spp.
    % no need to choose all spps just to reduce to the first one.
    Rm = Rindx(:,2);
    Rn = Rindx(:,1);
    
    % but then you need to make sure to ignore any of the 99's not associated
    % with a fileMTX file.. (i.e. that the 99 was a placeholder)
    
    for pp = 1:size(fileMTX,2);
        szfiles(pp) = size(fileMTX{pp},1);
    end
    
    uRm = unique(Rm);
    elim = [];
    for inz = 1:size(uRm,1);
        fuRm = find(Rm == uRm(inz));
        allRn = Rn(fuRm);
        fallRn = find(allRn > szfiles(uRm(inz)));
        if isempty(fallRn);
            % great, all are okay)
        else
            % need to eliminate these ones from the list
            elim = [elim; Rm(fuRm(fallRn)) allRn(fallRn)];
        end
    end
    
    if isempty(elim) == 0;
        newRs = setdiff([Rm Rn], elim,'rows');
        Rm = newRs(:,1);
        Rn = newRs(:,2);
    else
        % no changes to Rm or Rn
    end
    dirx = 1;
    
    fileshere = char(fileMTX);
    FilesDateNum = datenum(fileshere(:, ...
        dashes(2)+1:dashes(4)-1),'yymmdd-HHMMSS');
    
    set(butt.review,'UserData',[choices choices choices; m n dirx; ...
        [Rm Rn FilesDateNum]]);
    
    %currfile is the file you were on when you hit 'review mode'
    %spoint is the date/time you entered in the popup window
    
    % Get the entered date/time
    findDay = datenum([char(spoint(1,:)) char(spoint(2,:))], ...
        'yymmddHHMMSS');
    % match that date/time
    reviewCntr = find(FilesDateNum == findDay);
    
    if isempty(reviewCntr);
        msgbox('That date/time does not exist. Try again!');
        %n and m are the current ones still
    else
        n = Rn(reviewCntr);
        m = Rm(reviewCntr);
    end
    [n,m,currentContrast] = pngPLOT(fileMTX,PngFolder,n,...
        m,currentContrast);
    for o = 1:size(handleMTX,1);
        if  resltMTX(n,m,o) == 99;
            set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));  % No is selection
        else
            if resltMTX(n,m,o) ~=0;
                set(eval(['butt.objgrp' num2str(o)]), ...
                    'SelectedObject',handleMTX(o, ...
                    resltMTX(n,m,o)));
            else
                set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));
            end
        end
    end
    % turn on scrolling buttons
    for bn = 5:6;
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','on');
        strtRevCntr = reviewCntr;
        dispRevCntr = 0;   % start from 0 here - you haven't reviewed one until you've gone forward one.
    end
    set(butt.change,'visible','on');
    butt.obj20 = uicontrol('Parent',f1,'Style','Text', ...
        'String', num2str(dispRevCntr),'backgroundcolor',[1 1 1], ...  % dispRevCntr here is 1 because it starts with first one.
        'Units','normalized','Position',[.05 .92 .05 .025]);
    set(f2,'WindowKeyPressFcn',{@keytry2,butt,PngFolder,WaveFolder,fileMTX,n,m,currentContrast,...
        PNGrslts_MetaData,pngCounter,f1,resltMTX,whoMTX,CheckNum,ResultsFolder,Recorder,handleMTX,WhoRan,f2,Sounds,reviewCntr,strtRevCntr});
    set(f1,'WindowKeyPressFcn',{@keytry2,butt,PngFolder,WaveFolder,fileMTX,n,m,currentContrast,...
        PNGrslts_MetaData,pngCounter,f1,resltMTX,whoMTX,CheckNum,ResultsFolder,Recorder,handleMTX,WhoRan,f2,Sounds,reviewCntr,strtRevCntr});
    
elseif get(butt.hop_to,'Value') == 0;  %OFF
    set(butt.hop_to,'BackgroundColor',[0.941176 0.941176 0.941176]);
    % and now go back to currfile:
    for bn = [1 2];
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','on');
    end
    for bn = 5:6;
        button = eval(['butt.obj' num2str(bn)]);
        set(button,'visible','off');
    end
    set(butt.change,'visible','off');
    
    nm = get(butt.hop_to,'UserData');
    n = nm(1);   % these set the n and m back to the place you left off
    m = nm(2);    % before the review started.
    [n,m] = pngPLOT(fileMTX,PngFolder,n,m,currentContrast);
    for o = 1:size(handleMTX,1);
        %find what original selection is and set buttons
        if  resltMTX(n,m,o) == 99;
            set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));  % No is selection
        else
            if resltMTX(n,m,o) ~=0;
                set(eval(['butt.objgrp' num2str(o)]), ...
                    'SelectedObject',handleMTX(o,resltMTX(n,m,o)));
            else
                set(eval(['butt.objgrp' num2str(o)]),'SelectedObject',handleMTX(o,3));
            end
        end
    end
    Getvars = get(f2,'WindowKeyPressFcn');
    resltMTX = Getvars{12};
    whoMTX = Getvars{13};
    currentContrast = Getvars{8};
    butt = Getvars{2};
    set(butt.hop_to,'Value',0);
    set(butt.hold,'Visible','on');
    set(butt.obj20,'String','0');
    reviewCntr = 0;
    strtRevCntr = 0;
    Getvars{21} = reviewCntr;
    Getvars{2} = butt;
    Getvars{8} = currentContrast;
    Getvars{6} = n;
    Getvars{7} = m;
    set(f2,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
    set(f1,'WindowKeyPressFcn',Getvars);  % here is where it enters the counter from either key or button
end
