%% Project 259 - CPU/GPU reconstruction comparison

clear;
clc;
close all;

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

cpuFile = fullfile(projectRoot, ...
    "data", "processed", ...
    "cirs040_reference_reconstruction.mat");

gpuFile = fullfile(projectRoot, ...
    "data", "processed", "gpu", ...
    "cirs040_gpu_reconstruction.mat");

fprintf("Project 259 - CIRS040GSE CPU/GPU comparison\n");
fprintf("-------------------------------------------\n");

if ~isfile(cpuFile)
    error("CPU reconstruction file was not found: %s", cpuFile);
end

if ~isfile(gpuFile)
    error("GPU reconstruction file was not found: %s", gpuFile);
end

cpuData = load(cpuFile);
gpuData = load(gpuFile);

cpuRF = double(cpuData.imageRF);
gpuRF = double(gpuData.imageRF);

fprintf("CPU RF image size: %s\n", mat2str(size(cpuRF)));
fprintf("GPU RF image size: %s\n", mat2str(size(gpuRF)));

if ~isequal(size(cpuRF), size(gpuRF))
    error("CPU and GPU reconstruction sizes do not match.");
end

difference = gpuRF - cpuRF;

absoluteDifference = abs(difference);

maxAbsoluteError = max(absoluteDifference(:));
meanAbsoluteError = mean(absoluteDifference(:));

cpuNorm = norm(cpuRF(:));
differenceNorm = norm(difference(:));

relativeError = differenceNorm / (cpuNorm + eps);

cpuVector = cpuRF(:);
gpuVector = gpuRF(:);

correlationMatrix = corrcoef(cpuVector, gpuVector);
correlation = correlationMatrix(1, 2);

fprintf("\nComparison results\n");
fprintf("------------------\n");
fprintf("Maximum absolute error: %.6e\n", maxAbsoluteError);
fprintf("Mean absolute error:    %.6e\n", meanAbsoluteError);
fprintf("Relative L2 error:      %.6e\n", relativeError);
fprintf("Correlation coefficient: %.9f\n", correlation);

if isfield(cpuData, "bMode") && isfield(gpuData, "bMode")

    cpuBMode = double(cpuData.bMode);
    gpuBMode = double(gpuData.bMode);

    bModeDifference = gpuBMode - cpuBMode;

    fprintf("\nB-mode comparison\n");
    fprintf("-----------------\n");
    fprintf("Maximum absolute error: %.6e dB\n", ...
        max(abs(bModeDifference(:))));
    fprintf("Mean absolute error:    %.6e dB\n", ...
        mean(abs(bModeDifference(:))));

end

outputDir = fullfile( ...
    projectRoot, "data", "processed", "validation");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

comparisonFile = fullfile( ...
    outputDir, "cirs040_cpu_gpu_comparison.mat");

save(comparisonFile, ...
    "maxAbsoluteError", ...
    "meanAbsoluteError", ...
    "relativeError", ...
    "correlation", ...
    "difference", ...
    "-v7.3");

figure("Visible", "off");

imagesc( ...
    cpuData.x * 1e3, ...
    cpuData.z * 1e3, ...
    difference);

axis image;
colormap gray;
colorbar;

xlabel("Lateral position (mm)");
ylabel("Depth (mm)");
title("Project 259 - CPU/GPU Reconstruction Difference");

differenceImage = fullfile( ...
    outputDir, "cirs040_cpu_gpu_difference.png");

exportgraphics( ...
    gcf, differenceImage, ...
    "Resolution", 150);

close(gcf);

fprintf("\nSaved comparison data: %s\n", comparisonFile);
fprintf("Saved difference image: %s\n", differenceImage);

fprintf("\nCPU/GPU comparison finished.\n");