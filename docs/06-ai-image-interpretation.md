# AI Image Interpretation

## 1. Purpose

The AI stage is where the pipeline moves from image processing to image interpretation.

The input to this stage will be the enhanced ultrasound image produced by the previous stage. The AI model will then perform one defined task and return a result that can be displayed as part of the final application.

The purpose of this work is not to build a clinical diagnostic system. It is to demonstrate that an AI model can be integrated into the same processing pipeline as ultrasound reconstruction and image enhancement, while still meeting the practical requirements of a real-time application.

The AI task will therefore be kept manageable and measurable.

The final choice of task and model will be based on the available data, the quality of the reconstructed images, model performance, and inference speed.

---

## 2. AI Task

The first decision is to define exactly what the model needs to do.

Possible tasks include:

* Image classification
* Object or region detection
* Image segmentation

These tasks have different data and implementation requirements.

### Classification

The model receives an ultrasound image and predicts a class.

For example:

```text
Ultrasound Image
        ↓
AI Model
        ↓
Class + Confidence
```

This is the simplest option and is a good starting point if the available dataset contains reliable image-level labels.

### Detection

The model identifies a region or structure inside the image.

```text
Ultrasound Image
        ↓
AI Model
        ↓
Bounding Box + Class + Confidence
```

This provides a more visible demonstration because the detected region can be drawn directly over the ultrasound image.

### Segmentation

The model produces a pixel-level mask.

```text
Ultrasound Image
        ↓
AI Model
        ↓
Segmentation Mask
```

Segmentation is more demanding because the training dataset needs pixel-level annotations.

The final task will be selected after the available datasets and reconstructed image format have been evaluated.

For the initial implementation, a lightweight classification or detection task is preferred because it keeps the development effort under control and allows more time for GPU and Holoscan integration.

---

## 3. Dataset

The AI model needs a dataset that matches the selected task.

A publicly available ultrasound dataset may be used if it provides suitable images and labels.

One possible starting point is the Breast Ultrasound Images Dataset (BUSI), which contains ultrasound images with associated labels and segmentation information.

Other datasets may be considered if they provide a better match to the final imaging task.

The dataset will not automatically be treated as suitable just because it is publicly available.

Before using it, the following will be checked:

* Image format
* Image dimensions
* Number of samples
* Class distribution
* Label quality
* Availability of annotations
* Licensing and permitted use
* Similarity to the intended ultrasound application
* Suitability for the selected AI task

The final dataset choice will be recorded in the project documentation once it has been confirmed.

---

## 4. Relationship Between the Dataset and Raw RF Pipeline

There is an important distinction between the imaging dataset and the raw RF dataset.

The raw RF data is required to demonstrate the image-reconstruction part of the project.

The AI dataset does not necessarily need to contain RF data if the selected AI task is designed around ultrasound images.

This creates two possible development paths.

### Path A — Separate Development Datasets

```text
Raw RF Dataset
      ↓
Reconstruction
      ↓
Enhancement
      ↓
Test / Visualization

Ultrasound Image Dataset
      ↓
Training
      ↓
AI Model
```

The AI model can then be tested with images having the same general characteristics as the output of the imaging pipeline.

### Path B — Common Imaging Data

If the selected raw dataset also contains suitable labels or annotations, it may be possible to use the same data for both reconstruction and AI development.

This would provide a stronger end-to-end relationship because the AI model would be trained and evaluated on images produced from the same type of acquisition data.

The final choice will depend on what data is actually available.

The project should not claim that an AI model trained on an unrelated image dataset has been clinically or scientifically validated for the reconstructed RF dataset.

---

## 5. Dataset Preparation

Before training, the dataset will be inspected and prepared.

Typical preparation steps include:

```text
Original Dataset
      ↓
Remove / identify unusable samples
      ↓
Verify Labels
      ↓
Resize / Format Images
      ↓
Normalize Input
      ↓
Training / Validation / Test Split
```

The exact preprocessing will depend on the selected model.

The preprocessing applied during training must also be available during inference.

For example, if training images are resized and normalized in a particular way, the same operations must be applied to the images arriving from the enhancement stage.

Otherwise, the model will be receiving data that differs from what it saw during training.

---

## 6. Training, Validation, and Test Sets

The dataset will be divided into separate subsets.

The training set will be used to fit the model.

The validation set will be used during development to monitor model behavior and compare configurations.

The test set will be kept separate and used for the final evaluation.

The exact split ratio will depend on the size of the selected dataset.

A typical starting point could be:

```text
Dataset
├── Training
├── Validation
└── Testing
```

Care must also be taken to avoid leakage between the sets.

If multiple images belong to the same patient or examination, samples from the same patient should not be split across training and testing where the dataset structure allows patient-level separation.

The test set should represent data that the model has not seen during training.

---

## 7. Data Augmentation

Data augmentation may be used if the selected dataset is relatively small.

Possible augmentation operations include:

* Small rotations
* Translation
* Scaling
* Cropping
* Intensity changes
* Other transformations that remain realistic for ultrasound images

Augmentation should not be applied blindly.

A transformation that changes the medical meaning of an image would not be appropriate simply because it increases the number of training examples.

The augmentation strategy will therefore be kept conservative and based on the selected task.

---

## 8. Model Selection

The initial model should be small enough to run efficiently on the target GPU while still providing useful performance.

A lightweight convolutional neural network is therefore a practical starting point.

Transfer learning can also be considered.

The general approach is:

```text
Pretrained Network
        ↓
Replace / Adapt Final Layers
        ↓
Train Using Ultrasound Dataset
        ↓
Evaluate
```

Using a pretrained network can reduce the amount of training data and training time required compared with building a network completely from scratch.

Possible model choices will be evaluated based on:

* Accuracy or task-specific performance
* Number of parameters
* Model size
* Input resolution
* Inference time
* GPU memory usage
* MATLAB compatibility
* Deployment compatibility

The final model will be selected after testing rather than choosing a network only because it is popular.

---

## 9. MATLAB Development

MATLAB will initially be used for model development and evaluation.

The Deep Learning Toolbox will provide the main environment for:

* Loading the dataset
* Preparing training data
* Defining the network
* Training the model
* Evaluating predictions
* Inspecting errors
* Measuring inference time

The first objective is to establish a working reference model.

At this point, optimization for Holoscan is not the main concern.

The model needs to demonstrate that it can perform the selected task before deployment work begins.

---

## 10. Baseline Model

A simple baseline model will be trained first.

The baseline is important because it gives us something against which later improvements can be measured.

For example:

```text
Baseline Model
      ↓
Measure Accuracy
      ↓
Measure Inference Time
      ↓
Identify Problems
      ↓
Improve Model
      ↓
Compare Again
```

The baseline should be kept reasonably simple.

There is little benefit in immediately building a complicated network if the dataset, labels, preprocessing, or task definition have not yet been verified.

---

## 11. Model Evaluation

The evaluation metrics will depend on the selected AI task.

### Classification

Possible metrics include:

* Accuracy
* Precision
* Recall
* F1-score
* Confusion matrix

Accuracy alone may not be sufficient if the classes are imbalanced.

### Detection

Possible metrics include:

* Precision
* Recall
* Intersection over Union
* Mean Average Precision, where appropriate

### Segmentation

Possible metrics include:

* Dice coefficient
* Intersection over Union
* Precision
* Recall

The final report will use metrics that actually match the selected task.

The project will not present a single accuracy value as proof that the system is medically reliable.

The AI model is being evaluated as an engineering component of the demonstration.

---

## 12. Error Analysis

Model performance should also be inspected rather than relying only on a final metric.

Examples of useful analysis include:

* Correct predictions
* Incorrect predictions
* False positives
* False negatives
* Difficult image regions
* Poor-quality inputs
* Images affected by preprocessing

This can help determine whether the problem is related to the model itself or to the input image.

Error analysis is also useful when deciding whether the image-enhancement stage is helping or hurting the AI system.

---

## 13. Enhancement and AI Input

The AI model should eventually receive the output of the image-enhancement stage.

The intended relationship is:

```text
Raw RF Data
      ↓
Image Reconstruction
      ↓
Image Enhancement
      ↓
AI Preprocessing
      ↓
AI Model
      ↓
AI Result
```

The preprocessing immediately before inference must be clearly defined.

This may include resizing, normalization, conversion to the required number of channels, or other operations required by the selected network.

The processing should be deterministic so that the same input produces the same expected preprocessing behavior during testing and deployment.

---

## 14. Testing Enhanced Versus Unenhanced Input

One useful experiment will be to compare AI performance using:

```text
Reconstructed Image → AI
```

against:

```text
Reconstructed Image → Enhancement → AI
```

This will show whether the enhancement stage actually benefits the AI task.

The comparison should use the same test data and evaluation procedure.

Possible outcomes are:

* Enhancement improves model performance
* Enhancement has little effect
* Enhancement reduces model performance

Any of these results is useful because it tells us something about the relationship between the image-processing and AI stages.

The final pipeline should use the configuration that provides the best overall engineering trade-off rather than assuming that enhancement must always improve AI accuracy.

---

## 15. Inference Performance

Once the model is working correctly, inference time will be measured.

The measurement should be performed separately from training.

Important values include:

* Model inference time
* Preprocessing time
* Postprocessing time
* GPU memory usage
* CPU-to-GPU transfer time where relevant

The model should be tested over multiple frames rather than measuring only one inference.

Warm-up iterations may be excluded from the final measurement because initial GPU setup can take longer than steady-state inference.

---

## 16. GPU Inference

The final system will use the NVIDIA GPU for AI inference where appropriate.

The RTX 3050 available in the validated development environment provides the target GPU for initial testing.

The exact deployment path will depend on the selected network and the tools supported by the final implementation.

Possible approaches may include MATLAB GPU execution, generated deployment code, or another NVIDIA-compatible inference path.

The important requirement is that the final AI operator must be capable of receiving frames from the upstream pipeline and returning results without becoming an unnecessary bottleneck.

---

## 17. AI Model Optimization

If the baseline model is too slow for the intended pipeline, optimization will be considered.

Possible approaches include:

* Reducing input resolution
* Selecting a smaller network
* Reducing unnecessary layers
* Using an appropriate numeric precision
* GPU execution
* Model-specific deployment optimization

Optimization will only be performed after the baseline model has been measured.

The project should report the actual effect of any optimization.

For example:

```text
Baseline:
Accuracy = measured value
Inference = measured value

Optimized:
Accuracy = measured value
Inference = measured value
```

This makes the trade-off visible instead of simply claiming that the optimized model is better.

---

## 18. AI Output Interface

The AI stage must provide an output that can be consumed by the visualization stage.

For classification:

```text
Class
Confidence
```

For detection:

```text
Bounding Box
Class
Confidence
```

For segmentation:

```text
Segmentation Mask
Class / Label
Confidence where applicable
```

The output should remain associated with the input frame that produced it.

This is particularly important once the pipeline becomes asynchronous or contains multiple frames in flight.

---

## 19. Holoscan Integration

After the AI model has been validated independently, it will be integrated into the Holoscan application.

The intended flow is:

```text
Data Source
      ↓
Reconstruction Operator
      ↓
Enhancement Operator
      ↓
AI Inference Operator
      ↓
Visualization
```

The AI operator should have one clear responsibility: receive a valid image, perform inference, and return the corresponding result.

It should not contain unrelated reconstruction or visualization logic.

This separation will make it easier to test and replace the model later.

---

## 20. Visualization of AI Results

The AI output should be visible in the final demonstration.

For classification, the predicted class and confidence can be displayed alongside the ultrasound image.

For detection, bounding boxes can be drawn over the detected regions.

For segmentation, the predicted mask can be displayed as an overlay.

The final visualization should make it obvious which AI result belongs to which image frame.

---

## 21. Medical and Research Limitations

The AI output will be treated as a research and engineering demonstration.

It will not be presented as a medical diagnosis.

The model will not be claimed to be clinically validated unless appropriate clinical validation has actually been performed.

The selected dataset may also differ substantially from data produced by the final raw-RF reconstruction pipeline.

These limitations should be stated clearly in the project documentation and demonstration.

The purpose of the AI stage is to demonstrate the technical integration of machine learning into a real-time ultrasound processing system.

---

## 22. Development Procedure

The AI work will follow this sequence:

```text
Define AI Task
        ↓
Select Dataset
        ↓
Inspect Labels
        ↓
Prepare Dataset
        ↓
Create Train / Validation / Test Sets
        ↓
Train Baseline Model
        ↓
Evaluate Model
        ↓
Perform Error Analysis
        ↓
Compare Enhanced / Unenhanced Input
        ↓
Measure Inference Time
        ↓
Optimize Model if Necessary
        ↓
Validate GPU Inference
        ↓
Integrate With Holoscan
```

The order is intentional.

There is no point optimizing inference speed before knowing whether the model performs the intended task correctly.

---

## 23. Acceptance Criteria

The AI stage will be considered ready for integration when the following have been established:

* A clearly defined AI task exists.
* A suitable dataset has been selected.
* Training, validation, and testing procedures are documented.
* A baseline model produces meaningful results.
* The selected evaluation metrics have been measured.
* Model errors have been inspected.
* The required input preprocessing is defined.
* Inference time has been measured.
* GPU execution has been tested where applicable.
* The AI output has a defined interface.
* The model can accept the image format produced by the upstream pipeline.
* The result can be passed to the visualization stage.
* The model's limitations are documented.

Only after these conditions are satisfied should the AI component be treated as ready for full Holoscan integration.

---

## 24. Expected Result

The completed AI stage should take an enhanced ultrasound image and produce a defined interpretation result at a measurable processing speed.

The complete relationship will be:

```text
Raw Ultrasound Data
        ↓
Image Reconstruction
        ↓
Image Enhancement
        ↓
AI Preprocessing
        ↓
AI Inference
        ↓
Prediction / Detection / Segmentation
        ↓
Visualization
```

The final model will be chosen based on actual measurements rather than on model complexity alone.

The important result is that AI becomes a real processing stage in the imaging pipeline, with a known input, known output, measured performance, and a clear path toward GPU-accelerated Holoscan deployment.
