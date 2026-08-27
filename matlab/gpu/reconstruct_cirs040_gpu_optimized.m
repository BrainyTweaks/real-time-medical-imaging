%% Project 259 - CIRS040GSE optimized GPU reconstruction

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

gpu = gpuDevice;

fprintf("Project 259 - CIRS040GSE optimized GPU reconstruction\n");
fprintf("-----------------------------------------------------\n");
fprintf("GPU: %s\n", gpu.Name);
fprintf("Compute capability: %s\n", gpu.ComputeCapability);
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

maxDepth = (numSamples - 1) / USHEADER.fs ...
    * USHEADER.c / 2;

z = linspace(0, maxDepth, 768);

[X, Z] = meshgrid(x, z);

fprintf("Image size: %d x %d\n", size(X, 1), size(X, 2));
fprintf("Maximum depth: %.2f mm\n", maxDepth * 1e3);

fprintf("\nMoving data to GPU...\n");

rfGPU = gpuArray(single(USDATA));
xGPU = gpuArray(single(X));
zGPU = gpuArray(single(Z));
elementXGPU = gpuArray(single(elementX));

sampleScale = single(USHEADER.fs / USHEADER.c);

imageRF = gpuArray.zeros(size(X), "single");

wait(gpuDevice);

fprintf("Starting optimized GPU beamforming...\n");

reconstructionStart = tic;

for angleIndex = 1:numAngles

    angleDeg = USHEADER.xmitAngles(angleIndex);
    angleRad = deg2rad(angleDeg);

    fprintf("Angle %d/%d: %.3f degrees\n", ...
        angleIndex, numAngles, angleDeg);

    rfAngle = rfGPU(:, :, 1, angleIndex);

    txDistance = xGPU * single(sin(angleRad)) ...
        + zGPU * single(cos(angleRad));

    txSamples = txDistance * sampleScale;

    angleImage = gpuArray.zeros(size(X), "single");

    for elementIndex = 1:numElements

        rxDistance = sqrt( ...
            (xGPU - elementXGPU(elementIndex)).^2 ...
            + zGPU.^2);

        totalDistance = txDistance + rxDistance;

        samplePosition = totalDistance * sampleScale;

        lowerIndex = floor(samplePosition) + 1;
        fraction = samplePosition - floor(samplePosition);

        valid = lowerIndex >= 1 ...
            & lowerIndex < numSamples;

        lowerIndexSafe = max( ...
            min(lowerIndex, numSamples - 1), 1);

        upperIndex = lowerIndexSafe + 1;

        channelRF = rfAngle(:, elementIndex);

        lowerValue = channelRF(lowerIndexSafe);
        upperValue = channelRF(upperIndex);

        receivedSignal = lowerValue ...
            + fraction .* (upperValue - lowerValue);

        receivedSignal(~valid) = 0;

        angleImage = angleImage + receivedSignal;

    end

    imageRF = imageRF + angleImage;

end

wait(gpuDevice);

reconstructionTime = toc(reconstructionStart);

imageRF = imageRF / single(numAngles * numElements);

fprintf("\nGPU beamforming finished.\n");
fprintf("Optimized GPU reconstruction time: %.4f seconds\n", ...
    reconstructionTime);

fprintf("\nGenerating B-mode image...\n");

processingStart = tic;

analyticImage = hilbert(imageRF);
envelope = abs(analyticImage);

envelope = envelope / ...
    (max(envelope(:)) + eps("single"));

bMode = 20 * log10(envelope + eps("single"));

wait(gpuDevice);

processingTime = toc(processingStart);

fprintf("B-mode processing time: %.4f seconds\n", ...
    processingTime);

fprintf("\nMoving result to CPU...\n");

imageRFCPU = gather(imageRF);
bModeCPU = gather(bMode);

outputDir = fullfile( ...
    projectRoot, "data", "processed", "gpu");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

outputFile = fullfile( ...
    outputDir, ...
    "cirs040_gpu_optimized_reconstruction.mat");

imageFile = fullfile( ...
    outputDir, ...
    "cirs040_gpu_optimized_reconstruction.png");

save(outputFile, ...
    "imageRFCPU", ...
    "bModeCPU", ...
    "x", ...
    "z", ...
    "USHEADER", ...
    "reconstructionTime", ...
    "processingTime", ...
    "-v7.3");

figure("Visible", "off");

imagesc( ...
    x * 1e3, ...
    z * 1e3, ...
    bModeCPU);

axis image;
colormap gray;
colorbar;
clim([-60 0]);

xlabel("Lateral position (mm)");
ylabel("Depth (mm)");
title("Project 259 - CIRS040GSE Optimized GPU Reconstruction");

exportgraphics( ...
    gcf, ...
    imageFile, ...
    "Resolution", 150);

close(gcf);

fprintf("\nOptimized GPU reconstruction finished.\n");
fprintf("Saved data: %s\n", outputFile);
fprintf("Saved image: %s\n", imageFile);