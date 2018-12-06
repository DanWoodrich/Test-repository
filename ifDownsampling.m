allwaves = monthstuff(N).wavsuse;
dashwaves = strfind(allwaves(1,:),'-');
whichwaves = strmatch(PngDaysInMonth(DN,:), ...
    allwaves(:,dashwaves(2)+1:dashwaves(3)-1));
daywaves = allwaves(whichwaves,:);

dashpngs = strfind(pngs(1,:),'-');
pngdatetimes = datenum(pngs(:,dashpngs(2)+1:dashpngs(4)-1),'yymmdd-HHMMSS');

if monthStart == 1;

    for ddx = 1:size(daywaves,1);
        totalpng = [];
        totalpngnext = [];
        fp = find(pngdatetimes == datenum(daywaves(ddx,dashwaves(2)+1:end-4),'yymmdd-HHMMSS'));
        whichpng = pngdatetimes(fp);
        whichwave = find(datenum(monthstuff(N).wavsuse(:,dashwaves(2)+1:end-4),'yymmdd-HHMMSS') == whichpng);
        if ismember(whichwave,monthstuff(N).partialfiles) == 1;
            totalpng = [totalpng fp];
        else
            totalpng = [totalpng fp];
            for x = 1:pngsPerWav-1;
                if fp+x > size(pngs,1);
                    % need to get png from next day
                    totalpngnext = [N,DN ,x];
                else
                    totalpng = [totalpng fp+x ];
                    totalpngnext = [];
                end
            end
        end
        if exist('fileMTX')  == 1;
            if size(fileMTX,2) <DN+DayAdd;
                fileMTX{DN+DayAdd} = [];
            end
        else
            fileMTX{1} = [];
        end
        fileMTX{DN+DayAdd} = [fileMTX{DN+DayAdd}; pngs(totalpng,:)];
        Psize(DN+DayAdd) = size(pngs,1);
        if isempty(totalpngnext) == 0;

            fileMTX{DN+DayAdd+1} = [];
            for zz = 1:size(totalpngnext,1);
                if totalpngnext(zz,2)+1 <= size(PngDaysInMonth,1);
                    cd(PngFolder)
                    % then you are on same month
                    cd(PngMonths(N,:))
                    cd(PngDaysInMonth(totalpngnext(zz,2)+1,:));
                    pngs = ls;
                    pngs = pngs(3:end,:);
                    StupidThumbs = strmatch('Thumbs',pngs);
                    pngs = pngs(setdiff(1:size(pngs,1),StupidThumbs),:);
                    fileMTX{DN+DayAdd+zz} = [fileMTX{DN+DayAdd+zz}; pngs(totalpngnext(zz,3),:)];
                else
                    cd(PngFolder)
                    cd(PngMonths(totalpngnext(zz,1)+1,:))
                    PngDaysInMonth = ls;
                    PngDaysInMonth = PngDaysInMonth(3:end,:);
                    cd(PngDaysInMonth(1,:));
                    pngs = ls;
                    pngs = pngs(3:end,:);
                    StupidThumbs = strmatch('Thumbs',pngs);
                    pngs = pngs(setdiff(1:size(pngs,1),StupidThumbs),:);
                    fileMTX{DN+DayAdd+zz} = [fileMTX{DN+DayAdd+zz}; pngs(totalpngnext(zz,3),:)];
                end

            end

            cd(PngFolder)
        end
    end
else
    if ismember(N,monthStart) == 1;
        % then waves already skipped, don't have to skip
        % again

        fileMTX{DN+DayAdd} = pngs(1:end,:);
    else

        for ddx = 1:size(daywaves,1);
            totalpng = [];
            totalpngnext = [];
            fp = find(pngdatetimes == datenum(daywaves(ddx,dashwaves(2)+1:end-4),'yymmdd-HHMMSS'));
            whichpng = pngdatetimes(fp);
            whichwave = find(datenum(monthstuff(N).wavsuse(:,dashwaves(2)+1:end-4),'yymmdd-HHMMSS') == whichpng);
            if ismember(whichwave,monthstuff(N).partialfiles) == 1;
                totalpng = [totalpng fp];
            else
                totalpng = [totalpng fp];
                for x = 1:pngsPerWav-1;
                    if fp+x > size(pngs,1);
                        % need to get png from next day
                        totalpngnext = [N,DN ,x];
                    else
                        totalpng = [totalpng fp+x ];
                        totalpngnext = [];
                    end
                end
            end
            if exist('fileMTX')  == 1;
                if size(fileMTX,2) <DN+DayAdd;
                    fileMTX{DN+DayAdd} = [];
                end
            else
                fileMTX{1} = [];
            end
            fileMTX{DN+DayAdd} = [fileMTX{DN+DayAdd}; pngs(totalpng,:)];
            Psize(DN+DayAdd) = size(pngs,1);
            if isempty(totalpngnext) == 0;

                fileMTX{DN+DayAdd+1} = [];
                for zz = 1:size(totalpngnext,1);
                    if totalpngnext(zz,2)+1 <= size(PngDaysInMonth,1);
                        cd(PngFolder)
                        % then you are on same month
                        cd(PngMonths(N,:))
                        cd(PngDaysInMonth(totalpngnext(zz,2)+1,:));
                        pngs = ls;
                        pngs = pngs(3:end,:);
                        StupidThumbs = strmatch('Thumbs',pngs);
                        pngs = pngs(setdiff(1:size(pngs,1),StupidThumbs),:);
                        fileMTX{DN+DayAdd+zz} = [fileMTX{DN+DayAdd+zz}; pngs(totalpngnext(zz,3),:)];
                    else
                        cd(PngFolder)
                        cd(PngMonths(totalpngnext(zz,1)+1,:))
                        cd(PngDaysInMonth(1,:));
                        pngs = ls;
                        pngs = pngs(3:end,:);
                        StupidThumbs = strmatch('Thumbs',pngs);
                        pngs = pngs(setdiff(1:size(pngs,1),StupidThumbs),:);
                        fileMTX{DN+DayAdd+zz} = [fileMTX{DN+DayAdd+zz}; pngs(totalpngnext(zz,3),:)];c
                    end

                end

                cd(PngFolder)
            end

        end
    end
end
