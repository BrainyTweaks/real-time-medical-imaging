%% Project 259 - CIRS040GSE GPU reconstruction

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

fprintf("Project 259 - CIRS040GSE GPU reconstruction\n");
fprintf("--------------------------------------------\n");
fprintf("GPU: %s\n", gpuDevice().Name);
fprintf("Compute capability: %s\n", gpuDevice().ComputeCapability);
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

elementX = ((0:numElements-1) - (numElements-1)/2) ...
    * USHEADER.pitch;

x = linspace(min(elementX), max(elementX), 384);
maxDepth = (numSamples - 1) / USHEADER.fs * USHEADER.c / 2;
z = linspace(0, maxDepth, 768);

[X, Z] = meshgrid(x, z);

fprintf("\nImage size: %d x %d\n", size(X, 1), size(X, 2));
fprintf("Maximum depth: %.2f mm\n", maxDepth * 1e3);

sampleTime = (0:numSamples-1) / USHEADER.fs;

fprintf("\nMoving RF data to GPU...\n");

rfGPU = gpuArray(single(USDATA));
xGPU = gpuArray(single(X));
zGPU = gpuArray(single(Z));
elementXGPU = gpuArray(single(elementX));
sampleTimeGPU = gpuArray(single(sampleTime));

imageRF = gpuArray.zeros(size(X), "single");

fprintf("Starting GPU beamforming...\n");

gpuDevice;
wait(gpuDevice);

totalTimeStart = tic;

for angleIndex = 1:numAngles

    angleDeg = USHEADER.xmitAngles(angleIndex);
    angleRad = deg2rad(angleDeg);

    fprintf("Angle %d/%d: %.3f degrees\n", ...
        angleIndex, numAngles, angleDeg);

    rfAngle = rfGPU(:, :, 1, angleIndex);

    txTime = (xGPU .* single(sin(angleRad)) ...
        + zGPU .* single(cos(angleRad))) ...
        / single(USHEADER.c);

    angleImage = gpuArray.zeros(size(X), "single");

    for elementIndex = 1:numElements

        rxDistance = sqrt( ...
            (xGPU - elementXGPU(elementIndex)).^2 ...
            + zGPU.^2);

        rxTime = rxDistance / single(USHEADER.c);

        totalTime = txTime + rxTime;

        channelRF = rfAngle(:, elementIndex);

        receivedSignal = interp1( ...
            sampleTimeGPU, ...
            channelRF, ...
            totalTime, ...
            "linear", ...
            0);

        angleImage = angleImage + receivedSignal;

    end

    imageRF = imageRF + angleImage;

end

wait(gpuDevice);

reconstructionTime = toc(totalTimeStart);

imageRF = imageRF / single(numAngles * numElements);

fprintf("\nGPU reconstruction finished.\n");
fprintf("GPU reconstruction time: %.3f seconds\n", ...
    reconstructionTime);

analyticImage = hilbert(imageRF);
envelope = abs(analyticImage);

maximumEnvelope = max(envelope(:));
envelope = envelope / (maximumEnvelope + eps("single"));

bMode = 20 * log10(envelope + eps("single"));

dynamicRange = 60;
bModeDisplay = max(bMode, -dynamicRange);

bMode = gather(bMode);
bModeDisplay = gather(bModeDisplay);
imageRF = gather(imageRF);

outputDir = fullfile(projectRoot, ...
    "data", "processed", "gpu");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

dataFile = fullfile(outputDir, ...
    "cirs040_gpu_reconstruction.mat");

imageFile = fullfile(outputDir, ...
    "cirs040_gpu_reconstruction.png");

save(dataFile, ...
    "bMode", ...
    "bModeDisplay", ...
    "imageRF", ...
    "x", ...
    "z", ...
    "USHEADER", ...
    "reconstructionTime", ...
    "-v7.3");

figure("Name", "Project 259 - CIRS040GSE GPU");

imagesc(x * 1e3, z * 1e3, bModeDisplay);

axis image;
colormap gray;
colorbar;
clim([-dynamicRange 0]);

xlabel("Lateral position (mm)");
ylabel("Depth (mm)");
title("Project 259 - CIRS040GSE GPU Reconstruction");

exportgraphics(gcf, imageFile, "Resolution", 150);

close(gcf);

fprintf("Saved GPU data: %s\n", dataFile);
fprintf("Saved GPU image: %s\n", imageFile);