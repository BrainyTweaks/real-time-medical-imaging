%% Project 259 - CIRS040GSE CPU reconstruction benchmark

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

outputDir = fullfile(projectRoot, ...
    "data", "processed", "benchmark");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

outputFile = fullfile(outputDir, ...
    "cirs040_reconstruction_cpu_benchmark.mat");

load(headerFile, "USHEADER");
load(dataFile, "USDATA");

fprintf("Project 259 - CIRS040GSE CPU reconstruction benchmark\n");
fprintf("-----------------------------------------------------\n");
fprintf("System: %s\n", USHEADER.system);
fprintf("Transducer: %s\n", USHEADER.transducer);
fprintf("Sampling frequency: %.3f MHz\n", USHEADER.fs / 1e6);
fprintf("Center frequency: %.3f MHz\n", USHEADER.fc / 1e6);
fprintf("Sound speed: %.1f m/s\n", USHEADER.c);
fprintf("Element pitch: %.4f mm\n", USHEADER.pitch * 1e3);

[numSamples, numElements, ~, numAngles] = size(USDATA);

fprintf("\nRF data size: %s\n", mat2str(size(USDATA)));
fprintf("RF data type: %s\n", class(USDATA));

rf = double(USDATA);

elementX = ((0:numElements - 1) - ...
    (numElements - 1) / 2) * USHEADER.pitch;

x = linspace( ...
    min(elementX), ...
    max(elementX), ...
    384);

maxDepth = (numSamples - 1) / USHEADER.fs * ...
    USHEADER.c / 2;

z = linspace(0, maxDepth, 768);

[X, Z] = meshgrid(x, z);

fprintf("Image size: %d x %d\n", size(X, 1), size(X, 2));
fprintf("Maximum depth: %.2f mm\n", maxDepth * 1e3);

sampleTime = (0:numSamples - 1) / USHEADER.fs;

numRuns = 3;

fprintf("\nBenchmark runs: %d\n", numRuns);
fprintf("Starting CPU reconstruction benchmark...\n");

runTimes = zeros(numRuns, 1);

for runIndex = 1:numRuns

    fprintf("\nRun %d/%d\n", runIndex, numRuns);

    startTime = tic;

    imageRF = zeros(size(X));

    for angleIndex = 1:numAngles

        angleDeg = USHEADER.xmitAngles(angleIndex);
        angleRad = deg2rad(angleDeg);

        rfAngle = rf(:, :, 1, angleIndex);

        txTime = (X .* sin(angleRad) + ...
            Z .* cos(angleRad)) / USHEADER.c;

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

    envelope = envelope / ...
        (max(envelope(:)) + eps);

    bMode = 20 * log10(envelope + eps);

    runTimes(runIndex) = toc(startTime);

    fprintf("Reconstruction time: %.3f seconds\n", ...
        runTimes(runIndex));

end

meanTime = mean(runTimes);
medianTime = median(runTimes);
minimumTime = min(runTimes);
maximumTime = max(runTimes);

meanFPS = 1 / meanTime;
frameBudget = 1 / 30;

fprintf("\nCPU reconstruction benchmark results\n");
fprintf("------------------------------------\n");
fprintf("Mean latency:    %.3f seconds\n", meanTime);
fprintf("Median latency:  %.3f seconds\n", medianTime);
fprintf("Minimum latency: %.3f seconds\n", minimumTime);
fprintf("Maximum latency: %.3f seconds\n", maximumTime);
fprintf("Throughput:      %.2f FPS\n", meanFPS);
fprintf("30 FPS budget:   %.4f seconds\n", frameBudget);

if meanTime <= frameBudget
    fprintf("30 FPS target:   PASS\n");
else
    fprintf("30 FPS target:   FAIL\n");
end

save(outputFile, ...
    "runTimes", ...
    "meanTime", ...
    "medianTime", ...
    "minimumTime", ...
    "maximumTime", ...
    "meanFPS", ...
    "frameBudget", ...
    "bMode", ...
    "imageRF", ...
    "x", ...
    "z", ...
    "USHEADER", ...
    "-v7.3");

fprintf("\nSaved benchmark: %s\n", outputFile);