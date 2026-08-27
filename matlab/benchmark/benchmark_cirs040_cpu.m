%% Project 259 - CIRS040GSE CPU benchmark

clear;
clc;
close all;

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

inputFile = fullfile(projectRoot, ...
    "data", "processed", ...
    "cirs040_reference_reconstruction.mat");

outputDir = fullfile(projectRoot, ...
    "data", "processed", ...
    "benchmark");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

outputFile = fullfile(outputDir, ...
    "cirs040_cpu_benchmark.mat");

load(inputFile, "bMode", "x", "z", "USHEADER");

fprintf("Project 259 - CIRS040GSE CPU benchmark\n");
fprintf("--------------------------------------\n");
fprintf("Image size: %d x %d\n", size(bMode, 1), size(bMode, 2));

displayRange = 60;
numRuns = 10;

referenceDisplay = max(bMode, -displayRange);
normalizedImage = mat2gray(referenceDisplay, ...
    [-displayRange 0]);

fprintf("Benchmark runs: %d\n", numRuns);

fprintf("\nWarming up MATLAB image processing...\n");

wiener2(normalizedImage, [5 5]);
adapthisteq(normalizedImage, ...
    "NumTiles", [8 8], ...
    "ClipLimit", 0.01);

fprintf("Warm-up complete.\n");

runTimes = zeros(numRuns, 1);

fprintf("\nStarting CPU benchmark...\n");

for runIndex = 1:numRuns

    startTime = tic;

    filteredImage = wiener2(normalizedImage, [5 5]);

    enhancedImage = adapthisteq(filteredImage, ...
        "NumTiles", [8 8], ...
        "ClipLimit", 0.01);

    runTimes(runIndex) = toc(startTime);

    fprintf("Run %d/%d: %.4f seconds\n", ...
        runIndex, numRuns, runTimes(runIndex));

end

meanTime = mean(runTimes);
medianTime = median(runTimes);
minimumTime = min(runTimes);
maximumTime = max(runTimes);

meanFPS = 1 / meanTime;
frameBudget = 1 / 30;

fprintf("\nCPU benchmark results\n");
fprintf("---------------------\n");
fprintf("Mean latency:    %.4f seconds\n", meanTime);
fprintf("Median latency:  %.4f seconds\n", medianTime);
fprintf("Minimum latency: %.4f seconds\n", minimumTime);
fprintf("Maximum latency: %.4f seconds\n", maximumTime);
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
    "x", ...
    "z", ...
    "USHEADER", ...
    "-v7.3");

fprintf("\nSaved benchmark: %s\n", outputFile);