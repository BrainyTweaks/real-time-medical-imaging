# 07 — GPU Acceleration and CUDA Code Generation

## 1. Purpose

GPU acceleration is an important part of this project because the final system is intended to process ultrasound data continuously rather than as a collection of offline MATLAB experiments.

The first versions of the reconstruction and image-processing algorithms will be developed in MATLAB. Once those algorithms are working correctly, their performance will be measured to determine which parts of the pipeline actually require acceleration.

The project will then investigate the use of **MATLAB GPU Coder** to generate CUDA code for suitable computationally intensive functions.

The main goal is not to convert every MATLAB function into CUDA code.

The goal is to identify the parts of the system where GPU execution provides a useful improvement and then make those accelerated components usable within the final NVIDIA Holoscan application.

The intended development path is:

**MATLAB Implementation → Validation → CPU Profiling → GPU Candidate Selection → CUDA Generation → GPU Validation → Benchmarking → Holoscan Integration**

---

## 2. Why GPU Acceleration

The ultrasound reconstruction stage is expected to contain a significant amount of computation.

Beamforming can require calculations for many image locations using data from multiple receive channels. As the number of channels and image points increases, the amount of computation can increase substantially.

Image enhancement can also involve processing every pixel of every incoming frame.

The AI stage introduces another computational workload through neural-network inference.

When these stages are executed repeatedly on a continuous stream, the total processing requirement can become too large for a simple CPU-only implementation to maintain the required processing rate.

An NVIDIA GPU is well suited to workloads containing many independent or highly parallel calculations.

The project will therefore investigate whether moving suitable processing stages to the GPU can reduce processing time and improve the throughput of the complete pipeline.

---

## 3. Reference MATLAB Implementation

The MATLAB implementation will be treated as the reference version of the algorithms.

Before optimization begins, the reconstruction and enhancement algorithms must produce results that are understood and reproducible.

The reference implementation provides a baseline for both numerical validation and performance measurement.

The development sequence will therefore begin with:

**Implement → Test → Validate → Profile**

Only after this stage will GPU optimization begin.

This is important because optimizing an algorithm that has not yet been validated can make debugging much more difficult.

The MATLAB implementation should also be kept reasonably simple and modular so that individual functions can be tested and profiled independently.

---

## 4. CPU Baseline

A CPU baseline will be established before measuring GPU acceleration.

The baseline should use the same input data, image dimensions, and processing configuration that will later be used for the GPU implementation.

The main measurements will include:

* Processing time per frame
* Average processing time
* Throughput
* Individual stage execution time
* Memory requirements where practical

The baseline provides the reference needed to determine whether GPU acceleration provides an actual improvement.

For example:

**GPU Speedup = CPU Processing Time / GPU Processing Time**

The final speedup will be measured rather than predicted.

---

## 5. Profiling

Profiling will be performed before selecting functions for GPU acceleration.

The purpose is to identify where the majority of the processing time is being spent.

The expected areas of interest include:

* RF data preparation
* Beamforming
* Signal processing
* Image formation
* Image enhancement
* Data conversion
* AI preprocessing
* AI inference
* CPU-GPU data transfers

The profiling results will determine which parts of the pipeline should receive optimization effort.

A function that takes only a small fraction of the total processing time may not be worth moving to the GPU.

On the other hand, a reconstruction operation that consumes most of the frame-processing time would be a strong candidate.

This prevents optimization from being based on assumptions.

---

## 6. GPU Candidate Selection

Not every MATLAB operation will necessarily be suitable for GPU Coder.

Candidate functions will be selected using two criteria:

1. They should represent a meaningful portion of the computational workload.
2. They should be suitable for implementation or code generation for the target GPU environment.

The first candidate is expected to be part of the image-reconstruction process, particularly if profiling confirms that beamforming dominates the runtime.

Image-enhancement operations may also be considered if their computational cost is significant.

AI inference will be treated separately because neural-network inference may already have an appropriate GPU execution path.

The final list of GPU-accelerated functions will therefore be based on profiling and compatibility testing.

---

## 7. MATLAB GPU Coder

MATLAB GPU Coder will be investigated as the main path for converting suitable MATLAB algorithms into CUDA implementations.

The basic concept is:

**MATLAB Function → GPU Coder → Generated CUDA Code → NVIDIA GPU**

The generated code will then be tested independently before being connected to Holoscan.

GPU Coder compatibility will need to be checked for each selected function.

If a particular MATLAB function is not supported directly, the algorithm may need to be rewritten using operations that are compatible with code generation.

This is another reason to keep the reference implementation modular.

Instead of rewriting an entire processing stage, an individual function can be replaced or modified while preserving the rest of the algorithm.

---

## 8. CUDA Generation Strategy

CUDA generation will be performed only after the corresponding MATLAB implementation has been validated.

The first generated version should prioritize correctness rather than aggressive optimization.

The initial sequence will be:

**Validated MATLAB Function**

↓

**Prepare for GPU Coder**

↓

**Generate CUDA**

↓

**Build Generated Code**

↓

**Execute on RTX 3050**

↓

**Compare With MATLAB Reference**

Only after the generated implementation produces acceptable results will further optimization be considered.

---

## 9. Numerical Validation

The generated CUDA implementation must be compared with the MATLAB reference.

The comparison will depend on the processing stage.

For numerical processing, quantities such as maximum absolute error, mean error, or relative error may be calculated where appropriate.

For image reconstruction and enhancement, visual comparison will also be useful.

Small differences are expected in some cases because CPU and GPU implementations may perform floating-point operations differently.

Parallel execution can also change the order in which operations such as summation are performed.

The purpose of validation is therefore not necessarily to require every floating-point value to be identical.

The important requirement is that any differences remain within an acceptable range and do not materially change the resulting image or AI output.

The actual tolerance values will be established during implementation based on the algorithm being tested.

---

## 10. GPU Performance Measurement

Once the generated CUDA implementation has been validated, its performance will be measured.

The main comparison will be between the CPU reference and GPU implementation using the same workload.

Measurements will include, where applicable:

* CPU execution time
* GPU execution time
* GPU speedup
* Processing throughput
* Data-transfer overhead
* GPU memory usage

Warm-up executions may be excluded from the final measurements where required because the first GPU execution can include initialization overhead.

Multiple iterations will be used rather than relying on a single measurement.

The resulting values will be recorded in the project's performance documentation.

---

## 11. Data Transfer

GPU acceleration does not automatically guarantee better performance.

If large amounts of data are repeatedly transferred between CPU and GPU memory, the transfer overhead can reduce or even eliminate the benefit of GPU computation.

The final implementation will therefore consider the movement of data between processing stages.

The preferred design is to keep data on the GPU when several consecutive operations can operate there without unnecessary transfers.

For example:

**Input → GPU Reconstruction → GPU Enhancement → GPU AI Processing**

may be more efficient than repeatedly moving the image between CPU and GPU memory.

The actual memory strategy will depend on the interfaces required by the selected Holoscan operators and generated CUDA code.

---

## 12. GPU Memory Constraints

The development system contains an NVIDIA GeForce RTX 3050 Laptop GPU with approximately 4 GB of dedicated GPU memory.

This memory limit will be considered during algorithm development and optimization.

The project will avoid assuming that very large intermediate buffers can remain permanently resident on the GPU.

Memory usage will be measured for the actual implementation.

If necessary, processing dimensions, buffering strategy, or intermediate representations may need to be adjusted.

The purpose is to build an implementation that works reliably on the available development hardware rather than designing around a much larger GPU that is not available.

---

## 13. Reconstruction Acceleration

The reconstruction stage is expected to be one of the primary GPU candidates.

Beamforming can involve a large number of operations across:

* Receive channels
* Samples
* Image pixels
* Beamforming positions
* Frames

This makes the workload potentially well suited to GPU parallelism.

The exact implementation will depend on the reconstruction algorithm selected in `04-image-reconstruction.md`.

The MATLAB version will first be used as the reference.

After profiling, the computationally expensive section of the reconstruction process will be isolated and evaluated for GPU Coder compatibility.

The generated CUDA implementation will then be compared against the MATLAB result.

---

## 14. Image Enhancement Acceleration

The image-enhancement stage will also be evaluated for GPU acceleration.

Potential candidates may include operations that process large image arrays or perform substantial per-pixel calculations.

However, GPU acceleration will not automatically be applied to every filter.

If an enhancement operation executes quickly enough on the CPU, keeping it CPU-based may be the better engineering decision.

The final implementation will therefore be based on measured runtime and the effect of each operation on total pipeline performance.

---

## 15. AI GPU Execution

The AI model is expected to execute on the NVIDIA GPU as part of the final pipeline.

The AI stage will be treated separately from the MATLAB GPU Coder path because neural-network inference may use a deployment mechanism different from the generated CUDA used for signal processing.

The important requirement is that the AI stage can receive its input efficiently and return the inference result without becoming an unnecessary bottleneck.

The exact deployment mechanism will be selected after the MobileNetV2 baseline has been trained and its inference requirements have been established.

---

## 16. Generated Code Interface

Generated CUDA code must eventually be connected to the rest of the application.

The generated functions should therefore have clearly defined input and output interfaces.

For example, a reconstruction function may receive:

* Raw RF data
* Acquisition parameters
* Imaging configuration

and return:

* Reconstructed image data

The exact interface will be defined during implementation.

Keeping the interface simple will make it easier to connect the generated code to a Holoscan operator later.

---

## 17. Holoscan Integration

The generated CUDA implementation is not considered complete simply because it runs independently.

The final objective is to make the accelerated processing part of the Holoscan streaming pipeline.

The intended relationship is:

**MATLAB Algorithm**

↓

**GPU Coder**

↓

**Generated CUDA**

↓

**Holoscan Processing Operator**

↓

**Next Pipeline Stage**

The ADI HoloHub `matlab_gpu_coder` example will be used as a reference when investigating this integration.

The exact implementation will depend on the generated code interface and the Holoscan SDK APIs used by the final application.

---

## 18. Benchmarking the Complete Pipeline

Individual GPU functions will be benchmarked first.

Once they are integrated into Holoscan, the complete application will also be measured.

This is important because the performance of an individual CUDA function does not necessarily represent the performance of the complete system.

The final pipeline may contain additional costs associated with:

* Buffer management
* Data movement
* Operator scheduling
* Synchronization
* AI inference
* Visualization
* Input and output handling

The end-to-end measurements will therefore be used to determine whether the GPU acceleration actually improves the complete application.

---

## 19. Optimization Strategy

Optimization will be performed in stages.

### Stage 1 — Correctness

Make sure the MATLAB implementation works.

### Stage 2 — Baseline

Measure the CPU implementation.

### Stage 3 — Profiling

Identify the actual bottlenecks.

### Stage 4 — GPU Candidate Selection

Choose the operations that are worth accelerating.

### Stage 5 — CUDA Generation

Generate and build the CUDA implementation.

### Stage 6 — Validation

Compare the GPU result with the MATLAB reference.

### Stage 7 — Benchmarking

Measure the actual performance improvement.

### Stage 8 — Integration

Connect the accelerated component to Holoscan.

### Stage 9 — End-to-End Optimization

Measure the complete pipeline and address the remaining bottlenecks.

This order keeps optimization controlled and makes it possible to explain why each optimization was introduced.

---

## 20. Development Environment

The current development environment provides the following GPU execution path:

**Windows 11 → WSL2 → Ubuntu 24.04 → Docker → NVIDIA GPU Runtime → NVIDIA RTX 3050 → Holoscan**

MATLAB R2025b is available on the host for algorithm development and GPU experimentation.

The validated environment also includes NVIDIA Holoscan SDK 4.5.0 running inside the NVIDIA container environment.

This environment is recorded in `01-system-understanding.md` and should be treated as the current known-good baseline.

Changes to the NVIDIA driver, CUDA environment, WSL2 configuration, Docker environment, MATLAB version, or Holoscan version should be revalidated before becoming part of the project's supported configuration.

---

## 21. Expected Results

The project will eventually report measured results rather than predefined performance claims.

The final comparison is expected to include:

| Measurement                |        CPU |        GPU |
| -------------------------- | ---------: | ---------: |
| Reconstruction time        | To measure | To measure |
| Enhancement time           | To measure | To measure |
| AI inference time          | To measure | To measure |
| End-to-end processing time | To measure | To measure |
| Throughput                 | To measure | To measure |

The actual values will only be added after implementation and testing.

If a particular GPU optimization does not provide a useful improvement, that result will also be recorded.

A negative or small performance improvement is still useful because it shows which parts of the pipeline are not worth accelerating under the selected workload.

---

## 22. Success Criteria

The GPU acceleration stage will be considered successful when the project has:

* A validated MATLAB reference implementation.
* A measured CPU baseline.
* Identified computational bottlenecks.
* Selected appropriate GPU candidates.
* Generated CUDA code for at least one meaningful processing stage where feasible.
* Validated the generated implementation against the MATLAB reference.
* Measured GPU execution performance.
* Documented the resulting speedup or performance difference.
* Connected the accelerated component to the Holoscan pipeline where practical.
* Identified any remaining performance bottlenecks.

The objective is therefore not simply to produce CUDA code.

The objective is to show a clear and measurable path from a MATLAB algorithm to GPU-accelerated processing that can contribute to the final real-time imaging application.