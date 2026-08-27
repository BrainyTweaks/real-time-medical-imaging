# Image Enhancement

## 1. Purpose

The image reconstruction stage gives us the first usable ultrasound image, but that image will not necessarily be suitable for the final application.

Ultrasound images contain speckle, noise, uneven brightness, and low-contrast regions. Depending on the reconstruction method and the input data, some structures may also be difficult to distinguish. The purpose of this stage is to improve the reconstructed image before it is sent to the AI model and displayed to the user.

The main requirement here is not to make the image look artificially clean. We need to improve visibility while keeping the information that matters for the imaging task.

This stage will therefore be developed using actual reconstructed ultrasound data rather than choosing a filter only because it produces a visually attractive result.

The enhancement pipeline will also be evaluated from a performance point of view. A processing method that improves the image but adds a large amount of latency may not be suitable for the final real-time application.

---

## 2. Input and Output

The input to this stage is the output of the image-reconstruction stage.

```text
Raw RF / Channel Data
        ↓
Image Reconstruction
        ↓
Reconstructed Ultrasound Image
        ↓
Image Enhancement
        ↓
Enhanced Ultrasound Image
        ↓
AI Inference / Visualization
```

The enhancement stage should not need to know how the image was reconstructed.

Its interface should therefore remain simple:

**Input:** reconstructed ultrasound image

**Output:** enhanced ultrasound image

Keeping this interface stable will allow different enhancement methods to be tested without changing the reconstruction or AI portions of the project.

---

## 3. What Needs to Be Improved

The first step will be to inspect the reconstructed images and determine what problems are actually present.

Possible issues include:

* Speckle noise
* Low contrast
* Uneven intensity
* Weak anatomical boundaries
* Excessive background noise
* Small unwanted structures or artifacts
* Dynamic-range problems

The actual problem will depend on the selected dataset and reconstruction algorithm.

We should not assume that every listed problem needs to be fixed. For example, speckle is a normal characteristic of ultrasound imaging and removing it aggressively can also remove useful information.

The enhancement stage will therefore be kept as small as possible while still providing a useful improvement.

---

## 4. Initial Processing Methods

A few standard image-processing methods will be tested as candidate building blocks.

### 4.1 Median Filtering

A median filter can be used as an initial noise-reduction baseline.

It is simple, easy to understand, and relatively inexpensive computationally. Different kernel sizes can be tested to see how much noise can be reduced before image details begin to disappear.

The median filter will mainly be used as a baseline rather than assuming it will be part of the final pipeline.

---

### 4.2 Wiener Filtering

A Wiener filter can be tested when the reconstructed image contains noise that can benefit from adaptive filtering.

Unlike a fixed smoothing operation, Wiener filtering considers local image statistics when estimating the output.

Its usefulness will be evaluated directly on the reconstructed ultrasound data.

If the improvement is small compared with the additional computation, it may be removed from the final pipeline.

---

### 4.3 Adaptive Contrast Enhancement

Adaptive histogram equalization using MATLAB's `adapthisteq` function is another candidate.

This can improve local contrast in images where some regions contain useful structures but have a narrow intensity range.

The parameters will need to be chosen carefully. Excessive contrast enhancement can make speckle and unwanted artifacts more visible.

The goal is to improve the visibility of useful structures, not simply to increase contrast everywhere.

---

### 4.4 Edge-Preserving Filtering

An edge-preserving filter can also be investigated when smoothing is required but important boundaries need to remain visible.

Bilateral filtering is one possible option.

This type of processing may be useful when a conventional smoothing filter removes too much structural information.

Again, it will only be included in the final pipeline if testing shows a clear benefit.

---

## 5. Initial Enhancement Pipeline

The first version of the enhancement stage will remain deliberately simple.

A possible starting point is:

```text
Reconstructed Image
        ↓
Noise Reduction
        ↓
Contrast Adjustment
        ↓
Enhanced Image
```

The exact filters and their order will be decided after testing.

For example:

```text
Reconstructed Image
        ↓
Median Filter
        ↓
Adaptive Contrast Enhancement
        ↓
Enhanced Image
```

may work better or worse than another combination.

There is no reason to lock the final processing chain before seeing the actual reconstruction results.

---

## 6. Image Representation

The enhancement stage must operate on a clearly defined image representation.

If the reconstruction stage produces an RF or complex-valued representation, the required envelope detection, magnitude calculation, logarithmic compression, or other conversion should be completed before applying ordinary image-enhancement operations.

A typical ultrasound display path may look like:

```text
Beamformed Signal
        ↓
Envelope
        ↓
Log Compression
        ↓
Image
        ↓
Enhancement
```

The exact representation will depend on the reconstruction implementation selected for this project.

This needs to be documented when the reconstruction stage is finalized so that the enhancement and AI stages are working from a known input.

---

## 7. Before and After Comparison

Every candidate enhancement method will be compared against the original reconstructed image.

At minimum, the comparison should show:

1. Original reconstructed image
2. Enhanced image
3. Difference in processing time
4. Relevant image-quality observations

A simple visual comparison is useful, but it should not be the only measurement.

Where suitable, numerical measurements can also be used.

Possible measurements include contrast-related measures, signal-to-noise-related measures, edge preservation, or other metrics that make sense for the selected dataset.

The important point is that a metric should have a reason for being included. We should not collect a large number of image-quality values that do not tell us anything useful about the final system.

---

## 8. Effect on the AI Model

The enhancement stage sits directly before AI inference, so image quality cannot be judged independently from the AI task.

For each candidate enhancement method, we should eventually check whether the AI model performs better, worse, or approximately the same compared with the unprocessed reconstruction.

For example:

```text
Reconstructed Image
        ↓
        ├──→ AI
        │
        └──→ Enhancement → AI
```

This gives us a direct comparison.

An image may look better to a person while making the model's job harder.

The opposite can also happen: an enhancement that does not produce a dramatic visual improvement may give the AI model a more consistent input.

The final enhancement method should therefore be selected using both image quality and AI performance.

---

## 9. Runtime Considerations

The enhancement stage is part of a real-time pipeline, so processing time matters.

Each candidate operation will be measured using representative frames.

The measurements should eventually include:

* Processing time per frame
* Average processing time
* Variation between frames
* CPU usage where relevant
* GPU processing time where applicable

The goal is to understand whether the enhancement stage is actually contributing meaningful latency.

For example, if two methods provide similar results but one takes significantly less time, the faster method will generally be the better choice for this project.

---

## 10. GPU Acceleration

GPU acceleration will not be added simply because a GPU is available.

The first implementation will run on the CPU and will be used as the reference version.

After the enhancement pipeline has been finalized, it will be profiled together with the other processing stages.

If enhancement becomes a meaningful part of the total processing time, suitable operations will be investigated for GPU execution.

MATLAB GPU capabilities and MATLAB GPU Coder will be considered where appropriate.

The intended development path is:

```text
MATLAB Implementation
        ↓
Validate Output
        ↓
Measure Runtime
        ↓
Identify Expensive Operations
        ↓
GPU Compatibility Check
        ↓
GPU Implementation / GPU Coder
        ↓
Compare With CPU Result
```

There is no requirement that every filter be converted to CUDA.

If an operation is already fast enough on the CPU, leaving it there may be the better engineering decision.

---

## 11. Numerical Validation

The accelerated enhancement implementation must be checked against the MATLAB reference implementation.

The comparison should verify that the GPU version produces the same intended image-processing behavior.

Depending on the operation, small numerical differences may occur because of floating-point calculations and differences in execution order.

The comparison should therefore include both numerical and visual checks.

For example, we can compare:

* Maximum absolute difference
* Mean absolute difference
* Relative error where appropriate
* Output image appearance

The acceptable tolerance will be established during implementation rather than being chosen arbitrarily beforehand.

---

## 12. Selecting the Final Method

The final enhancement method will be selected using four main considerations:

**Image quality**

Does the method make useful structures easier to see without destroying important information?

**AI performance**

Does the processed image provide a suitable input to the selected AI model?

**Runtime**

Can the method execute quickly enough for the intended pipeline?

**Implementation**

Can the method be implemented reliably in the final MATLAB/GPU/Holoscan environment?

A method that performs well in only one of these areas will not automatically be selected.

The final choice should provide a reasonable balance between all four.

---

## 13. Development Procedure

The enhancement work will follow this sequence:

```text
Obtain Reconstructed Images
        ↓
Inspect Image Characteristics
        ↓
Establish Unprocessed Baseline
        ↓
Test Noise Reduction
        ↓
Test Contrast Enhancement
        ↓
Test Edge-Preserving Methods
        ↓
Compare Results
        ↓
Check Effect on AI Input
        ↓
Measure Runtime
        ↓
Select Final Enhancement Method
        ↓
Prepare for GPU / Holoscan Integration
```

Only a small number of methods need to survive into the final implementation.

The purpose of the experiments is to find a method that works well for this project, not to create a catalogue of every available MATLAB image-processing function.

---

## 14. Final Interface

Once the enhancement stage has been finalized, it should expose a simple processing interface that can later be called by the Holoscan pipeline.

Conceptually:

```text
Input:
    Reconstructed ultrasound frame

Processing:
    Selected enhancement operations

Output:
    Enhanced ultrasound frame
```

The implementation details can change during development, but the input and output contract should remain stable.

This will make it possible to replace the MATLAB reference implementation with an optimized implementation later without changing the rest of the system.

---

## 15. Current Status

At this stage, the enhancement algorithm has **not yet been fixed**.

The next practical step is to obtain the output of the image-reconstruction stage and test the candidate methods on the actual data.

The final enhancement method will only be documented as selected after those experiments have been completed.

This keeps the project documentation aligned with what has actually been tested rather than claiming that an algorithm works before it has been evaluated.

The expected outcome of this stage is one validated enhancement pipeline that can be passed to the AI stage and later integrated into the GPU-accelerated Holoscan application.
