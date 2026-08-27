# Image Reconstruction

## 1. Purpose

The image reconstruction stage is where the project starts doing the actual ultrasound imaging work.

The input at this point is not an ultrasound image. It is raw RF or channel data containing the signals received by the ultrasound transducer elements.

The job of this stage is to turn those signals into a spatial image.

For the first implementation, the main goal is to get one reliable reconstruction working in MATLAB. We are not trying to make it fast yet. We first need to understand the data, confirm the imaging geometry, produce a sensible image, and have something that can later be used as the reference for GPU acceleration.

The basic flow is:

**Raw RF Data → Beamforming → Envelope Detection → Log Compression → Ultrasound Image**

The exact steps may change depending on the dataset we finally use.

---

## 2. Input Data

The reconstruction stage will receive raw ultrasound data from the data layer described in the previous document.

The input should represent data that exists before the final ultrasound image is produced.

Depending on the selected dataset, the data may be arranged as:

* samples × channels
* samples × channels × frames
* channels × samples × frames
* another dataset-specific format

The first task is therefore to inspect the actual data instead of assuming a particular arrangement.

For every selected dataset, we need to determine:

* Number of receive channels
* Number of samples per channel
* Number of frames or acquisitions
* Sampling frequency
* Data type
* RF or IQ representation
* Transducer element positions
* Element spacing
* Imaging depth
* Speed of sound used by the dataset
* Transmit configuration
* Receive configuration
* Any available timing information
* Any metadata required for reconstruction

These values need to be documented before implementing the beamformer.

---

## 3. Understanding the Acquisition Geometry

Beamforming depends heavily on geometry.

The reconstruction algorithm needs to know where each transducer element is located and how long an ultrasound signal should take to travel between an element and a particular point in the image.

For a simple pulse-echo system, the approximate depth associated with a received echo can be written as:

**Depth = c × t / 2**

where:

* `c` is the assumed speed of sound in tissue
* `t` is the measured round-trip time

The division by two is because the ultrasound pulse travels to the target and then returns to the transducer.

For a real array, the calculation is more involved.

A point in the image can be represented by coordinates `(x, z)`, while a receive element has a position `(x_e, 0)`.

The distance between them is approximately:

**r = sqrt((x - x_e)^2 + z^2)**

The corresponding receive delay is then related to:

**t = r / c**

For multiple elements, these delays will be different for the same image point.

Beamforming uses those delays to align the signals before combining them.

This is one of the main reasons why raw ultrasound data cannot simply be displayed directly as an image.

---

## 4. Initial Reconstruction Method

The first reconstruction method will be kept relatively simple.

The initial implementation will investigate **Delay-and-Sum (DAS) beamforming**.

DAS is a useful starting point because the basic idea is easy to understand and the computation maps naturally to the problem we are trying to solve.

For every point in the desired image:

1. Calculate the distance from that point to each receive element.
2. Convert the distance into a propagation delay.
3. Find the corresponding sample in each channel.
4. Apply the required interpolation if the delay falls between samples.
5. Sum the delayed channel values.
6. Store the resulting value at that image location.

Conceptually:

**Channel Data → Delay Each Channel → Align Signals → Sum → Image Pixel**

This will provide a clear baseline before we consider more complicated beamforming methods.

---

## 5. MATLAB Implementation

The first working version will be implemented in MATLAB.

The implementation should be split into small functions instead of putting the entire reconstruction process into one large script.

A possible structure is:

```text
reconstruction/
├── load_rf_data.m
├── setup_imaging_grid.m
├── calculate_delays.m
├── das_beamform.m
├── envelope_detection.m
├── log_compression.m
└── reconstruct_frame.m
```

The exact file structure can change as implementation progresses.

The important part is that the reconstruction algorithm should have a clear input and output.

For example:

```text
RF frame + acquisition parameters
              ↓
        Reconstruction
              ↓
     Reconstructed image
```

The rest of the project should not need to know how the beamformer internally calculates each pixel.

---

## 6. Imaging Grid

Before beamforming, an imaging grid needs to be defined.

The grid determines the locations at which the reconstruction will be calculated.

For a 2D image, the grid can be represented using lateral and depth coordinates:

```text
        Lateral position
       ←──────────────→

       x x x x x x x x
       x x x x x x x x
Depth  x x x x x x x x
       x x x x x x x x
       x x x x x x x x
```

Each grid point represents a location where the algorithm estimates the received ultrasound response.

The initial grid should not be unnecessarily large.

A reasonable starting point is to use a resolution that allows the algorithm to be tested quickly while still showing the expected structures.

The final image dimensions can be increased later if required.

This is important because the computational cost of DAS beamforming increases significantly as the number of image pixels increases.

---

## 7. Delay Calculation

For each image point and each receive channel, the required delay must be calculated.

For a basic receive-only reconstruction:

**distance = sqrt((x - x_e)^2 + (z - z_e)^2)**

and:

**delay = distance / c**

where:

* `x` and `z` describe the image point
* `x_e` and `z_e` describe the receive element
* `c` is the assumed speed of sound

For a transmit-and-receive system, the total travel time can include both transmit and receive paths.

The actual equation will depend on the acquisition sequence used by the selected dataset.

This is why the reconstruction implementation must be tied to the dataset's acquisition information rather than using arbitrary beamforming parameters.

---

## 8. Sample Interpolation

The calculated delay will usually not correspond exactly to an integer sample.

For example, the required location might fall between samples 105 and 106.

The implementation will therefore need some form of interpolation.

Linear interpolation is a reasonable starting point because it is simple and computationally manageable.

The basic idea is:

```text
Sample 105        Sample 106
    |------------------|
             ↑
        required time
```

The value at the required time is estimated from the surrounding samples.

More sophisticated interpolation methods can be considered later if they provide a meaningful improvement in image quality.

At the beginning, the priority is to establish a reliable reconstruction rather than adding complexity unnecessarily.

---

## 9. Channel Summation

After the appropriate delayed samples have been obtained, the channel values are combined.

The simplest approach is coherent summation:

**Beamformed value = Σ channel signals**

The resulting value represents the combined response for that particular image location.

Depending on the dataset and reconstruction method, additional weighting or apodization may be applied.

Apodization can reduce unwanted sidelobes and improve image quality, but it also adds additional processing.

Therefore, the initial implementation should first establish a basic DAS result before introducing more advanced weighting.

---

## 10. Envelope Detection

The beamformed RF image will generally still contain an oscillating RF waveform.

That is not the representation we normally want to display as an ultrasound image.

The next step is therefore to obtain the signal envelope.

One common approach is to use the analytic signal:

**analytic signal = RF + j × Hilbert(RF)**

The envelope is then:

**envelope = abs(analytic signal)**

This produces a representation of the local signal magnitude.

The envelope can then be converted into an intensity image.

The exact implementation will depend on the data representation.

If the selected dataset already provides an envelope or IQ representation, this step may not be necessary in the same form.

---

## 11. Log Compression

Ultrasound signals can have a very large dynamic range.

Displaying the raw envelope directly can make weaker structures difficult to see.

Log compression is therefore normally applied before visualization.

A typical representation is:

**I_dB = 20 × log10(envelope / maximum envelope)**

The resulting values can be displayed over a selected dynamic range.

For example, the display might use a range such as:

**0 dB to -60 dB**

The exact value should be determined from the actual data.

It should not be chosen simply because it is a common ultrasound display setting.

The reconstruction code should keep the raw beamformed/envelope data available separately from the display representation.

This is important because the AI stage may eventually need a different input representation from the one used for human visualization.

---

## 12. First MATLAB Reconstruction

The first milestone for this stage is deliberately simple:

**Take one valid RF frame and produce one understandable ultrasound image.**

The initial implementation should therefore focus on one frame rather than immediately attempting continuous processing.

The workflow should be:

1. Load one RF frame.
2. Confirm its dimensions.
3. Confirm the sampling frequency.
4. Confirm the channel layout.
5. Load the array geometry.
6. Define the imaging grid.
7. Calculate beamforming delays.
8. Perform DAS beamforming.
9. Generate the envelope.
10. Apply log compression.
11. Display the reconstructed image.
12. Save the result for comparison.

Only after this works reliably should multiple frames be introduced.

---

## 13. MATLAB Reference Output

The MATLAB reconstruction will become the reference implementation for the rest of the project.

This is important later when GPU Coder and CUDA implementations are introduced.

The reference result should therefore be saved for selected test frames.

For example:

```text
validation/
├── reference_rf_frame.mat
├── reference_reconstruction.mat
└── reference_reconstruction.png
```

The exact file names are not important.

What matters is that we have known inputs and known outputs.

Later, the GPU implementation can process exactly the same RF frame and its result can be compared against the MATLAB reference.

---

## 14. Reconstruction Validation

A reconstruction should not be considered successful just because an image appears on the screen.

Several checks should be performed.

### 14.1 Data Check

Confirm that the expected number of channels and samples are being processed.

### 14.2 Geometry Check

Confirm that the image coordinates correspond to the physical imaging region.

### 14.3 Depth Check

Confirm that known or expected structures appear at reasonable depths.

### 14.4 Lateral Position Check

Confirm that structures appear at sensible lateral positions.

### 14.5 Signal Check

Confirm that the beamformed output is not entirely zero, saturated, or dominated by numerical artifacts.

### 14.6 Visual Check

Inspect the reconstructed image for obvious reconstruction failures.

### 14.7 Repeatability Check

Run the same frame again and confirm that the result is unchanged.

These checks will help separate actual algorithm problems from data-format or parameter mistakes.

---

## 15. Reconstruction Quality

The first version does not need to produce the best possible ultrasound image.

The goal is to establish a trustworthy baseline.

The following properties will be observed:

* Visibility of expected structures
* Image artifacts
* Background noise
* Spatial resolution
* Contrast
* Depth representation
* Lateral representation
* Stability between frames

If the selected dataset provides suitable ground truth or reference information, numerical measurements can also be considered.

However, visual inspection will remain useful during early development because it can quickly reveal problems with geometry, timing, or channel ordering.

---

## 16. Phased Array System Toolbox

The project will investigate the use of MATLAB's Phased Array System Toolbox where it is useful for understanding or validating the reconstruction process.

The toolbox can provide useful functionality for array modelling, signal processing, and beamforming experiments.

However, the project should avoid becoming dependent on a toolbox function without understanding what the function is doing internally.

The reconstruction algorithm needs to remain understandable because later stages will require:

* GPU acceleration
* code generation
* performance profiling
* Holoscan integration

If a high-level toolbox function cannot be used directly in the final accelerated implementation, the underlying operation may need to be implemented explicitly.

The MATLAB reference implementation can therefore use toolbox functionality during exploration, while the final accelerated implementation may use a more controlled implementation where necessary.

---

## 17. Multiple Frames

Once one frame is working, the same reconstruction should be tested on a sequence of frames.

For example:

```text
Frame 1 → Reconstruction
Frame 2 → Reconstruction
Frame 3 → Reconstruction
Frame 4 → Reconstruction
...
```

The purpose is to make sure the implementation is not accidentally tuned to one particular frame.

The output should remain stable across the dataset.

This will also provide the first useful workload for performance testing.

Processing a single frame tells us how the algorithm behaves once.

Processing many frames tells us how expensive the algorithm actually is.

---

## 18. Performance Baseline

Performance measurements will be introduced only after the reconstruction is correct.

The first measurements should include:

* Total reconstruction time
* Beamforming time
* Envelope detection time
* Log-compression time
* Image dimensions
* Input data dimensions
* Memory usage where useful

The most important initial measurement is the time required to reconstruct one frame.

For example:

```text
RF input
   ↓
Beamforming        XX ms
   ↓
Envelope           XX ms
   ↓
Log compression    XX ms
   ↓
Total              XX ms
```

The actual numbers will be recorded after implementation.

No target performance number should be claimed before the workload and hardware are known.

---

## 19. Profiling

Once the baseline is available, MATLAB profiling will be used to determine where the reconstruction time is being spent.

The main question is:

**What is actually slow?**

It may be the delay calculation.

It may be interpolation.

It may be the channel summation.

It may be memory access.

It may be another part of the implementation.

The answer needs to come from measurement.

The result of profiling will determine which sections are candidates for GPU acceleration.

---

## 20. GPU Preparation

The first reconstruction implementation should not be written purely for GPU Coder from the beginning.

Correctness comes first.

However, the implementation should avoid unnecessary constructs that will make later code generation difficult.

The eventual target is:

**MATLAB Reference → GPU-Compatible MATLAB → GPU Coder → CUDA**

The reconstruction stage is expected to be one of the strongest candidates for GPU acceleration because the same type of calculations are repeated across a large number of image locations and receive channels.

The exact acceleration strategy will be decided after profiling.

---

## 21. Possible Reconstruction Improvements

Once the basic DAS implementation is working, improvements can be investigated if they are justified.

Possible areas include:

* Receive apodization
* Transmit modelling
* Better interpolation
* Dynamic receive focusing
* Improved delay calculation
* Different beamforming approaches
* Parallel implementation
* Memory-access optimization
* GPU execution

These are not requirements for the first milestone.

The project should not move into advanced beamforming before the basic reconstruction is understood and validated.

---

## 22. Reconstruction Milestones

This stage will be considered complete progressively.

### Milestone 1 — Data Loaded

A valid RF frame can be loaded and inspected.

### Milestone 2 — Geometry Confirmed

The channel arrangement, sampling rate, element positions, and imaging parameters are understood.

### Milestone 3 — Basic Beamforming

A first DAS implementation produces a non-empty reconstructed result.

### Milestone 4 — Image Formation

Envelope detection and log compression produce a usable ultrasound image.

### Milestone 5 — Validation

The result is checked across multiple frames and compared against the expected behaviour of the dataset.

### Milestone 6 — CPU Baseline

The reconstruction runtime is measured on the development machine.

### Milestone 7 — GPU Candidate Identified

Profiling shows which reconstruction operations are worth investigating for GPU acceleration.

---

## 23. Current Definition of Done

The reconstruction stage will be considered ready for the next stage when:

* A valid raw RF dataset has been loaded.
* The input format is documented.
* The imaging geometry is understood.
* A MATLAB reconstruction implementation is working.
* A reconstructed ultrasound image can be generated from raw data.
* The reconstruction works on more than one frame.
* A reference output has been saved.
* Basic image-quality checks have been performed.
* CPU execution time has been measured.
* The main computational bottleneck has been identified.
* The reconstruction interface is defined clearly enough for the enhancement stage to consume its output.

At this point, the output of the reconstruction stage becomes the input to the next part of the project:

**Reconstructed Ultrasound Image → Image Enhancement**
