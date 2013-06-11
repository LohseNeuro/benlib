function varargout = batchmode(fn, filespec, varargin)
% function batchmode(fn, filepattern, varargin)
% 
% Applies a function to all files matching filepattern
% 
% Inputs:
%  fn -- function name or handle
%  filespec -- pattern the files should match, or list of files
%  varargin -- parameters that will be passed to fn
%  ..., 'reverse' or 'flip' -- last argument should be one of these
%    if you want the files to be processed in reverse order

% e.g. batchmode('compute_csdkernel', './metadata/*.mat', 10, 6.25, 6.25)

reverse = false;
if ~isempty(varargin) && isstr(varargin{end})
  if strcmp(varargin{end}, 'reverse') || strcmp(varargin{end}, 'flip')
    reverse = true;
    varargin = varargin(1:end-1);
  end
end

if isstr(fn)
  fnstr = fn;
else
  fnstr = func2str(fn);
end

% create log dir if it doesn't exist
logdir = './batch.log';
if ~exist(logdir, 'dir')
  mkdir(logdir);
end

% overcomplicated formatting of parameters for printing in log file
paramsdot = [];
paramscomma = [];
for ii = 1:length(varargin)
  if isstr(varargin{ii})
    pstr = varargin{ii};
    paramsdot = [paramsdot pstr '.'];
    paramscomma = [paramscomma ', ''' pstr ''''];
  elseif isnumeric(varargin{ii}) && isscalar(varargin{ii})
    pstr = num2str(varargin{ii});
    paramsdot = [paramsdot pstr '.'];
    paramscomma = [paramscomma ', ' pstr];
  else
    pstr = '.';
  end
end

% logfile filename
logfile = [logdir filesep datestr(now, 'yyyy.mm.dd_HH.MM') '.' ...
	   fnstr '.' paramsdot 'log'];
	   
% start saving output to logfile
diary(logfile);

% find files matching filespec (unless it is already a list)
if isstr(filespec)
  files = getfilesmatching(filespec);
else
  files = filespec;
end

% reverse order in which files will be processed
if reverse
  files = flipud(files);
end

% do it
nargs = nargout(fn);
result = {};

% loop through files
for ii = 1:length(files)
  diary on;
  file = files{ii};
  fprintf(['== Running ' fnstr '(''' file '''' paramscomma ') ...\n']);

  try
    if nargs==0
      feval(fn, file, varargin{:});
    elseif nargs<0 || nargs==1
      out = feval(fn, file, varargin{:});
      result{end+1} = out;
    else
      [out{1:nargs}] = feval(fn, file, varargin{:});
      result{end+1} = out;
    end
    
    fprintf(['-> ' fnstr ' ' file  ' success\n\n']);

  catch
    warning(lasterr);
    fprintf(['-> ' fnstr ' ' file  ' failure\n\n']);

  end

  diary off;
end

diary off;

try
  result = [result{:}];
end

if length(result)
 [varargout{1:nargout}] = result;
end
