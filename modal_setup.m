function setup = modal_setup(setup_csv_file)
P = read_setup_csv(setup_csv_file);
if ~isfield(P,'iHammer')
    P.iHammer = 0*P.zHammer + 1;
end
if ~isfield(P,'iAccel')
    P.iAccel = 0*P.zAccel + 1;
end

path = fileparts(setup_csv_file);
setup.Name = filename(path);

%% Geometry
setup.nAcc = [P.axAccel;
             P.ayAccel;
             P.azAccel]';
setup.nHam = [P.FxHammer;
             P.FyHammer;
             P.FzHammer]';
setup.rHam = [P.xHammer;
             P.yHammer;
             P.zHammer]';
setup.rAcc = [P.xAccel;
             P.yAccel;
             P.zAccel]';
                 
setup.iBodyHam = P.iHammer';
setup.iBodyAcc = P.iAccel';
         
setup.nAcc = normalise(setup.nAcc,2);
setup.nHam = normalise(setup.nHam,2);
         
setup.NHam = size(setup.rHam,1);
setup.NAcc = size(setup.rAcc,1);

setup = setup_sensors(setup);

setup.modes = setup_modes(P);

%% Frequency information
if isfield(P,'fMin')
    setup.wMin = P.fMin*2*pi;
else
    setup.wMin = 0;
end

if isfield(P,'fMax')
    setup.wMax = P.fMax*2*pi;
else
    setup.wMax = Inf;
end

%% Accelerometer labels
if ~isfield(P,'AccelName')
    for k = 1:length(P.axAccel)
        if P.axAccel(k) ~= 0 && P.azAccel(k) == 0
            setup.AccName{k} = 'Horizontal';
        elseif P.ayAccel(k) ~= 0 && P.azAccel(k) == 0
            setup.AccName{k} = 'Vertical';
        elseif P.azAccel(k) ~= 0 && P.axAccel(k) == 0 && P.ayAccel(k) == 0
            setup.AccName{k} = 'Axial';
        else
            setup.AccName{k} = 'Unknown';
        end
    end
else
    setup.AccName = P.AccelName;
end

setup.options = setup_options(P);

function setup = setup_sensors(setup)
nAcc = setup.nAcc;
sAcc = ones(setup.NAcc,1);

nHam = setup.nHam;
sHam = ones(setup.NHam,1);

%flip sign if accelerometer in the negative direction
for i = 1:setup.NAcc
    dotProd = nHam * nAcc(i,:)';
    bOppositeDir = abs(dotProd + 1) < 1E-8;
    bSameLoc = all(setup.rHam == setup.rAcc(i,:),2);
    if any(bOppositeDir & bSameLoc)
        sAcc(i) = -1;
    end
end
nAcc = nAcc .* sAcc;

[sHam,nHam] = flip_sensor_sign(sHam,nHam);
[sAcc,nAcc] = flip_sensor_sign(sAcc,nAcc);

setup.sTest = sHam*sAcc';
setup.nHam = nHam;
setup.nAcc = nAcc;

function [s,n] = flip_sensor_sign(s,n)
sHamFlip = (1-2*any(n < 0,2));
s = sHamFlip .* s;
n = sHamFlip .* n;



function options = setup_options(P)
if isfield(P,'bFitBand')
    options.bFitBand = P.bFitBand;
else
    options.bFitBand = false;
end

function modes = setup_modes(P)
modes.wBand = [P.fLMode' P.fHMode']*2*pi;
modes.wEst = mean(modes.wBand,2);

modes.Nmodes = size(modes.wBand,1);

if isfield(P,'uxMode')
    modes.nMode = [P.uxMode'  P.uyMode' P.uzMode'];
    modes.nMode = normalise(modes.nMode,2);
end