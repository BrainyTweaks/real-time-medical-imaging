# 06 — AI-Based Image Interpretation

## 1. Purpose

The AI stage is the part of the project where the processed ultrasound image is used to produce information beyond the image itself.

The input to this stage will come from the image-enhancement stage. The AI model will then perform a defined task on the processed ultrasound image and produce an output that can be displayed as part of the final Holoscan application.

The first version of the project will use **ultrasound image classification** as the AI task. This keeps the first implementation manageable while still demonstrating the complete path from raw ultrasound data to AI-assisted output.

The initial network will be **MobileNetV2**, used as a transfer-learning baseline.

The choice is based mainly on the requirements of the overall project. The model needs to be reasonably lightweight, straightforward to train in MATLAB, and suitable for later GPU-based inference. A larger network can be investigated later if the baseline does not provide sufficient performance.

The AI stage is therefore initially defined as:

**Enhanced Ultrasound Image → Preprocessing → MobileNetV2 → Class Prediction + Confidence**

---

## 2. Initial AI Task

The first AI task will be image classification.

The model will receive an ultrasound image and assign it to one of the classes defined by the selected dataset.

Classification is being chosen as the starting point because it allows the AI pipeline to be developed without immediately introducing the additional complexity of object-detection bounding boxes or pixel-level segmentation masks.

Once the classification pipeline is working, more advanced tasks can be considered if they provide a useful improvement to the overall project.

Possible future extensions include:

* Region-of-interest detection
* Lesion detection
* Anatomical structure segmentation
* Multi-class classification
* Frame-level temporal analysis

These are not required for the first working version.

The initial objective is to get one complete AI inference path working reliably inside the larger imaging pipeline.

---

## 3. Baseline Network

The first network to be evaluated will be **MobileNetV2**.

MobileNetV2 is a convolutional neural network designed with relatively low computational requirements compared with many larger image-classification networks.

This makes it a reasonable starting point for this project because the final application is intended to operate as a real-time pipeline rather than as an offline classification experiment.

The model will initially be used through transfer learning.

Instead of training the complete network from random initialization, the existing feature-extraction layers will be reused and the final classification portion will be adapted to the selected ultrasound dataset.

The initial approach will therefore be:

**Pretrained MobileNetV2 → Replace Classification Layer → Train on Ultrasound Dataset → Validate → Test**

The actual model configuration will be documented after implementation rather than being assumed in advance.

---

## 4. Why MobileNetV2

The network was selected as a baseline for practical reasons.

The project has a limited GPU memory budget and ultimately needs to run as part of a streaming application. Using a relatively compact network gives us a better starting point for measuring the complete pipeline.

MobileNetV2 also provides a useful reference point for later comparisons.

If the baseline performs adequately, it may remain the final model.

If its classification performance is not sufficient, another network can be evaluated and compared against it.

Possible alternatives can include other lightweight convolutional networks supported by the available MATLAB toolchain.

The project will therefore avoid choosing a large model simply because it produces better offline results.

The final network should provide a reasonable balance between:

* Classification performance
* Model size
* GPU memory usage
* Inference time
* Deployment complexity
* Overall pipeline latency

---

## 5. Dataset

The AI dataset will be selected based on the final classification task.

A possible starting point is the **Breast Ultrasound Images Dataset (BUSI)** or another suitable publicly available ultrasound dataset.

The dataset must provide enough labelled images to support training and evaluation.

Before training begins, the dataset will be inspected to determine:

* Number of classes
* Number of images per class
* Image dimensions
* Image format
* Label quality
* Class imbalance
* Duplicate or near-duplicate images
* Availability of appropriate train/test separation

The final dataset choice will be recorded in the project documentation once it has been confirmed.

The dataset used for AI training does not necessarily have to be the same dataset used for raw RF reconstruction.

This distinction is important.

The reconstruction part of the project requires raw signal or channel data, while the AI classification task requires labelled ultrasound images.

If the available raw dataset does not contain suitable labels for the chosen AI task, a separate labelled ultrasound image dataset can be used for AI development.

The relationship between the two datasets will be documented clearly.

---

## 6. Dataset Preparation

The dataset will be divided into training, validation, and test sets.

The test data must remain separate from the training process so that the final model can be evaluated on images that were not used during training.

Care will also be taken to avoid data leakage.

For example, if multiple images originate from the same patient or examination, those images should not be randomly distributed across training and testing in a way that allows information from the same subject to appear in both sets.

The exact split will depend on the structure of the selected dataset.

The preprocessing pipeline will also be kept consistent between training and inference.

Typical preprocessing may include:

* Image resizing
* Conversion to the required number of channels
* Intensity normalization
* Dataset-specific preprocessing
* Data augmentation during training

The final preprocessing operations will be documented after the dataset has been inspected.

---

## 7. Transfer Learning

MobileNetV2 will initially be used through transfer learning.

The pretrained network provides a set of feature-extraction layers that can be adapted to the ultrasound classification problem.

The final classification layers will be replaced or modified so that the network produces the number of classes required by the selected dataset.

Training will then be performed using the training portion of the dataset.

Validation data will be used during training to monitor model behavior and help identify problems such as overfitting.

The model that performs best according to the selected validation criteria will then be evaluated using the independent test set.

---

## 8. Training

The first training implementation will be developed in MATLAB using the available Deep Learning Toolbox functionality.

The initial training process will establish a working baseline rather than attempting to optimize every possible training parameter immediately.

Parameters that may be investigated include:

* Learning rate
* Batch size
* Number of epochs
* Optimizer
* Data augmentation
* Layer freezing
* Input image size

The exact values will be determined experimentally.

Training results will be recorded so that different experiments can be compared rather than relying only on the final model.

Where useful, training progress and validation performance will be saved as part of the project results.

---

## 9. Evaluation

The AI model will be evaluated using the test dataset after training has been completed.

For the initial classification task, the main evaluation measures will include:

* Accuracy
* Precision
* Recall
* F1-score
* Confusion matrix

The appropriate metrics may change depending on the number of classes and their distribution.

Accuracy alone will not be treated as sufficient if the dataset is significantly imbalanced.

The confusion matrix will also be useful for identifying which classes are being confused by the model.

The purpose of this stage is to establish whether the model is performing the intended classification task before it is integrated into the real-time pipeline.

---

## 10. Enhanced Image as AI Input

The intended pipeline places image enhancement before AI inference.

The complete processing relationship is therefore:

**Raw RF Data → Image Reconstruction → Image Enhancement → AI Preprocessing → MobileNetV2**

This creates an important dependency between the image-processing and AI stages.

The enhanced image must be converted into the representation expected by the neural network.

The AI preprocessing stage may therefore include operations such as resizing and normalization.

The same preprocessing must be applied during both training and deployment.

The effect of enhancement on classification performance will also be investigated.

A useful experiment will be to compare the AI model using:

**Reconstructed Image → AI**

against:

**Reconstructed Image → Enhancement → AI**

This will allow us to determine whether the enhancement stage actually helps the downstream AI task.

---

## 11. AI Inference

Once the model has been trained, the next step will be to measure inference performance separately from training.

Training performance is not the main concern for the final application.

The important measurement is how long the trained model takes to process an individual image during deployment.

The inference stage will therefore be tested using representative images and measured on the available NVIDIA GPU.

The following information will be recorded:

* Model input size
* Model size
* GPU memory usage where practical
* Inference time
* Inference throughput
* Predicted class
* Prediction confidence

The measurements will later be compared with the timing of the reconstruction and enhancement stages.

---

## 12. GPU Execution

The final system is intended to execute computationally intensive processing on NVIDIA GPU hardware.

The AI model will therefore be evaluated using GPU-based inference.

The exact deployment mechanism will be selected after the MATLAB model has been trained and tested.

The important requirement is that the AI inference implementation can operate efficiently with the rest of the GPU-based pipeline.

Unnecessary CPU-GPU transfers should be avoided where possible because moving data between memory spaces can introduce additional latency.

This becomes especially important once the model is placed inside the Holoscan streaming pipeline.

---

## 13. AI Model Optimization

If the initial MobileNetV2 implementation is too slow or consumes more resources than practical for the target application, optimization will be investigated.

Possible approaches include:

* Reducing the input resolution
* Freezing additional layers
* Simplifying the model
* Selecting a smaller network
* Using supported inference optimizations
* Reducing unnecessary data transfers

The objective will not be to optimize the model before establishing a baseline.

The sequence will be:

**Working Model → Measure Performance → Identify Problem → Optimize → Measure Again**

This provides a clear basis for deciding whether an optimization actually improves the system.

---

## 14. Integration With Holoscan

After the AI model has been validated independently, it will be integrated into the Holoscan application.

The intended dataflow will be:

**Data Source → Reconstruction → Enhancement → AI Inference → Visualization**

The AI operator will receive the processed image from the enhancement stage.

It will perform the required preprocessing and inference and return the classification result.

The visualization stage can then display the processed ultrasound image together with the predicted class and confidence.

The AI component should not depend on the source of the ultrasound data.

The input may eventually come from:

* Simulated data
* Prerecorded data
* Real acquisition hardware

The AI operator should receive the same expected image representation regardless of the upstream source.

---

## 15. AI and Real-Time Performance

The AI model will be evaluated as part of the complete pipeline rather than only as an independent benchmark.

For example, a model may have excellent classification accuracy but still be unsuitable if its inference time creates an unacceptable bottleneck.

The final performance evaluation will therefore consider:

**Reconstruction Time + Enhancement Time + AI Inference Time + Other Pipeline Overhead**

The actual end-to-end latency will be measured once the complete Holoscan pipeline is operational.

The AI stage will be considered successful only if it provides useful classification performance without preventing the overall application from meeting its target processing rate.

---

## 16. Baseline and Future Models

MobileNetV2 will be treated as the initial baseline rather than an irreversible final choice.

Once the baseline has been implemented and measured, another lightweight model can be evaluated if there is a clear reason to do so.

Any alternative model should be compared using the same general evaluation procedure.

The comparison should consider both:

**AI Performance**

and

**System Performance**

For example:

| Metric         | MobileNetV2 | Alternative |
| -------------- | ----------: | ----------: |
| Test Accuracy  |  To measure |  To measure |
| F1-score       |  To measure |  To measure |
| Model Size     |  To measure |  To measure |
| Inference Time |  To measure |  To measure |
| GPU Memory     |  To measure |  To measure |
| Pipeline FPS   |  To measure |  To measure |

This prevents the model-selection process from being based only on classification accuracy.

---

## 17. Medical Use Limitation

The AI output in this project is intended only as an engineering demonstration.

The classification result must not be presented as a clinical diagnosis or as a replacement for medical professionals.

A model trained on a public dataset is not sufficient to establish clinical effectiveness.

Clinical deployment would require substantially more validation, appropriate patient data, expert review, regulatory assessment, and other requirements that are outside the scope of this project.

The AI stage is being developed to demonstrate how machine-learning inference can be incorporated into a real-time medical-imaging processing system.

---

## 18. Development Sequence

The AI implementation will follow this progression:

**Define Classification Task**

↓

**Select and Inspect Dataset**

↓

**Prepare Training / Validation / Test Data**

↓

**Set Up MobileNetV2 Transfer Learning**

↓

**Train Baseline Model**

↓

**Evaluate Test Performance**

↓

**Measure GPU Inference**

↓

**Compare Enhanced vs. Non-Enhanced Input**

↓

**Optimize if Required**

↓

**Integrate With Holoscan**

↓

**Measure End-to-End Performance**

This keeps the AI development separate from the final streaming integration until the model has been shown to work independently.

---

## 19. Initial AI Baseline

The initial AI baseline for the project is therefore:

| Item                    | Initial Choice                         |
| ----------------------- | -------------------------------------- |
| AI task                 | Ultrasound image classification        |
| Baseline network        | MobileNetV2                            |
| Training approach       | Transfer learning                      |
| Development environment | MATLAB                                 |
| Toolbox                 | Deep Learning Toolbox                  |
| Input                   | Enhanced ultrasound image              |
| Output                  | Class + confidence                     |
| Inference target        | NVIDIA GPU                             |
| Final integration       | NVIDIA Holoscan                        |
| Dataset                 | To be confirmed                        |
| Final model             | To be determined from measured results |

The dataset and final model configuration will only be considered fixed after the relevant experiments have been completed.

The purpose of this baseline is to give the project a concrete starting point without making claims about performance that have not yet been measured.
