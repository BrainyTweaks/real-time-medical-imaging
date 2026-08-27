%% Project 259 - CIRS040GSE image enhancement

clear;
clc;
close all;

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

inputFile = fullfile(projectRoot, ...
    "data", "processed", "cirs040_reference_reconstruction.mat");

outputDir = fullfile(projectRoot, ...
    "data", "processed", "enhancement");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

outputFile = fullfile(outputDir, ...
    "cirs040_enhanced.mat");

load(inputFile, "bMode", "x", "z", "USHEADER");

fprintf("Project 259 - CIRS040GSE image enhancement\n");
fprintf("------------------------------------------\n");

fprintf("Input image size: %s\n", mat2str(size(bMode)));
fprintf("Lateral range: %.2f to %.2f mm\n", ...
    min(x) * 1e3, max(x) * 1e3);
fprintf("Depth range: %.2f to %.2f mm\n", ...
    min(z) * 1e3, max(z) * 1e3);

displayRange = 60;

referenceDisplay = max(bMode, -displayRange);

fprintf("\nStarting enhancement...\n");

startTime = tic;

normalizedImage = mat2gray(referenceDisplay, ...
    [-displayRange 0]);

filteredImage = wiener2(normalizedImage, [5 5]);

enhancedImage = adapthisteq(filteredImage, ...
    "NumTiles", [8 8], ...
    "ClipLimit", 0.01);

enhancedBMode = enhancedImage * displayRange - displayRange;

enhancementTime = toc(startTime);

fprintf("Enhancement finished in %.3f seconds\n", ...
    enhancementTime);

fprintf("\nReference statistics:\n");
fprintf("  Mean: %.2f dB\n", mean(referenceDisplay(:)));
fprintf("  Std:  %.2f dB\n", std(referenceDisplay(:)));

fprintf("\nEnhanced statistics:\n");
fprintf("  Mean: %.2f dB\n", mean(enhancedBMode(:)));
fprintf("  Std:  %.2f dB\n", std(enhancedBMode(:)));

figure("Name", "Project 259 - CIRS040GSE Enhancement");

tiledlayout(1, 2);

nexttile;

imagesc(x * 1e3, z * 1e3, referenceDisplay);

axis image;
colormap gray;
clim([-displayRange 0]);

xlabel("Lateral position (mm)");
ylabel("Depth (mm)");
title("Reference B-mode");

nexttile;

imagesc(x * 1e3, z * 1e3, enhancedBMode);

axis image;
colormap gray;
clim([-displayRange 0]);

xlabel("Lateral position (mm)");
ylabel("Depth (mm)");
title("Enhanced B-mode");

saveas(gcf, fullfile(outputDir, ...
    "cirs040_enhancement_comparison.png"));

save(outputFile, ...
    "bMode", ...
    "enhancedBMode", ...
    "referenceDisplay", ...
    "x", ...
    "z", ...
    "USHEADER", ...
    "enhancementTime", ...
    "-v7.3");

fprintf("\nSaved enhanced data: %s\n", outputFile);
fprintf("Saved comparison image: %s\n", ...
    fullfile(outputDir, "cirs040_enhancement_comparison.png"));