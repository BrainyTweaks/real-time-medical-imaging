%% Project 259 - CIRS040GSE GPU reconstruction profiling

clear;
clc;

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

fprintf("Project 259 - CIRS040GSE GPU profiling\n");
fprintf("--------------------------------------\n");
fprintf("GPU: %s\n", gpu.Name);
fprintf("Compute capability: %s\n", gpu.ComputeCapability);
fprintf("GPU memory: %.2f GB\n", gpu.TotalMemory / 1e9);

[numSamples, numElements, ~, numAngles] = size(USDATA);

elementX = ((0:numElements-1) - (numElements-1)/2) ...
    * USHEADER.pitch;

x = linspace(min(elementX), max(elementX), 384);

maxDepth = (numSamples - 1) / USHEADER.fs ...
    * USHEADER.c / 2;

z = linspace(0, maxDepth, 768);

[X, Z] = meshgrid(x, z);

sampleTime = (0:numSamples-1) / USHEADER.fs;

fprintf("\nRF data size: %s\n", mat2str(size(USDATA)));
fprintf("Image size: %s\n", mat2str(size(X)));
fprintf("Number of elements: %d\n", numElements);
fprintf("Number of angles: %d\n", numAngles);

fprintf("\nPreparing GPU data...\n");

wait(gpuDevice);

transferStart = tic;

rfGPU = gpuArray(single(USDATA));
xGPU = gpuArray(single(X));
zGPU = gpuArray(single(Z));
elementXGPU = gpuArray(single(elementX));
sampleTimeGPU = gpuArray(single(sampleTime));

wait(gpuDevice);

transferTime = toc(transferStart);

fprintf("CPU -> GPU transfer: %.4f seconds\n", transferTime);

fprintf("\nStarting profiled reconstruction...\n");

wait(gpuDevice);

totalStart = tic;

imageRF = gpuArray.zeros(size(X), "single");

angleTimes = zeros(numAngles, 1);
interpolationTimes = zeros(numAngles, 1);
accumulationTimes = zeros(numAngles, 1);

for angleIndex = 1:numAngles

    angleStart = tic;

    angleDeg = USHEADER.xmitAngles(angleIndex);
    angleRad = deg2rad(angleDeg);

    rfAngle = rfGPU(:, :, 1, angleIndex);

    txTime = (xGPU .* single(sin(angleRad)) ...
        + zGPU .* single(cos(angleRad))) ...
        / single(USHEADER.c);

    angleImage = gpuArray.zeros(size(X), "single");

    wait(gpuDevice);

    interpolationStart = tic;

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

    wait(gpuDevice);

    interpolationTimes(angleIndex) = toc(interpolationStart);

    accumulationStart = tic;

    imageRF = imageRF + angleImage;

    wait(gpuDevice);

    accumulationTimes(angleIndex) = toc(accumulationStart);

    angleTimes(angleIndex) = toc(angleStart);

    if mod(angleIndex, 10) == 0 || angleIndex == 1

        fprintf("Angle %d/%d: %.3f s\n", ...
            angleIndex, numAngles, angleTimes(angleIndex));

    end

end

wait(gpuDevice);

beamformingTime = toc(totalStart);

fprintf("\nBeamforming complete.\n");
fprintf("Beamforming time: %.4f seconds\n", beamformingTime);

normalizationStart = tic;

imageRF = imageRF / single(numAngles * numElements);

wait(gpuDevice);

normalizationTime = toc(normalizationStart);

fprintf("Normalization time: %.4f seconds\n", ...
    normalizationTime);

fprintf("\nProfiling image processing...\n");

wait(gpuDevice);

processingStart = tic;

analyticImage = hilbert(imageRF);
envelope = abs(analyticImage);

envelope = envelope / ...
    (max(envelope(:)) + eps("single"));

bMode = 20 * log10(envelope + eps("single"));

wait(gpuDevice);

processingTime = toc(processingStart);

fprintf("Hilbert/envelope/B-mode time: %.4f seconds\n", ...
    processingTime);

wait(gpuDevice);

downloadStart = tic;

imageRFCPU = gather(imageRF);
bModeCPU = gather(bMode);

downloadTime = toc(downloadStart);

fprintf("GPU -> CPU transfer: %.4f seconds\n", ...
    downloadTime);

totalTime = beamformingTime ...
    + normalizationTime ...
    + processingTime ...
    + downloadTime;

fprintf("\nGPU profiling results\n");
fprintf("---------------------\n");
fprintf("CPU -> GPU transfer:       %.4f s\n", transferTime);
fprintf("Beamforming:               %.4f s\n", beamformingTime);
fprintf("Normalization:             %.4f s\n", normalizationTime);
fprintf("B-mode processing:         %.4f s\n", processingTime);
fprintf("GPU -> CPU transfer:       %.4f s\n", downloadTime);
fprintf("Measured total:            %.4f s\n", totalTime);
fprintf("Effective throughput:      %.2f FPS\n", 1 / totalTime);

fprintf("\nBeamforming breakdown\n");
fprintf("---------------------\n");
fprintf("Mean angle time:           %.4f s\n", mean(angleTimes));
fprintf("Mean interpolation time:   %.4f s\n", mean(interpolationTimes));
fprintf("Mean accumulation time:    %.4f s\n", mean(accumulationTimes));

outputDir = fullfile( ...
    projectRoot, "data", "processed", "benchmark");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

outputFile = fullfile( ...
    outputDir, ...
    "cirs040_gpu_profile.mat");

save(outputFile, ...
    "transferTime", ...
    "beamformingTime", ...
    "normalizationTime", ...
    "processingTime", ...
    "downloadTime", ...
    "totalTime", ...
    "angleTimes", ...
    "interpolationTimes", ...
    "accumulationTimes", ...
    "imageRFCPU", ...
    "bModeCPU", ...
    "USHEADER", ...
    "-v7.3");

fprintf("\nSaved profiling data: %s\n", outputFile);
fprintf("GPU profiling finished.\n");