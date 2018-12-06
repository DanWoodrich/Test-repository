function [excelApp, excelWorkbook,excelFlag] = notes(notesFile,fileMTX,n,m,Sounds,CheckNum,WhoRan,butt,var1,var2)
% CLB
%v4.0 04/04/13 - multi-line works now
%v3.0 12/28/12 - multiple species review now

SppNum = get(gco,'UserData');
notePrmt= 'Enter text here';
noteTitle = 'Notes';
noteDef = { ' '};
num_lines = 6;
nT = newid(notePrmt,noteTitle,num_lines,noteDef);
nTT =  cellstr(char(nT));
noteText = strjoin(nTT,' ');
noteTextnocomma = strrep(noteText,',',';');

png = char(fileMTX{m}(n,:));
png = png(1:end-4);
Species = Sounds(CheckNum).Spp{SppNum};
% is the file open already?
fid = fopen(notesFile,'a+')
if fid <0;
   % 'Then close it'   
   excelWorkbook = var2
   excelApp = var1
excelApp.DisplayAlerts = false;
   excelWorkbook.Save;  
    excelWorkbook.Close;
      % now to open the file
     fid = fopen(notesFile,'a+')
end
% and write to it
fprintf(fid,'%s,%s,%s,%s,%s\n',png, char(Species),noteTextnocomma,WhoRan,datestr(now));
% and close it
fclose(fid)
if exist('excelApp','var')
else
    excelApp = actxserver('Excel.Application'); 
end
excelApp.visible = true;
% and open it to view
% Open file called test.xls, located in the current folder.
excelWorkbook = excelApp.Workbook.Open(notesFile);
ActiveSheet = excelWorkbook.Activesheet;
excelFlag = 1;
% set the column widths here
ActiveSheet.Columns.Item('A').ColumnWidth = '24';
ActiveSheet.Columns.Item('B').ColumnWidth = '10';
ActiveSheet.Columns.Item('C').ColumnWidth = '70';
ActiveSheet.Columns.Item('D').ColumnWidth = '5';
ActiveSheet.Columns.Item('E').ColumnWidth = '14';
ActiveSheet.Columns.Item('F').ColumnWidth = '13';
% and get the excel window to come up in the same spot on the
% desktop and at the same size each time.
set(excelApp,'Left',10); % this is where the left edge of the excel window goes
set(excelApp,'Top',10) % this is where the right edge of the excel window goes
set(excelApp,'Height',400) %this is the height of the excel
set(excelApp,'Width',825) %this is the width of the excel
% and scroll down to the last entry
robj = ActiveSheet.Columns.End(4);
numrows = robj.row;



