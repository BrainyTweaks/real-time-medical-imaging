%% Project 259 - CIRS040GSE reconstruction

clear;
clc;
close all;

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

dataRoot = fullfile(projectRoot, ...
    "data", "raw", "CIRS040GSE", "CIRS040GSE");

headerFile = fullfile(dataRoot, ...
    "USHEADER_20220330104510.mat");

dataFile = fullfile(dataRoot, ...
    "low_attenuation", "USDATA_20220330104522673.mat");

load(headerFile, "USHEADER");
load(dataFile, "USDATA");

fprintf("Project 259 - CIRS040GSE reconstruction\n");
fprintf("---------------------------------------\n");
fprintf("System: %s\n", USHEADER.system);
fprintf("Transducer: %s\n", USHEADER.transducer);
fprintf("Sampling frequency: %.3f MHz\n", USHEADER.fs / 1e6);
fprintf("Center frequency: %.3f MHz\n", USHEADER.fc / 1e6);
fprintf("Sound speed: %.1f m/s\n", USHEADER.c);
fprintf("Element pitch: %.4f mm\n", USHEADER.pitch * 1e3);
fprintf("Number of angles: %d\n", numel(USHEADER.xmitAngles));

[numSamples, numElements, ~, numAngles] = size(USDATA);

fprintf("\nRF data size: %s\n", mat2str(size(USDATA)));
fprintf("RF data type: %s\n", class(USDATA));

rf = double(USDATA);  % Use double for the CPU reference implementation

elementX = ((0:numElements-1) - (numElements-1)/2) * USHEADER.pitch;

x = linspace(min(elementX), max(elementX), 384);

maxDepth = (numSamples - 1) / USHEADER.fs * USHEADER.c / 2;
z = linspace(0, maxDepth, 768);

[X, Z] = meshgrid(x, z);

fprintf("\nImage size: %d x %d\n", size(X, 1), size(X, 2));
fprintf("Maximum depth: %.2f mm\n", maxDepth * 1e3);

imageRF = zeros(size(X));

sampleTime = (0:numSamples-1) / USHEADER.fs;

fprintf("\nStarting beamforming...\n");

for angleIndex = 1:numAngles

    angleDeg = USHEADER.xmitAngles(angleIndex);
    angleRad = deg2rad(angleDeg);

    fprintf("Angle %d/%d: %.3f degrees\n", ...
        angleIndex, numAngles, angleDeg);

    rfAngle = rf(:, :, 1, angleIndex);

    txTime = (X .* sin(angleRad) + Z .* cos(angleRad)) ...
        / USHEADER.c;

    angleImage = zeros(size(X));

    for elementIndex = 1:numElements

        rxDistance = sqrt( ...
            (X - elementX(elementIndex)).^2 + Z.^2);

        rxTime = rxDistance / USHEADER.c;

        totalTime = txTime + rxTime;

        channelRF = rfAngle(:, elementIndex);

        receivedSignal = interp1( ...
            sampleTime, ...
            channelRF, ...
            totalTime, ...
            "linear", ...
            0);

        angleImage = angleImage + receivedSignal;

    end

    imageRF = imageRF + angleImage;

end

imageRF = imageRF / (numAngles * numElements);

analyticImage = hilbert(imageRF);
envelope = abs(analyticImage);

envelope = envelope / (max(envelope(:)) + eps);

bMode = 20 * log10(envelope + eps);

dynamicRange = 60;
bModeDisplay = max(bMode, -dynamicRange);

outputDir = fullfile(projectRoot, "data", "processed");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

figure("Name", "Project 259 - CIRS040GSE");

imagesc(x * 1e3, z * 1e3, bModeDisplay);

axis image;
colormap gray;
colorbar;
clim([-dynamicRange 0]);

xlabel("Lateral position (mm)");
ylabel("Depth (mm)");
title("CIRS040GSE Plane-Wave B-Mode Reconstruction");

outputFile = fullfile( ...
    outputDir, ...
    "cirs040_reference_reconstruction.mat");

imageFile = fullfile( ...
    outputDir, ...
    "cirs040_reference_reconstruction.png");

save(outputFile, ...
    "bMode", ...
    "imageRF", ...
    "x", ...
    "z", ...
    "USHEADER", ...
    "-v7.3");

exportgraphics(gcf, imageFile, "Resolution", 150);  % Save the displayed B-mode image

fprintf("\nReconstruction finished.\n");
fprintf("Saved data: %s\n", outputFile);
fprintf("Saved image: %s\n", imageFile);