%% Project 259 - CIRS040GSE GPU reconstruction benchmark

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

fprintf("Project 259 - CIRS040GSE GPU reconstruction benchmark\n");
fprintf("-----------------------------------------------------\n");
fprintf("GPU: %s\n", gpu.Name);
fprintf("Compute capability: %s\n", gpu.ComputeCapability);
fprintf("GPU memory: %.2f GB\n", gpu.TotalMemory / 1e9);
fprintf("System: %s\n", USHEADER.system);
fprintf("Transducer: %s\n", USHEADER.transducer);
fprintf("Sampling frequency: %.3f MHz\n", USHEADER.fs / 1e6);
fprintf("Center frequency: %.3f MHz\n", USHEADER.fc / 1e6);
fprintf("Sound speed: %.1f m/s\n", USHEADER.c);
fprintf("Element pitch: %.4f mm\n", USHEADER.pitch * 1e3);

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

sampleTime = (0:numSamples-1) / USHEADER.fs;

rfGPU = gpuArray(single(USDATA));
xGPU = gpuArray(single(X));
zGPU = gpuArray(single(Z));
elementXGPU = gpuArray(single(elementX));
sampleTimeGPU = gpuArray(single(sampleTime));

fprintf("\nRF data moved to GPU.\n");

numRuns = 3;

fprintf("Benchmark runs: %d\n", numRuns);
fprintf("Starting GPU reconstruction benchmark...\n");

runTimes = zeros(numRuns, 1);

for runIndex = 1:numRuns

    fprintf("\nRun %d/%d\n", runIndex, numRuns);

    wait(gpuDevice);

    startTime = tic;

    imageRF = gpuArray.zeros(size(X), "single");

    for angleIndex = 1:numAngles

        angleDeg = USHEADER.xmitAngles(angleIndex);
        angleRad = deg2rad(angleDeg);

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

    imageRF = imageRF / single(numAngles * numElements);

    wait(gpuDevice);

    runTimes(runIndex) = toc(startTime);

    fprintf("Reconstruction time: %.3f seconds\n", ...
        runTimes(runIndex));

end

meanLatency = mean(runTimes);
medianLatency = median(runTimes);
minimumLatency = min(runTimes);
maximumLatency = max(runTimes);

throughput = 1 / meanLatency;

frameBudget = 1 / 30;

cpuLatency = 69.664;
speedup = cpuLatency / meanLatency;

fprintf("\nGPU reconstruction benchmark results\n");
fprintf("------------------------------------\n");
fprintf("Mean latency:    %.4f seconds\n", meanLatency);
fprintf("Median latency:  %.4f seconds\n", medianLatency);
fprintf("Minimum latency: %.4f seconds\n", minimumLatency);
fprintf("Maximum latency: %.4f seconds\n", maximumLatency);
fprintf("Throughput:      %.2f FPS\n", throughput);
fprintf("CPU reference:   %.4f seconds\n", cpuLatency);
fprintf("GPU speedup:     %.2fx\n", speedup);
fprintf("30 FPS budget:   %.4f seconds\n", frameBudget);

if meanLatency <= frameBudget
    fprintf("30 FPS target:   PASS\n");
else
    fprintf("30 FPS target:   FAIL\n");
end

outputDir = fullfile( ...
    projectRoot, "data", "processed", "benchmark");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

outputFile = fullfile( ...
    outputDir, ...
    "cirs040_reconstruction_gpu_benchmark.mat");

save(outputFile, ...
    "runTimes", ...
    "meanLatency", ...
    "medianLatency", ...
    "minimumLatency", ...
    "maximumLatency", ...
    "throughput", ...
    "frameBudget", ...
    "cpuLatency", ...
    "speedup", ...
    "USHEADER", ...
    "-v7.3");

fprintf("\nSaved benchmark: %s\n", outputFile);