# 08 — Holoscan Integration

## 1. Purpose

This stage moves the working ultrasound pipeline into NVIDIA Holoscan.

By this point, the main processing stages should already be understood and tested separately. Holoscan is where those stages are connected into a streaming pipeline.

The goal is not to rewrite everything at once.

The first goal is to get the pipeline running end to end, with clear data moving between each processing stage.

The intended flow is:

**Input Data → Reconstruction → Image Enhancement → Output**

Once that works, the pipeline can be adapted toward live or near-real-time processing.

---

## 2. Why Holoscan

Holoscan is being used to build the application around a streaming architecture rather than treating every processing step as a standalone MATLAB script.

This is important because the final system needs to process ultrasound data continuously.

Instead of:

```text
Load file
    ↓
Process everything
    ↓
Save result
```

the target architecture is closer to:

```text
Data Source
    ↓
Reconstruction
    ↓
Image Enhancement
    ↓
Output
```

with frames moving through the pipeline as they become available.

---

## 3. Initial Integration Strategy

The integration should start with the simplest working pipeline.

Do not try to optimize the complete system immediately.

The first version should use a known dataset and process frames in sequence.

A basic structure is:

```text
Dataset / Input
      ↓
Frame Acquisition
      ↓
Reconstruction
      ↓
Image Enhancement
      ↓
Output
```

The purpose of this first version is to confirm that the different stages can communicate correctly.

---

## 4. Pipeline Stages

Each major processing stage should have a clearly defined input and output.

### Input

Provides the raw RF or channel data for each frame.

### Reconstruction

Converts the raw ultrasound data into a reconstructed image.

### Image Enhancement

Applies the image-processing or enhancement stage developed earlier.

### Output

Stores, displays, or forwards the processed image.

The exact implementation of each stage can change, but the interfaces between them should remain clear.

---

## 5. Frame-Based Processing

The first Holoscan implementation should process one frame at a time.

Conceptually:

```text
Frame N
  ↓
Reconstruction
  ↓
Enhancement
  ↓
Output
```

Then:

```text
Frame N+1
  ↓
Reconstruction
  ↓
Enhancement
  ↓
Output
```

This makes it easier to identify problems with frame ordering, data transfer, and processing latency.

Once this works reliably, the system can be tested with longer sequences.

---

## 6. Data Interface

The data passed between operators needs to be defined explicitly.

For each frame, the system should know:

* Data type
* Number of dimensions
* Image dimensions
* Number of channels where applicable
* Sampling information where required
* Frame identifier
* Timestamp where available

The receiving stage should not have to guess what the incoming data represents.

The interface should be documented so that the reconstruction and enhancement stages can be replaced independently if required.

---

## 7. Holoscan Operators

The pipeline should be divided into operators based on meaningful processing stages.

A possible initial structure is:

```text
InputOperator
      ↓
ReconstructionOperator
      ↓
EnhancementOperator
      ↓
OutputOperator
```

The names are only examples.

The important point is that each operator should have one clear responsibility.

For example, the reconstruction operator should not also contain unrelated display or dataset-management logic.

---

## 8. Reconstruction Integration

The MATLAB reconstruction developed earlier becomes the reference for this stage.

The Holoscan version needs to produce the same basic result when given the same input frame and reconstruction parameters.

The first integration should therefore use a fixed test frame.

The workflow is:

```text
Known RF frame
      ↓
Holoscan reconstruction
      ↓
Reconstructed image
```

The output can then be compared with the previously saved MATLAB reference.

The purpose is to catch integration errors before performance work begins.

---

## 9. Image Enhancement Integration

The reconstructed image is then passed to the enhancement stage.

The enhancement operator should receive the reconstructed image in a clearly defined format.

For example:

```text
Reconstructed Image
        ↓
Enhancement Operator
        ↓
Enhanced Image
```

The enhancement stage should not need to know how the original RF data was acquired or how the reconstruction was performed.

This separation will make it easier to change either stage later.

---

## 10. CPU Implementation First

The first Holoscan version should run correctly on the CPU.

GPU execution should only be introduced after the CPU pipeline is functioning.

This gives us a working reference for the complete pipeline and makes debugging much easier.

The progression should be:

```text
CPU pipeline
     ↓
Correctness check
     ↓
Performance measurement
     ↓
GPU acceleration
```

rather than trying to debug correctness and GPU performance at the same time.

---

## 11. GPU Integration

After the CPU pipeline is working, the computationally expensive stages can be moved toward GPU execution.

The exact split will depend on the profiling results from the previous stages.

A possible architecture is:

```text
Input
  ↓
CPU / Host
  ↓
GPU Reconstruction
  ↓
GPU Image Enhancement
  ↓
Output
```

The goal should be to avoid unnecessary transfers between CPU and GPU memory.

If reconstruction produces data on the GPU and enhancement also runs on the GPU, the data should ideally remain on the GPU between those stages.

This will be investigated during implementation rather than assumed in advance.

---

## 12. Memory Transfers

Memory movement needs to be treated as part of the system performance.

Moving a large image or RF frame between host and GPU memory can introduce significant overhead.

The implementation should therefore track:

* Host-to-device transfers
* Device-to-host transfers
* Intermediate buffers
* Buffer allocation
* Data copies between operators
* Synchronization points

Where possible, buffers should be reused instead of repeatedly allocated and released for every frame.

---

## 13. Pipeline Configuration

The Holoscan application should have a clear configuration for the main processing parameters.

This may include:

* Input source
* Dataset path
* Frame range
* Reconstruction parameters
* Image dimensions
* Enhancement parameters
* Output location
* GPU device
* Processing mode

These values should not be scattered throughout the implementation.

A configuration file or clearly defined application parameters should be used where practical.

---

## 14. Development Mode

During development, the application should support processing a known dataset without requiring live hardware.

This is important because most debugging and development can be performed using recorded ultrasound data.

A typical development flow will be:

```text
Recorded Dataset
       ↓
Holoscan Pipeline
       ↓
Reconstruction
       ↓
Enhancement
       ↓
Saved / Displayed Result
```

This gives us a repeatable workload for testing changes.

---

## 15. Live Input Preparation

Once the recorded-data pipeline is stable, the input stage can be prepared for a live ultrasound source.

The exact interface will depend on the hardware and acquisition system available to the project.

The input operator should eventually be capable of receiving frames continuously rather than reading them from a file.

The downstream processing stages should not need to change significantly when the source changes.

Ideally:

```text
Recorded Input ─────┐
                    ├──→ Reconstruction → Enhancement → Output
Live Input ─────────┘
```

The processing pipeline should remain the same while only the source operator changes.

---

## 16. Error Handling

The pipeline needs to handle basic failures cleanly.

Examples include:

* Missing input data
* Invalid frame dimensions
* Unsupported data type
* Incorrect metadata
* Empty frames
* GPU initialization failure
* Operator failure
* Unexpected end of input

An error should be reported clearly rather than producing a corrupted image and continuing silently.

During development, useful diagnostic information should also be logged.

---

## 17. Logging

The application should provide enough logging to understand what is happening during execution.

Useful information includes:

* Application startup
* Selected input source
* Frame dimensions
* Processing stage
* Frame number
* Processing errors
* GPU device information
* Processing time where available

The logging should help with debugging without making the output unnecessarily difficult to read.

---

## 18. Output

The first output does not need to be a polished visualization system.

It only needs to prove that the complete pipeline is working.

The output can initially be:

* Saved image files
* Processed frame data
* A simple display
* Performance logs

Later, this can be replaced or extended with the final demonstration interface.

---

## 19. End-to-End Test

A basic end-to-end test should process a known sequence through the complete pipeline.

For example:

```text
Input Frame
     ↓
Holoscan
     ↓
Reconstruction
     ↓
Enhancement
     ↓
Output Image
```

The test should confirm that:

1. The frame enters the pipeline correctly.
2. Reconstruction produces valid output.
3. Enhancement receives the expected input.
4. Enhancement produces valid output.
5. The output can be displayed or saved.
6. Multiple frames can be processed without failure.

---

## 20. Comparison With the MATLAB Reference

The first Holoscan implementation should be compared against the previously validated MATLAB results.

The same input frame should be used wherever possible.

The comparison should look at:

* Image dimensions
* Image orientation
* Depth scaling
* Lateral scaling
* Overall image appearance
* Signal range
* Major structures
* Numerical differences where appropriate

Small numerical differences may be expected after changing implementations, particularly when interpolation or GPU operations are involved.

The important requirement is that the Holoscan result remains consistent with the validated reference.

---

## 21. Initial Performance Measurement

Performance measurements should begin once the complete pipeline works.

At this point, measure the time taken by each major stage:

```text
Input                XX ms
Reconstruction       XX ms
Enhancement          XX ms
Output               XX ms
----------------------------
Total                XX ms
```

The actual values will be recorded from the implementation.

No performance claim should be made until the complete workload has been measured on the target hardware.

---

## 22. Pipeline Stability

The pipeline should be tested over enough frames to expose basic stability problems.

The test should check for:

* Dropped frames
* Increasing memory usage
* Unexpected latency
* Frame ordering problems
* Operator failures
* GPU synchronization issues
* Output corruption

A pipeline that works for one frame but fails after several hundred frames is not considered stable.

---

## 23. Holoscan Milestones

### Milestone 1 - Basic Pipeline

A recorded dataset can pass through the Holoscan application.

### Milestone 2 - Reconstruction Integration

The reconstruction stage works inside the pipeline.

### Milestone 3 - Enhancement Integration

The image enhancement stage receives and processes reconstructed images.

### Milestone 4 - End-to-End Output

The complete pipeline produces valid output frames.

### Milestone 5 - Reference Comparison

Holoscan output is compared against the MATLAB reference.

### Milestone 6 - GPU Integration

The appropriate processing stages are moved toward GPU execution.

### Milestone 7 - Stable Multi-Frame Processing

The pipeline can process a sequence of frames without failure.

### Milestone 8 - Performance Baseline

End-to-end processing time and individual stage timings have been measured.

---

## 24. Current Definition of Done

The Holoscan integration stage will be considered complete when:

* A recorded ultrasound dataset can be processed through Holoscan.
* The input data interface is clearly defined.
* Reconstruction runs as part of the pipeline.
* Image enhancement runs after reconstruction.
* The complete pipeline produces valid output.
* The pipeline works across multiple frames.
* Holoscan output has been compared with the MATLAB reference.
* Basic error handling and logging are in place.
* CPU execution has been verified.
* GPU acceleration has been integrated where justified by profiling.
* Major memory transfers and synchronization points are understood.
* End-to-end processing time has been measured.
* The pipeline is stable enough to move into real-time performance testing.
