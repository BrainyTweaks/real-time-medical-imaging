# Data and Dataset

## 1. Purpose

The project needs raw ultrasound data that can be passed into the image reconstruction stage.

The important point is that the main pipeline should not start from a finished ultrasound image. We want data that is as close as practical to the output of the acquisition system.

The first version of the project does not require a physical ADC. A recorded or simulated dataset is enough to develop the processing pipeline.

The dataset will also affect the reconstruction algorithm. We need to know the channel arrangement, sampling rate, probe geometry, and acquisition sequence before we can correctly reconstruct an image.

For this reason, dataset selection comes before the reconstruction implementation.

---

## 2. What the Input Needs to Represent

The preferred input is raw ultrasound receive data.

Conceptually, the acquisition path is:

**Transducer → Analog Signal → ADC → Digital RF Data → Reconstruction**

For the software-only version, the first part can be replaced with:

**Recorded/Simulated RF Data → Reconstruction**

The replacement data should still represent the digital samples that would normally be produced after ADC conversion.

A normal B-mode ultrasound image is not equivalent to this input. An image can be used later for enhancement and AI development, but it does not allow us to demonstrate the raw-data-to-image reconstruction part of the project.

---

## 3. Required Data Information

Before using a dataset, the following information needs to be available or determined.

### Acquisition

* Number of receive channels
* Number of samples per channel
* Sampling frequency
* Sample data type
* Number of frames or acquisitions
* RF/IQ representation
* Transmit configuration, if available
* Receive configuration, if available

### Probe / Array

* Number of elements
* Element arrangement
* Element pitch
* Element spacing
* Probe geometry
* Element positions, if available

### Imaging

* Imaging depth
* Lateral field of view
* Speed of sound assumption
* Transmit focus, if applicable
* Receive focus, if applicable
* Beam steering information, if applicable

### File Information

* File format
* File size
* Metadata format
* Compression, if any
* Dataset license
* Required software for reading the data

Not every dataset will provide all of these values. Missing acquisition information is one of the main things that needs to be checked before selecting the final dataset.

---

## 4. Dataset Types

There are three practical input options for this project.

### 4.1 Public Recorded Raw Data

This is the preferred option if a suitable dataset is available.

Recorded raw data gives us a realistic input and allows the same frames to be processed repeatedly during development.

It also gives us a fixed dataset for comparing different reconstruction algorithms and measuring performance.

The main problem is that many publicly available ultrasound datasets provide reconstructed images rather than raw channel data.

A dataset that contains only B-mode images is not enough for the raw-data reconstruction part of this project.

---

### 4.2 Simulated Ultrasound Data

Simulation is the fallback if a suitable raw dataset cannot be used.

A simulator can generate channel data while allowing parameters such as:

* array geometry
* imaging depth
* target position
* speed of sound
* noise
* sampling rate

to be controlled.

This is useful for testing the reconstruction algorithm because the expected target position can be known beforehand.

Simulation also makes it possible to create controlled test cases before moving to more complicated recorded data.

The simulator does not need to reproduce an entire commercial ultrasound scanner. The first goal is simply to generate data with a known relationship between the signal and the target location.

---

### 4.3 Real ADC Data

Real acquisition data is the closest match to the final system.

If suitable Analog Devices hardware becomes available, the acquisition stage can eventually be connected to the processing pipeline.

This is not a dependency for the first implementation.

The software architecture should be designed so that the recorded-data source can later be replaced by a hardware source.

The downstream reconstruction interface should remain the same.

---

## 5. Public Dataset Search

A public raw ultrasound dataset needs to satisfy more than just having the word "ultrasound" in its description.

The main questions are:

1. Does it contain raw RF or channel data?
2. Is the acquisition geometry documented?
3. Is the sampling frequency known?
4. Are the transducer parameters available?
5. Can the data be used for research?
6. Can the data be downloaded and processed locally?
7. Can the data be converted into the input format required by our MATLAB reconstruction?
8. Is the dataset large enough to provide multiple test frames?

Datasets containing only JPEG, PNG, or similar finished ultrasound images are useful for the AI stage but do not satisfy the raw reconstruction requirement by themselves.

---

## 6. AI Dataset and Reconstruction Dataset Do Not Have to Be the Same

There is no requirement that one dataset must provide everything.

The reconstruction part of the project needs raw RF/channel data.

The AI part needs labelled ultrasound images.

These requirements are different.

It is therefore acceptable to use:

**Dataset A → Raw-data reconstruction**

and

**Dataset B → AI training/evaluation**

provided that the final system still demonstrates the intended processing chain.

For example, a raw dataset can be used to establish the reconstruction algorithm while a labelled public ultrasound-image dataset can be used to train the initial AI model.

If we later find a dataset that supports both requirements, that would simplify the project, but it should not be treated as mandatory.

---

## 7. Initial Data Strategy

The project will use a staged approach rather than waiting for the perfect dataset.

### Stage 1 — Find Suitable Raw Data

First, identify public datasets that contain raw RF or channel data.

The dataset documentation will be checked for acquisition parameters and probe information.

### Stage 2 — Inspect the Data

Before implementing beamforming, load a small portion of the dataset and inspect:

* dimensions
* data type
* value range
* channel arrangement
* sample count
* metadata
* frame structure

### Stage 3 — Define the Internal Format

Once the data is understood, convert it into one consistent internal representation.

The reconstruction stage should not need to know whether the original file was MAT, HDF5, binary, or another format.

The input interface should be defined by the project rather than by the original file format.

### Stage 4 — Build a Small Test Dataset

A small subset will be used during algorithm development.

This avoids loading a large dataset every time the reconstruction code is changed.

### Stage 5 — Keep Full Data for Validation

The larger dataset or complete sequence will be kept for later validation and performance testing.

The small development set and the final performance set should not be confused.

---

## 8. Internal Input Representation

The exact MATLAB representation will depend on the selected dataset.

The preferred concept is a matrix or array representing the receive samples and channels.

For a simple single acquisition, the data can be represented conceptually as:

**samples × channels**

For multiple frames or acquisitions, an additional dimension may be required:

**samples × channels × frames**

The actual dimensions will be recorded after the dataset is selected.

The reconstruction input should also have a separate structure containing the acquisition parameters rather than relying on undocumented constants inside the reconstruction code.

For example, the reconstruction configuration may eventually contain:

* sampling frequency
* speed of sound
* element positions
* imaging depth
* lateral imaging range
* number of channels

The exact structure will be defined during implementation.

---

## 9. Data Conversion

The original dataset should be preserved.

If conversion is required, the converted copy should be generated from the original data rather than modifying the source files.

For example:

**Original Dataset → Import Script → Project Internal Format → Reconstruction**

The import/conversion script should document any changes made to the data.

Possible operations include:

* changing the data type
* rearranging dimensions
* converting units
* selecting a subset of channels
* extracting individual frames
* converting file formats

Any operation that changes the numerical values should be documented.

Normalization should not be performed automatically unless there is a reason for it.

For reconstruction, preserving the original signal characteristics is important.

---

## 10. Data Inspection

The first actual experiment with the selected dataset will be data inspection.

The inspection script should report basic information such as:

```text
File:
Format:
Number of samples:
Number of channels:
Number of frames:
Data type:
Sampling frequency:
Value range:
Probe information:
Imaging information:
```

The script should also display representative raw signals.

A small number of channels should be plotted so that we can confirm that the loaded data actually looks like ultrasound receive data.

This step is useful for catching problems such as:

* incorrect dimension ordering
* wrong data type
* corrupted files
* incorrect scaling
* unexpected channel ordering
* missing metadata

before reconstruction development starts.

---

## 11. Frame Definition

The project needs a clear definition of what one processing unit represents.

For the initial implementation, one processing unit will normally correspond to one ultrasound acquisition/frame or one equivalent block of channel data.

The exact definition depends on the selected dataset.

The reconstruction function should receive one defined input unit and return one reconstructed image.

This makes later streaming integration easier because the same unit can become the basic data object passed through Holoscan.

---

## 12. Development Data vs Performance Data

Two different data sizes should be maintained.

### Development Data

A small subset used while writing and debugging the algorithms.

The goal is fast iteration.

### Performance Data

A larger sequence used to measure:

* reconstruction time
* enhancement time
* AI inference time
* end-to-end latency
* throughput

The performance dataset should contain enough frames to avoid basing conclusions on a single image.

---

## 13. Data Quality Checks

Before reconstruction, the selected input should pass basic checks.

At minimum:

* data can be loaded without errors
* dimensions are known
* channel count is known
* sample count is known
* sampling frequency is known
* data type is known
* channel ordering is understood
* required probe/acquisition information is available
* representative signals can be visualized

If important acquisition information is missing, this should be recorded before reconstruction starts.

We should not guess a probe geometry or sampling frequency just to make the algorithm run.

---

## 14. Dataset Licensing

The license or usage terms of every external dataset must be checked before including it in the project repository or distributing it with the project.

The repository should not contain a copy of a dataset unless its license permits redistribution.

If redistribution is not allowed, the repository should contain instructions explaining:

* where the dataset can be obtained
* what files are required
* where the files should be placed
* how to run the import script

The same applies to AI datasets.

---

## 15. Relationship to ADI Hardware

The final system is intended to represent a hardware-oriented acquisition-to-processing workflow.

The project therefore keeps the acquisition interface separate from the reconstruction code.

The current development path is:

**Recorded/Simulated Data → Internal Input Interface → Reconstruction**

The future hardware path is:

**ADI ADC → Internal Input Interface → Reconstruction**

The objective is for both paths to produce the same internal input representation.

This means that adding the ADC later should mainly require replacing or extending the acquisition layer rather than rewriting the image-processing pipeline.

---

## 16. Dataset Decision Criteria

The final reconstruction dataset will be selected using the following priority:

1. Raw RF/channel data available.
2. Acquisition parameters documented.
3. Probe geometry available.
4. Sampling information available.
5. Data can be processed in MATLAB.
6. Multiple frames/acquisitions available.
7. Research use is permitted.
8. Data can be used without requiring unavailable proprietary software.
9. Data size is practical for the development machine.
10. Data is suitable for demonstrating GPU acceleration.

A dataset that fails the first few requirements should not be selected simply because it is easy to download.

---

## 17. Current Status

The software and GPU environment has already been validated.

The raw-data source is still a separate decision.

At this point:

**Confirmed**

* The project requires raw-data input for the reconstruction stage.
* Recorded data can be used without physical ADC hardware.
* Simulated data is an acceptable fallback.
* Real ADI ADC integration is optional for the initial implementation.
* The reconstruction input must have a defined and documented format.
* The original dataset should be preserved.
* A small development dataset and a larger performance sequence should be used.

**Not yet fixed**

* Final raw ultrasound dataset
* Final file format
* Exact number of channels
* Exact sample count
* Sampling frequency
* Probe geometry
* Final reconstruction frame format

These values should be filled in after the dataset is selected and inspected.

---

## 18. Immediate Next Step

The next task is not beamforming yet.

The next task is to identify a suitable raw ultrasound dataset and inspect one sample.

The workflow should be:

**Find Dataset → Download → Read Documentation → Load Data → Inspect Dimensions → Inspect Metadata → Plot Raw Channels → Define Input Format**

Only after this is complete should the reconstruction implementation begin.

The output of this stage should be a small, reproducible MATLAB data-loading/inspection script and a clearly documented input structure for the reconstruction stage.
