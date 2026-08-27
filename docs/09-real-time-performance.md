# 09 — Real-Time Performance

## 1. Purpose

This stage measures how well the complete ultrasound pipeline performs when processing frames continuously.

The main question is no longer just whether the pipeline works.

The question is:

**Can the system process ultrasound data fast enough and consistently enough for real-time use?**

The measurements from this stage will be used to identify the remaining performance bottlenecks and determine what needs to be optimized before the final demonstration.

---

## 2. What Real-Time Means for This Project

Real-time performance should be defined using the actual frame rate of the selected ultrasound dataset or acquisition system.

If the input produces `N` frames per second, the available processing time per frame is approximately:

**Frame budget = 1 / N seconds**

For example, a 30 FPS input provides approximately:

**33.3 ms per frame**

A pipeline that consistently takes longer than the available frame budget will eventually fall behind the incoming data.

The target frame rate therefore needs to be based on the actual acquisition workload rather than an arbitrary number.

---

## 3. End-to-End Latency

The main measurement will be the time between receiving a frame and producing the corresponding final output.

Conceptually:

```text
Frame arrives
     ↓
Reconstruction
     ↓
Image enhancement
     ↓
Output
```

The total processing latency is the time taken by the complete path.

Where possible, the individual stages should also be measured separately.

For example:

```text
Input             XX ms
Reconstruction    XX ms
Enhancement       XX ms
Output            XX ms
-----------------------
Total             XX ms
```

The actual values will be obtained from profiling and testing.

---

## 4. Throughput

Latency and throughput are related but are not the same thing.

Latency measures how long one frame takes to travel through the pipeline.

Throughput measures how many frames the system can process per second.

The system should therefore report both.

For example:

```text
Latency:     XX ms/frame
Throughput:  XX frames/sec
Input rate:  XX frames/sec
```

A system may have reasonable average throughput while still having occasional long processing times.

That is why both measurements are required.

---

## 5. Frame Budget

The measured processing time should be compared against the available frame budget.

For an input rate of `F` frames per second:

**Frame budget = 1000 / F ms**

The result should be documented for the selected dataset or acquisition system.

The comparison should look something like:

```text
Input frame rate:       XX FPS
Available frame budget: XX ms
Measured processing:    XX ms
Margin:                 XX ms
```

The goal is to determine whether the pipeline can keep up with the incoming data.

---

## 6. Measurement Method

Performance measurements should be repeatable.

The same:

* Input data
* Image dimensions
* Reconstruction parameters
* Enhancement parameters
* Hardware
* Software configuration

should be used when comparing different implementations.

Warm-up runs should be separated from measured runs where necessary, particularly when GPU initialization or memory allocation is involved.

The number of frames used for each test should also be recorded.

---

## 7. Average Performance Is Not Enough

The average processing time alone is not sufficient for a real-time system.

The test should also record:

* Minimum processing time
* Maximum processing time
* Mean processing time
* Median processing time
* High-percentile latency where useful
* Number of missed frame deadlines

For example:

```text
Mean:       XX ms
Median:     XX ms
Maximum:    XX ms
P95:        XX ms
P99:        XX ms
```

This will show whether the pipeline is consistently fast or only fast on average.

---

## 8. Frame Drops

If the processing pipeline cannot keep up with the incoming data, frames may need to be dropped.

Frame drops should be measured explicitly.

The test should record:

**Dropped frames / Total frames**

For example:

```text
Input frames:   XXXX
Processed:      XXXX
Dropped:        XX
Drop rate:      XX %
```

The exact values will come from testing.

The system should also distinguish between intentionally skipped frames and frames lost because the pipeline could not keep up.

---

## 9. GPU Performance

The GPU implementation should be compared with the CPU baseline established earlier.

The comparison should include:

* Reconstruction time
* Enhancement time
* End-to-end time
* Throughput
* Memory transfers
* GPU utilization where useful

The objective is not simply to show that the GPU is faster.

The objective is to determine **where the GPU actually improves the pipeline**.

---

## 10. CPU vs GPU Comparison

A controlled comparison should be performed using the same workload.

A basic comparison can be recorded as:

```text
                    CPU        GPU

Reconstruction      XX ms      XX ms
Enhancement         XX ms      XX ms
Total               XX ms      XX ms
Throughput          XX FPS     XX FPS
```

The speedup can then be calculated as:

**Speedup = CPU time / GPU time**

The reported speedup should always identify the exact workload and hardware used.

---

## 11. Memory Transfer Overhead

GPU acceleration can lose much of its benefit if large amounts of data are repeatedly transferred between CPU and GPU memory.

The performance investigation should therefore identify:

* Host-to-device transfer time
* Device-to-host transfer time
* GPU kernel execution time
* Synchronization time
* Buffer allocation time

Where possible, intermediate processing should remain on the GPU.

For example:

```text
CPU
 ↓
GPU upload
 ↓
Reconstruction
 ↓
Enhancement
 ↓
GPU result
 ↓
CPU only when required
```

This should be tested rather than assumed to be optimal.

---

## 12. Profiling

Once the end-to-end pipeline is measurable, profiling should be used to identify the remaining bottlenecks.

The main questions are:

* Which stage takes the most time?
* Is the GPU actually being utilized effectively?
* Are memory transfers limiting performance?
* Are kernels too small or too frequently launched?
* Is CPU synchronization causing delays?
* Is image enhancement now more expensive than reconstruction?

The answers should come from measurements.

Optimization should focus on the largest measured bottlenecks rather than optimizing code simply because it looks computationally expensive.

---

## 13. Reconstruction Optimization

If reconstruction remains the dominant workload, possible optimization areas include:

* Delay calculation
* Interpolation
* Channel summation
* Memory access
* Parallelization
* GPU kernel organization
* Reuse of calculated values
* Buffer reuse

The existing validated reconstruction should be treated as the reference.

An optimization should not be accepted simply because it is faster.

The output must remain sufficiently consistent with the reference result.

---

## 14. Image Enhancement Optimization

The enhancement stage should also be profiled independently.

Depending on the implementation, the expensive operations may include:

* Image filtering
* Neural-network inference
* Resampling
* Normalization
* Memory transfers
* Image-format conversion

If enhancement becomes the dominant stage after reconstruction is accelerated, optimization effort may need to move to this part of the pipeline.

---

## 15. Pipeline-Level Optimization

Optimizing individual operators is not enough.

The complete pipeline should also be examined.

For example:

```text
Input
  ↓
Operator A
  ↓
Operator B
  ↓
Operator C
```

may be slower than expected because of synchronization or data movement between operators.

The final performance should therefore be measured at the pipeline level as well as the operator level.

---

## 16. Latency vs Throughput

The project should distinguish between low latency and high throughput.

For a continuous ultrasound system, both are useful.

A pipeline may process many frames per second while still having a large delay between input and output.

Likewise, a pipeline may have low latency for individual frames but fail to maintain the required frame rate.

The final implementation should therefore report both where practical.

---

## 17. Sustained Processing Test

The system should be tested over a sufficiently long sequence rather than only a few frames.

The purpose is to identify problems that appear over time.

The test should monitor:

* Processing rate
* Frame drops
* Latency
* Memory usage
* GPU utilization
* Errors
* Output stability

The pipeline should not gradually become slower or consume increasing amounts of memory during a normal run.

---

## 18. Different Workloads

Performance should be tested using the actual workload expected for the final demonstration.

Where practical, additional configurations can also be tested.

Examples include:

* Different image sizes
* Different numbers of receive channels
* Different frame rates
* Different reconstruction depths
* Different enhancement settings

This will show how sensitive the system is to changes in workload.

---

## 19. Hardware Configuration

Every performance result should record the hardware used.

At minimum, document:

* CPU
* GPU
* GPU memory
* System RAM
* Operating system
* CUDA version where relevant
* MATLAB version where relevant
* Holoscan version where relevant

This is necessary because performance numbers without hardware information are difficult to reproduce or interpret.

---

## 20. Performance Results

The final performance results should be summarized clearly.

A useful format is:

```text
Input:
    Frame rate: XX FPS
    RF dimensions: XXXX × XXXX
    Image dimensions: XXXX × XXXX

CPU:
    Reconstruction: XX ms
    Enhancement: XX ms
    Total: XX ms
    Throughput: XX FPS

GPU:
    Reconstruction: XX ms
    Enhancement: XX ms
    Total: XX ms
    Throughput: XX FPS

Frame drops:
    XX / XXXX
```

The actual values will be filled in after testing.

---

## 21. Real-Time Acceptance Criteria

The system should be considered capable of real-time operation when the measured workload can be processed continuously without unacceptable frame loss or latency.

The acceptance criteria should be based on:

* Required input frame rate
* Available frame budget
* Sustained processing rate
* Frame-drop rate
* End-to-end latency
* Output stability

These values should be defined from the actual project requirements and measured workload.

No unsupported real-time claim should be made before the measurements are complete.

---

## 22. Performance Milestones

### Milestone 1 — Baseline Measured

CPU and GPU execution times have been measured.

### Milestone 2 — Bottlenecks Identified

Profiling shows where the majority of processing time is being spent.

### Milestone 3 — GPU Performance Measured

GPU acceleration has been measured under the same workload as the CPU baseline.

### Milestone 4 — Pipeline Optimized

The main computational and data-transfer bottlenecks have been addressed.

### Milestone 5 — Sustained Test

The system has been tested across an extended sequence.

### Milestone 6 — Real-Time Capability Evaluated

Processing performance has been compared against the actual input frame budget.

---

## 23. Current Definition of Done

The real-time performance stage will be considered complete when:

* The complete pipeline has been benchmarked.
* CPU and GPU performance have been measured.
* End-to-end latency has been recorded.
* Throughput has been recorded.
* Frame drops have been measured.
* The main performance bottlenecks have been identified.
* GPU and memory-transfer overheads have been investigated.
* The system has been tested over a sustained sequence.
* Performance results have been recorded with the relevant hardware and software configuration.
* The measured performance has been compared against the required input frame rate.
* The system's real-time capability and remaining limitations are clearly documented.
