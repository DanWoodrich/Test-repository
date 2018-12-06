function [n,m,currentContrast] = pngPLOT(fileMTX,PngFolder,n,m,currentContrast);
%
%v3.0 12/28/12 - multiple species review now
% v2.0  12/27/11 - darken/lighten stays until changed.

% v1.2 5/9/11
% takes png file and folder path
% and plots png up onto the query window
%  cla reset

%   delete(gca)
% put contrast back to BASE

findSlashes = findstr('\', PngFolder);
% baseDB = str2num(PngFolder(findSlashes(3)+7:findSlashes(3)+9));
% currentContrast = baseDB;
PngType = PngFolder(size(PngFolder,2)-9:size(PngFolder,2)-7);
% baseDB = str2num(PngFolder(findSlashes(3)+7:findSlashes(3)+9));
baseDB = str2num(PngFolder(size(PngFolder,2)-6:size(PngFolder,2)-4));
 PngFolderNEW = PngFolder;
if currentContrast ~= baseDB;
   
    PngFolderNEW = [PngFolderNEW(1:findSlashes(end)) 'png' PngType num2str(currentContrast)];
end

thisFile = fileMTX{m}(n,:);
    
thisDash = strfind(thisFile,'-');

thisMonth = datestr(datenum(thisFile(thisDash(2)+1:thisDash(3)-1), ...
    'yymmdd'),'mm_yyyy');
thisDay = thisFile(thisDash(2)+1:thisDash(3)-1);
cd ([PngFolderNEW '\' thisMonth '\' thisDay])
fileNAME = fileMTX{m}(n,:);
findDashes = findstr('-', fileNAME);
fileNAME(findDashes(end)+1:findDashes(end)+2) = num2str(currentContrast);
pngImage = imread(fileNAME);
figure(1)
		% Clear line objects.
		findImage = findobj(figure(1), 'Type', 'image');
		if ~isempty(findImage)
			delete(findImage);
		end
		
im =imagesc(pngImage);
set(gca,'Position',[.01 .01 .97 .97])
set(im,'EraseMode','background');

axis off
