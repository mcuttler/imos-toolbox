function sample_data = salinityPP( sample_data )
%SALINITYPP Adds a salinity variable to the given data sets, if they
% contain conductivity, temperature and pressure variables. 
%
% This function uses the CSIRO Matlab Seawater Library to derive salinity 
% data from conductivity, temperature and pressure. It adds the salinity 
% data as a new variable in the data sets.Data sets which do not contain 
% conductivity, temperature and pressure variable are left unmodified.
%
% Inputs:
%   sample_data - cell array of data sets, ideally with conductivity, 
%                 temperature and pressure variables.
%
% Outputs:
%   sample_data - the same data sets, with salinity variables added.
%
% Author: Paul McCarthy <paul.mccarthy@csiro.au>
%

%
% Copyright (c) 2009, eMarine Information Infrastructure (eMII) and Integrated 
% Marine Observing System (IMOS).
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are met:
% 
%     * Redistributions of source code must retain the above copyright notice, 
%       this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in the 
%       documentation and/or other materials provided with the distribution.
%     * Neither the name of the eMII/IMOS nor the names of its contributors 
%       may be used to endorse or promote products derived from this software 
%       without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.
%
error(nargchk(nargin, 1, 1));

if ~iscell(sample_data), error('sample_data must be a cell array'); end
if isempty(sample_data), return;                                    end

for k = 1:length(sample_data)
  
  sam = sample_data{k};
  
  cndcIdx = getVar(sam.variables, 'CNDC');
  tempIdx = getVar(sam.variables, 'TEMP');
  presIdx = getVar(sam.variables, 'PRES');
  
  % cndc, temp, or pres not present in data set
  if ~(cndcIdx || tempIdx || presIdx), continue; end
  
  % data set already contains salinity
  if getVar(sam.variables, 'PSAL'), continue; end
  
  cndc = sam.variables{cndcIdx}.data;
  temp = sam.variables{tempIdx}.data;
  pres = sam.variables{presIdx}.data;
  
  % calculate C(S,T,P)/C(35,15,0) ratio
  R = cndc ./ 4.2914;
  
  % calculate salinity
  psal = sw_salt(R, temp, pres);
  
  % add salinity data as new variable in data set
  sample_data{k} = addVar(...
    sam, ...
    'PSAL', ...
    psal, ...
    getVar(sam.dimensions, 'TIME'), ...
    'salinityPP.m: derived from CNDC, TEMP and PRES');
end