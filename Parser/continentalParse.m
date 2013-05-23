 function sample_data = continentalParse( filename, mode )
%CONTINENTALPARSE Parses ADCP data from a raw Nortek Continental binary
% (.cpr) file.
%
% Parses a raw binary file from a Nortek Continental ADCP.
%
% Inputs:
%   filename    - Cell array containing the name of the raw continental file 
%                 to parse.
%   mode        - Toolbox data type mode ('profile' or 'timeSeries').
% 
% Outputs:
%   sample_data - Struct containing sample data.
%
% Author: 		Paul McCarthy <paul.mccarthy@csiro.au>
% Contributor: 	Guillaume Galibert <guillaume.galibert@utas.edu.au>
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
error(nargchk(1,2,nargin));

if ~iscellstr(filename), error('filename must be a cell array of strings'); end

% only one file supported
filename = filename{1};

% read in all of the structures in the raw file
structures = readParadoppBinary(filename);

% first three sections are header, head and user configuration
hardware = structures{1};
head     = structures{2};
user     = structures{3};

% the rest of the sections are continental data (which have 
% the same structure as awac velocity profile data sections).

nsamples = length(structures) - 3;
ncells   = user.NBins;

% preallocate memory for all sample data
time         = zeros(nsamples, 1);
distance        = zeros(ncells,   1);
analn1       = zeros(nsamples, 1);
battery      = zeros(nsamples, 1);
analn2       = zeros(nsamples, 1);
heading      = zeros(nsamples, 1);
pitch        = zeros(nsamples, 1);
roll         = zeros(nsamples, 1);
pressure     = zeros(nsamples, 1);
temperature  = zeros(nsamples, 1);
velocity1    = zeros(nsamples, ncells);
velocity2    = zeros(nsamples, ncells);
velocity3    = zeros(nsamples, ncells);
backscatter1 = zeros(nsamples, ncells);
backscatter2 = zeros(nsamples, ncells);
backscatter3 = zeros(nsamples, ncells);

%
% calculate distance values from metadata. Conversion of the BinLength 
% and T2 (blanking distance) values from counts to meaningful values 
% is a little strange. The relationship between frequency and the 
% 'factor', as i've termed it, is approximately:
%
% factor = 47.8 / frequency
%
% However this is not exactly correct for all frequencies, so i'm 
% just using a lookup table as recommended in this forum post:
% 
% http://www.nortek-as.com/en/knowledge-center/forum/hr-profilers/736804717
%
% Calculation of blanking distance always uses the constant value 0.0229
% (except for HR profilers - also explained in the forum post).
%
freq       = head.Frequency; % this is in KHz
cellStart  = user.T2;        % counts
cellLength = user.BinLength; % counts
factor     = 0;              % used for conversion

switch freq
  case 190, factor = 0.2221;
  case 470, factor = 0.0945;
end

cellLength = (cellLength / 256) * factor * cos(25 * pi / 180);
cellStart  =  cellStart         * 0.0229 * cos(25 * pi / 180) - cellLength;

% generate distance values
distance(:) = (cellStart):  ...
           (cellLength): ...
           (cellStart + (ncells-1) * cellLength);

% Note this is actually the distance between the ADCP's transducers and the
% middle of each cell
% See http://www.nortek-bv.nl/en/knowledge-center/forum/current-profilers-and-current-meters/579860330
distance = distance + cellLength;

% retrieve sample data
for k = 1:nsamples
  
  st = structures{k+3};
  
  time(k)           = st.Time;
  analn1(k)         = st.Analn1;
  battery(k)        = st.Battery;
  analn2(k)         = st.Analn2;
  heading(k)        = st.Heading;
  pitch(k)          = st.Pitch;
  roll(k)           = st.Roll;
  pressure(k)       = st.PressureMSB*65536 + st.PressureLSW;
  temperature(k)    = st.Temperature;
  velocity1(k,:)    = st.Vel1;
  velocity2(k,:)    = st.Vel2;
  velocity3(k,:)    = st.Vel3;
  backscatter1(k,:) = st.Amp1;
  backscatter2(k,:) = st.Amp2;
  backscatter3(k,:) = st.Amp3;
end

% battery     / 10.0   (0.1 V    -> V)
% heading     / 10.0   (0.1 deg  -> deg)
% pitch       / 10.0   (0.1 deg  -> deg)
% roll        / 10.0   (0.1 deg  -> deg)
% pressure    / 1000.0 (mm       -> m)   assuming equivalence to dbar
% temperature / 100.0  (0.01 deg -> deg)
% velocities  / 1000.0 (mm/s     -> m/s) assuming earth coordinates
% backscatter * 0.45   (counts   -> dB)  see http://www.nortek-as.com/lib/technical-notes/seditments
battery      = battery      / 10.0;
heading      = heading      / 10.0;
pitch        = pitch        / 10.0;
roll         = roll         / 10.0;
pressure     = pressure     / 1000.0;
temperature  = temperature  / 100.0;
velocity1    = velocity1    / 1000.0;
velocity2    = velocity2    / 1000.0;
velocity3    = velocity3    / 1000.0;
backscatter1 = backscatter1 * 0.45;
backscatter2 = backscatter2 * 0.45;
backscatter3 = backscatter3 * 0.45;

sample_data = struct;

sample_data.toolbox_input_file              = filename;
sample_data.meta.head                       = head;
sample_data.meta.hardware                   = hardware;
sample_data.meta.user                       = user;
sample_data.meta.binSize                    = cellLength;
sample_data.meta.instrument_make            = 'Nortek';
sample_data.meta.instrument_model           = 'Continental';
sample_data.meta.instrument_serial_no       = hardware.SerialNo;
sample_data.meta.instrument_sample_interval = median(diff(time*24*3600));
sample_data.meta.instrument_firmware        = hardware.FWversion;
sample_data.meta.beam_angle                 = 25;   % http://www.hydro-international.com/files/productsurvey_v_pdfdocument_19.pdf

sample_data.dimensions{1} .name = 'TIME';
sample_data.dimensions{2} .name = 'HEIGHT_ABOVE_SENSOR';
sample_data.dimensions{3} .name = 'LATITUDE';
sample_data.dimensions{4} .name = 'LONGITUDE';

sample_data.dimensions{1}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.dimensions{1}.name, 'type')));
sample_data.dimensions{2}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.dimensions{2}.name, 'type')));
sample_data.dimensions{3}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.dimensions{3}.name, 'type')));
sample_data.dimensions{4}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.dimensions{4}.name, 'type')));

sample_data.variables {1} .name = 'VCUR';
sample_data.variables {2} .name = 'UCUR';
sample_data.variables {3} .name = 'WCUR';
sample_data.variables {4} .name = 'ABSI1';
sample_data.variables {5} .name = 'ABSI2';
sample_data.variables {6} .name = 'ABSI3';
sample_data.variables {7} .name = 'TEMP';
sample_data.variables {8} .name = 'PRES_REL';
sample_data.variables {9} .name = 'VOLT';
sample_data.variables {10}.name = 'PITCH';
sample_data.variables {11}.name = 'ROLL';
sample_data.variables {12}.name = 'HEADING';

sample_data.variables{1}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{1}.name, 'type')));
sample_data.variables{2}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{2}.name, 'type')));
sample_data.variables{3}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{3}.name, 'type')));
sample_data.variables{4}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{4}.name, 'type')));
sample_data.variables{5}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{5}.name, 'type')));
sample_data.variables{6}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{6}.name, 'type')));
sample_data.variables{7}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{7}.name, 'type')));
sample_data.variables{8}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{8}.name, 'type')));
sample_data.variables{9}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{9}.name, 'type')));
sample_data.variables{10}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{10}.name, 'type')));
sample_data.variables{11}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{11}.name, 'type')));
sample_data.variables{12}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{12}.name, 'type')));

sample_data.variables {1} .dimensions = [1 2 3 4];
sample_data.variables {2} .dimensions = [1 2 3 4];
sample_data.variables {3} .dimensions = [1 2 3 4];
sample_data.variables {4} .dimensions = [1 2 3 4];
sample_data.variables {5} .dimensions = [1 2 3 4];
sample_data.variables {6} .dimensions = [1 2 3 4];
sample_data.variables {7} .dimensions = [1 3 4];
sample_data.variables {8} .dimensions = [1 3 4];
sample_data.variables {9} .dimensions = [1 3 4];
sample_data.variables {10}.dimensions = [1 3 4];
sample_data.variables {11}.dimensions = [1 3 4];
sample_data.variables {12}.dimensions = [1 3 4];

sample_data.dimensions{1} .data = sample_data.dimensions{1}.typeCastFunc(time);
sample_data.dimensions{2} .data = sample_data.dimensions{2}.typeCastFunc(distance);
sample_data.dimensions{3} .data = sample_data.dimensions{3}.typeCastFunc(NaN);
sample_data.dimensions{4} .data = sample_data.dimensions{4}.typeCastFunc(NaN);
  
sample_data.variables {1} .data = sample_data.variables{1}.typeCastFunc(velocity2); % V
sample_data.variables {2} .data = sample_data.variables{2}.typeCastFunc(velocity1); % U
sample_data.variables {3} .data = sample_data.variables{3}.typeCastFunc(velocity3);
sample_data.variables {4} .data = sample_data.variables{4}.typeCastFunc(backscatter1);
sample_data.variables {5} .data = sample_data.variables{5}.typeCastFunc(backscatter2);
sample_data.variables {6} .data = sample_data.variables{6}.typeCastFunc(backscatter3);
sample_data.variables {7} .data = sample_data.variables{7}.typeCastFunc(temperature);
sample_data.variables {8} .data = sample_data.variables{8}.typeCastFunc(pressure);
sample_data.variables {9} .data = sample_data.variables{9}.typeCastFunc(battery);
sample_data.variables {10}.data = sample_data.variables{10}.typeCastFunc(pitch);
sample_data.variables {11}.data = sample_data.variables{11}.typeCastFunc(roll);
sample_data.variables {12}.data = sample_data.variables{12}.typeCastFunc(heading);
