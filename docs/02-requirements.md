# Project Requirements

## 1. Purpose

This document defines what Project 259 needs to deliver.

The project is not just an ultrasound image-processing demo. The final system needs to show the path from raw ultrasound data through image reconstruction, enhancement, AI processing, GPU acceleration, and Holoscan deployment.

The requirements below are based on the current project scope and the environment already validated.

---

## 2. Functional Requirements

### FR-01 — Raw Data Input

The system shall accept data representing raw ultrasound acquisition data before image reconstruction.

The initial input may be:

* pre-recorded RF/channel data
* simulated RF/channel data

Real ADC input is optional for the core implementation.

The input format must be documented, including:

* number of channels
* number of samples
* sample rate
* data type
* frame/block definition
* relevant acquisition parameters

---

### FR-02 — Image Reconstruction

The system shall convert the raw input data into a 2-D ultrasound image.

The reconstruction algorithm must be implemented and validated in MATLAB before being used as the accelerated/deployment version.

The reconstruction method is not fixed yet. The final choice will depend on the selected dataset and the available acquisition information.

Beamforming is expected to be the main reconstruction approach.

---

### FR-03 — Image Enhancement

The system shall provide an image-enhancement stage after reconstruction.

The enhancement stage may include operations such as:

* noise/speckle reduction
* contrast enhancement
* edge-preserving filtering

The final processing chain will be selected after testing it on the reconstructed data.

The selected method must be evaluated for both image quality and execution time.

---

### FR-04 — AI Processing

The system shall include an AI inference stage.

The AI task must be clearly defined before the final model is selected.

Possible tasks include:

* classification
* detection
* segmentation

The initial implementation should favor a model that is practical to run in a real-time pipeline rather than selecting a large model only because it gives better offline accuracy.

---

### FR-05 — AI Dataset

The AI model shall use a documented dataset with appropriate labels or ground truth for the selected task.

The dataset must be split into appropriate training, validation, and test sets.

The final dataset has not been fixed yet.

BUSI and other suitable ultrasound datasets can be evaluated, but the final choice must be based on whether the dataset matches the actual AI task.

---

### FR-06 — MATLAB Reference Implementation

MATLAB shall be used as the reference environment for algorithm development and validation.

The MATLAB implementation must be kept as the reference against which accelerated implementations can be compared.

At minimum, the reference implementation should allow:

1. Loading the input data.
2. Running reconstruction.
3. Running enhancement.
4. Running AI preprocessing/inference where applicable.
5. Saving or displaying the resulting output.

---

### FR-07 — GPU Acceleration

The computationally expensive parts of the pipeline shall be evaluated for GPU acceleration.

GPU acceleration shall be based on profiling rather than automatically moving every operation to the GPU.

MATLAB GPU Coder shall be investigated for suitable processing stages.

The generated implementation must be compared against the MATLAB reference implementation.

---

### FR-08 — CUDA Implementation

Where MATLAB GPU Coder is suitable, the project shall generate CUDA-based implementation for the selected processing stage.

The generated code must be tested independently before being integrated into the final streaming application.

Numerical and visual differences between the MATLAB and CUDA implementations shall be checked.

---

### FR-09 — Holoscan Application

The final system shall run as an NVIDIA Holoscan application.

The Holoscan application shall contain a streaming data path connecting the major processing stages.

The intended structure is:

**Input → Reconstruction → Enhancement → AI → Visualization**

Additional operators may be added where required for:

* buffering
* format conversion
* synchronization
* timing
* GPU memory handling
* performance measurement

---

### FR-10 — Replaceable Data Source

The processing pipeline shall not depend permanently on one input method.

The architecture should allow the input source to be replaced without rewriting the downstream processing stages.

The expected progression is:

**Simulated Data → Recorded Data → Real ADC Data**

Real ADI ADC integration is an extension of the core implementation and is not required before the software pipeline is working.

---

### FR-11 — Visualization

The final application shall provide a visible output showing the result of the processing pipeline.

The visualization should make it possible to observe:

* reconstructed image
* enhanced image or final processed image
* AI result

Where appropriate, the AI result should be overlaid on the ultrasound image.

Holoviz/Holoscan visualization can be used for the final application.

---

### FR-12 — Single Main Entry Point

The final repository shall provide one clear main entry point for running the complete system.

The user should not have to manually start reconstruction, enhancement, AI inference, and visualization as separate applications.

The exact implementation will depend on the final Holoscan application structure.

---

## 3. Performance Requirements

### PR-01 — Performance Measurement

Performance shall be measured instead of being described only as "real-time."

The measurements shall include, where applicable:

* reconstruction time
* enhancement time
* AI inference time
* total pipeline latency
* throughput
* FPS

---

### PR-02 — CPU Baseline

A CPU/reference baseline shall be established before claiming GPU acceleration.

The same input and processing configuration should be used when comparing CPU and GPU implementations.

---

### PR-03 — GPU Performance

The GPU implementation shall be benchmarked against the reference implementation.

At minimum, the project should report:

**Speedup = CPU execution time / GPU execution time**

The actual measured value will be reported after testing.

No performance number should be claimed beforehand.

---

### PR-04 — Sustained Processing

The final pipeline shall be tested over multiple frames.

A single successfully processed frame is not sufficient to demonstrate streaming performance.

The system should be checked for:

* processing stability
* throughput
* latency variation
* queue buildup
* dropped frames where applicable

---

### PR-05 — Real-Time Target

A target processing rate shall be defined once the dataset and frame structure are fixed.

For example, a 30 FPS target would require approximately 33.3 ms per incoming frame.

The final target must be based on the actual system configuration rather than chosen only to make the results look good.

---

## 4. Accuracy and Validation Requirements

### VR-01 — Reconstruction Validation

The reconstruction output must be checked using representative input data.

The validation should confirm that:

* the output has the expected dimensions
* the image contains meaningful reconstructed information
* the spatial interpretation is correct
* the result is stable across multiple frames

---

### VR-02 — Enhancement Validation

The enhancement stage shall be compared against the unprocessed reconstruction.

The comparison should consider:

* visibility of structures
* contrast
* noise/speckle characteristics
* edge preservation
* processing time

---

### VR-03 — AI Validation

The AI model shall be evaluated using metrics appropriate to the selected task.

Examples:

**Classification**

* accuracy
* precision
* recall
* F1-score
* confusion matrix

**Detection**

* precision
* recall
* IoU
* appropriate detection metrics

**Segmentation**

* Dice score
* IoU
* precision
* recall

Only metrics relevant to the final selected task need to be reported.

---

### VR-04 — MATLAB/GPU Validation

The accelerated implementation shall be compared with the MATLAB reference.

The comparison should include numerical results where appropriate and visual comparison for imaging stages.

Small floating-point differences are acceptable if they do not materially change the output.

---

### VR-05 — End-to-End Validation

The final system shall be tested as one pipeline:

**Input → Reconstruction → Enhancement → AI → Output**

Testing must not rely only on individually successful components.

---

## 5. Environment Requirements

The following environment has already been validated and should be treated as the current baseline.

### Host

* Windows 11 Home Single Language
* x86_64
* NVIDIA GeForce RTX 3050 Laptop GPU
* 4 GB dedicated GPU memory
* NVIDIA driver 592.82

### MATLAB

* MATLAB R2025b
* Version 25.2
* Simulink R2025b
* Parallel Computing Toolbox
* GPU-related MATLAB tooling required for the project

MATLAB GPU access has already been tested using `gpuArray`.

---

### WSL2

* WSL2
* Ubuntu 24.04.4 LTS
* x86_64
* WSL2 kernel 6.6.87.2

GPU access from Ubuntu has already been verified using `nvidia-smi`.

---

### Docker

* Docker Engine 29.7.2
* Docker Compose 5.4.0
* `desktop-linux` context
* Linux containers
* NVIDIA GPU runtime

Docker GPU passthrough has already been tested successfully.

---

### CUDA Container

The following container has already been tested:

`nvidia/cuda:12.6.2-base-ubuntu24.04`

The container successfully detected the RTX 3050 through `nvidia-smi`.

---

### NVIDIA Holoscan

The currently validated Holoscan image is:

`nvcr.io/nvidia/clara-holoscan/holoscan:v4.5.0-cuda13`

Holoscan 4.5.0 has been tested with the RTX 3050.

An actual Holoscan application was also executed successfully and produced:

`Hello World!`

Therefore, Holoscan installation and basic execution are no longer open setup tasks.

---

## 6. Holoscan Runtime Requirements

The following runtime configuration was required during the validated Holoscan test and should be retained when building the project container:

* `--gpus all`
* `--ipc=host`
* `--ulimit memlock=-1`
* `--ulimit stack=67108864`
* `--cap-add CAP_SYS_PTRACE`

The shared-memory configuration is particularly relevant because imaging workloads may require more shared memory than the default Docker configuration provides.

---

## 7. Compatibility Requirements

The current environment has a CUDA version difference between the NVIDIA driver and the Holoscan container.

The host driver reports CUDA 13.1.

The Holoscan 4.5.0 container was built with CUDA 13.2.

The container reported CUDA Minor Version Compatibility mode during execution.

This is currently acceptable because the actual Holoscan application executed successfully.

The environment should not be changed unnecessarily while development is underway.

If the NVIDIA driver, CUDA version, WSL2 setup, Docker configuration, MATLAB release, or Holoscan version is changed, the environment should be tested again.

---

## 8. Repository Requirements

The final repository shall contain, at minimum:

* source code
* MATLAB implementation
* Holoscan application
* configuration files
* setup/build instructions
* execution instructions
* dataset instructions
* documentation
* performance results
* architecture diagrams
* license

The repository shall use either:

* BSD 2-Clause License

or:

* MIT License

The final repository must be public for submission.

---

## 9. Documentation Requirements

The repository documentation shall explain:

1. What the project does.
2. Why ultrasound was selected.
3. What data is used.
4. How the raw data is reconstructed.
5. What enhancement is applied.
6. What AI task is performed.
7. Where GPU acceleration is used.
8. How MATLAB GPU Coder is used.
9. How the system is integrated into Holoscan.
10. How to build and run the application.
11. What hardware and software are required.
12. What performance was measured.
13. What limitations remain.

Documentation must distinguish between tested functionality and planned functionality.

---

## 10. Demonstration Requirements

The final demonstration should show the complete system rather than isolated pieces.

The demonstration should ideally show:

**Raw/Input Data → Reconstructed Image → Enhanced Image → AI Result → Holoscan Streaming Application**

Performance information should also be shown where useful.

The demonstration video should make the connection between the MATLAB-developed algorithms, GPU acceleration, and Holoscan deployment clear.

---

## 11. Submission Requirements

The final submission shall include:

* public GitHub repository
* BSD 2-Clause or MIT license
* MATLAB and/or Simulink solution
* single main entry point
* end-to-end execution
* minimal manual setup
* documentation
* working demonstration
* performance evaluation
* repository link submitted through the required MathWorks submission process

The project deadline currently recorded in the project documentation is:

**December 24, 2026**

---

## 12. Optional / Future Requirements

The following are not required for the first working version:

* real ADI ADC integration
* advanced segmentation
* multiple AI models
* temporal analysis
* transformer-based models
* multiple imaging modalities
* advanced beamforming methods
* production/clinical deployment
* clinical validation
* medical-device certification

These should not delay the core pipeline.

The priority is to get one complete path working first.

---

## 13. Current Priority

The project should now be developed in this order:

**1. Select and inspect raw ultrasound data**

**2. Define the exact input format**

**3. Build the first MATLAB reconstruction**

**4. Validate the reconstructed image**

**5. Build the enhancement stage**

**6. Select and train the AI baseline**

**7. Connect reconstruction → enhancement → AI**

**8. Profile the complete MATLAB pipeline**

**9. Identify GPU candidates**

**10. Generate/test CUDA using MATLAB GPU Coder**

**11. Build the Holoscan application around the validated components**

**12. Add visualization**

**13. Benchmark the complete pipeline**

**14. Clean the repository and prepare the final demonstration**

The important thing now is **not to start adding extra features**. We need one working end-to-end path first, then improve it.