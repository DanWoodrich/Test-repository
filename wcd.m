% WCD Change current working directory.
%
%     WCD is the improved version of the CD which allow the wildcard.
%
%     Examples:
%
%     WCD
%        display the current directory
%
%     WCD data*
%        set the current directory to the one started by the 'data'.
%
%     WCD d:\work*\art*
%        set the current directory to the d:\works\artifacts, for example.
%
%
%     See CD.
%
% 
% Taegyu Yim
% APR. 28, 2004

function cWD = wcd(nPath)

if nargin > 1,
   error('Too many input argment.')
end

if nargin == 1,

   if ~isstr(nPath),
      error('Argument must contain a string.')
   end

   while 1,

      [nPath,rPath] = strtok(nPath, '\');

      % for root directory
      if nPath(end) == ':',
         nPath = [nPath '\'];
      end

      if findstr(nPath,'*'),
         dirList = dir(nPath);
         nPath   = {dirList(find(str2num(sprintf('%d ',dirList.isdir)))).name};
         if length(nPath) ~= 1,
            error('Can not identify the directory!')
         else,
            cd(nPath{1})
         end
      else,
         cd(nPath)
      end

      if isempty(rPath),
         break
      else,
         nPath = rPath(2:end);
      end

   end  % end of while 1

end

if nargout == 1,
   cWD = pwd;
else
   disp(pwd)
end