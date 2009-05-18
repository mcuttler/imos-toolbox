function displayManager( fieldTrip, sample_data,...
                         autoQCRequestCallback,...
                         manualQCRequestCallback,...
                         exportRequestCallback)
%DISPLAYMANGER Manages the display of data.
%
% The display manager handles the interaction between the main window and
% the rest of the toolbox. It defines what is displayed in the main window,
% and how the system reacts when the user interacts with the main window.
%
% Inputs:
%   fieldTrip               - struct containing field trip information.
%   sample_data             - Cell array of sample_data structs, one for
%                             each instrument.
%   autoQCRequestCallback   - Callback function called when the user attempts 
%                             to execute an automatic QC routine.
%   manualQCRequestCallback - Callback function called when the user attempts 
%                             to execute a manual QC routine.
%   exportRequestCallback   - Callback function called when the user attempts 
%                             to export data.
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
  error(nargchk(5,5,nargin));

  if ~isstruct(fieldTrip), error('fieldTrip must be a struct');       end
  if ~iscell(sample_data), error('sample_data must be a cell array'); end
  if isempty(sample_data), error('sample_data is empty');             end
  
  if ~isa(autoQCRequestCallback,   'function_handle')
    error('autoQCRequestCallback must be a function handle'); 
  end
  if ~isa(manualQCRequestCallback, 'function_handle')
    error('manualQCRequestCallback must be a function handle'); 
  end
  if ~isa(exportRequestCallback,   'function_handle')
    error('exportRequestCallback must be a function handle'); 
  end
  
  % define the user options, and create the main window
  states = {'Metadata', 'Raw data', 'Auto QC', 'Export'};
  mainWindow(fieldTrip, sample_data, states, 2, @selectCallback);
  
  function selectCallback(...
    panel, updateCallback, state, sample_data, graphType, vars, dim)
  %SELECTCALLBACK Called when the user pushes one of the 'state' buttons on
  % the main window. Populates the given panel as appropriate.
  %
  % Inputs:
  %   panel          - uipanel on which things can be drawn.
  %   updateCallback - function to be called when data is modified.
  %   state          - selected state (string).
  %   sample_data    - current sample_data struct.
  %   graphType      - currently selected graph type (string).
  %   vars           - currently selected variables (indices).
  %   dim            - currently selected dimension (index).
  %
    switch(state)

      case 'Metadata'
        viewMetadata(panel, fieldTrip, sample_data, updateCallback);
        
      case 'Raw data' 
        graphFunc = getGraph(graphType);
        graphFunc(panel, sample_data, vars, dim);

    end
  end
end