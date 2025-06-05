%% -----------------------------------------------------------
%  Batch EEM plotter  (scatter-masked EEMs)
%  Save as EEM_plot_batch.m   and run from MATLAB.
% -------------------------------------------------------------

% 1. SETTINGS -------------------------------------------------
inFolder      = '\DEFECTS\2021_EEM_data\scatter_masked\nan';  % or ...\zero
outFolder     = fullfile(inFolder, 'PNG_plots');
intensityMode = 'auto';   % 'auto'  = 95th percentile per file
                          % 'fixed' = use intensityMax below
intensityMax  = 50;       % only used if intensityMode == 'fixed'
numLevels     = 450;      % contour density
minEx         = 250;      % wavelength trimming (nm)
minEm         = 255;
deltaT        = 0.02;     % waitbar update frequency

% -------------------------------------------------------------
if ~exist(outFolder, 'dir'); mkdir(outFolder); end
fileList = dir(fullfile(inFolder, '*.csv'));
N        = numel(fileList);
wb       = waitbar(0, 'Plotting EEMs …');

for k = 1:N
    fName  = fullfile(fileList(k).folder, fileList(k).name);
    base   = erase(fileList(k).name, '.csv');
    
    % --- read ------------------------------------------------
    M   = readmatrix(fName);                 % numeric
    ex  = M(1, 2:end);
    em  = M(2:end, 1);
    Z   = M(2:end, 2:end);
    
    % --- cut wavelength window ------------------------------
    exIdx = ex >= minEx;
    emIdx = em >= minEm;
    ex    = ex(exIdx);
    em    = em(emIdx);
    Z     = Z(emIdx, exIdx);                 % row = Em, col = Ex
    
    % --- NaN handling for plot only -------------------------
    nanMask   = isnan(Z);
    if any(nanMask, 'all')
        minVal = min(Z(~nanMask), [], 'all');
        Z(nanMask) = minVal;
    end
    
    % --- choose colour scale --------------------------------
    if strcmpi(intensityMode, 'auto')
        zMax = prctile(Z(:), 95);  % robust upper limit
    else
        zMax = intensityMax;
    end
    
    % --- contour plot ---------------------------------------
    hFig = figure('Visible','off','Units','pixels','Position',[100 100 800 600]);
    levels = linspace(0, zMax, numLevels);
    contourf(em, ex, Z.', levels, 'LineStyle','none'); % note transpose
    axis xy
    colormap(turbo); caxis([0 zMax]);
    
    xlabel('Emission wavelength (nm)'); ylabel('Excitation wavelength (nm)');
    title(strrep(base,'_','\_'), 'Interpreter','none');
    cb = colorbar; cb.Label.String = 'Intensity (R.U.)';
    
    % --- save -----------------------------------------------
    outPNG = fullfile(outFolder, [base '.png']);
    exportgraphics(hFig, outPNG, 'Resolution',300);
    close(hFig)
    
    % --- progress bar ---------------------------------------
    if mod(k, max(1,round(N*deltaT)))==0
        waitbar(k/N, wb, sprintf('Plotted %d / %d files', k, N));
    end
end

close(wb)
fprintf('✓ Plots saved to %s\n', outFolder);
