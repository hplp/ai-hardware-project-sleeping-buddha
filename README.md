# AI_Hardware_Project

Team Name: sleeping-buddha

## Team Members:
Afsara Benazir,
Shafat Shahnewaz,
Samit Hasan

## Project Title: 
FaceSafe: On-Device Authentication & Gesture Recognition

## Project Description:
Recognize individual face for authentication and gestures for action identification.

## Key Objectives:
- Privacy: On-device execution would prevent leakage of facial features and repeated gestures
- Real-time Processing: Ensuring that face and gesture recognition runs efficiently and can provide real-time feedback without noticeable delay.
- Robustness: Make the system robust to variations in lighting, angles, facial expressions, and hand positioning, ensuring reliable performance across different environments.

## Usability
- Classroom attendance: streamline classroom access control and automate the attendance-taking process.
- Smart Home features: user performs a predefined gesture, such as swiping their hand up to increase room lighting or making a circle motion to play music

## Technology Stack:
Seeed Studio XIAO ESP32S3, PyTorch, Python

## Expected Outcomes:
Develop a fully functional prototype that can recognize individual faces for authentication and specific gestures for action identification.

## Timeline:
(Provide a rough timeline or milestones for the project)
- Week 1: Initial Setup and Requirements Analysis
- Week 2: Model Development
- Week 3, 4: System Integration and On-Device Deployment
- Week 5: Evaluation, documentation

# First Milestone

## Install Android studio IDE on PC
Install Android Studio and load necessary packages from https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json

## Installation of antenna
At the bottom left corner of the XIAO ESP32S3's front side, you'll find a dedicated "WiFi/BT Antenna Connector." To enhance the WiFi and Bluetooth signal, simply take the antenna provided in the package and attach it to this connector.

![image](https://github.com/user-attachments/assets/925f50e1-b3d8-4fcb-90c7-05f494f58ce5)

## Prepare the microSD card
XIAO ESP32S3 supports microSD cards up to 32GB, we use a 4GB microSD card that will be used later. We format the microSD card to FAT32 format before using the microSD card. After formatting, we insert the microSD card into the microSD card slot.

## Camera slot GPIO mapping
<img width="531" alt="Screenshot 2024-11-26 at 3 05 29 PM" src="https://github.com/user-attachments/assets/f7d712dd-4d18-494f-88db-eb00b6ad4bde">

## Enabling PSRAM
The PSRAM on the ESP32S3 (Pseudo Static Random Access Memory) supplements the ESP32S3 chip by providing additional memory space, expanding the system's available RAM. In the ESP32S3 system, PSRAM serves several key purposes:

1. **Expanding RAM capacity**: The built-in RAM of the ESP32S3 is limited, particularly for memory-intensive applications such as image or audio processing. By utilizing PSRAM, the system's RAM capacity can be increased to meet the demands of these applications.

2. **Enhancing memory access**: Although PSRAM is external and slower than internal RAM, it can still be used as cache or temporary memory, helping to improve data processing and memory access speeds.

3. **Providing large storage buffers**: For tasks requiring substantial buffer space, like network or audio buffering, PSRAM offers sufficient storage to prevent memory shortages.

We must enable the PSRAM function in the Arduino IDE to ensure proper operation of the camera.

<img width="598" alt="Screenshot 2024-11-26 at 3 07 27 PM" src="https://github.com/user-attachments/assets/21a7d2a5-9c2f-42dd-a8df-5e8136b5c390">


## Parameters

Function declarations
``` python
void startCameraServer();
void setupLedFlash(int pin);
void setupCamera();
bool initWiFi();
```

Static variables to set up camera
``` python
void setupCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_UXGA;
  config.pixel_format = PIXFORMAT_JPEG;  // for streaming
  //config.pixel_format = PIXFORMAT_RGB565; // for face detection/recognition
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  // if PSRAM IC present, init with UXGA resolution and higher JPEG quality
  if (config.pixel_format == PIXFORMAT_JPEG) {
    if (psramFound()) {
      config.jpeg_quality = 10;
      config.fb_count = 2;
      config.grab_mode = CAMERA_GRAB_LATEST;
    } else {
      // Limit the frame size when PSRAM is not available
      config.frame_size = FRAMESIZE_SVGA;
      config.fb_location = CAMERA_FB_IN_DRAM;
    }
  } else {
    // Best option for face detection/recognition
    config.frame_size = FRAMESIZE_240X240;
#if CONFIG_IDF_TARGET_ESP32S3
    config.fb_count = 2;
#endif
  }
```
Connect to WiFi
``` python
bool initWiFi() {
  WiFi.mode(WIFI_STA);  // Set WiFi to station mode
  WiFi.begin(ssid, password);
  WiFi.setSleep(false);

  Serial.print("Connecting to WiFi");
  
  int attempts = 0;
  const int maxAttempts = 20;  // 10 seconds total
  
  while (WiFi.status() != WL_CONNECTED && attempts < maxAttempts) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  Serial.println();

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Failed to connect to WiFi!");
    return false;
  }

  Serial.println("WiFi connected");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  return true;
}
```

## Face recognition

``` python
#if CONFIG_ESP_FACE_RECOGNITION_ENABLED
static int run_face_recognition(fb_data_t *fb, std::list<dl::detect::result_t> *results) {
  std::vector<int> landmarks = results->front().keypoint;
  int id = -1;

  Tensor<uint8_t> tensor;
  tensor.set_element((uint8_t *)fb->data).set_shape({fb->height, fb->width, 3}).set_auto_free(false);

  int enrolled_count = recognizer.get_enrolled_id_num();

  if (enrolled_count < FACE_ID_SAVE_NUMBER && is_enrolling) {
    id = recognizer.enroll_id(tensor, landmarks, "", true);
    log_i("Enrolled ID: %d", id);
    rgb_printf(fb, FACE_COLOR_CYAN, "ID[%u]", id);
  }

  face_info_t recognize = recognizer.recognize(tensor, landmarks);
  if (recognize.id >= 0) {
    rgb_printf(fb, FACE_COLOR_GREEN, "ID[%u]: %.2f", recognize.id, recognize.similarity);
  } else {
    rgb_print(fb, FACE_COLOR_RED, "Intruder Alert!");
  }
  return recognize.id;
}
#endif
```
## Face Detecion and Recognition Model

**Face Detection and Recognition Models**

*Overview**
This project employs efficient face detection and recognition models optimized for embedded systems. Using the ESP32S3 platform, these models provide real-time performance with minimal resource consumption.

*Face Detection Models*

*(a) HumanFaceDetectMSR01*
- Description:  
  A one-stage or two-stage model for detecting facial regions in an image.
- Features:  
  - Detects bounding boxes around faces.  
  - Operates with configurable thresholds (e.g., confidence levels) and scales.
- Two-Stage Detection (Optional):  
  - Stage 1: Performs rough detection of face candidates.  
  - Stage 2: Refines results using keypoints for higher accuracy (slower but more precise).
- Pixel Formats:  
  Supports both *RGB565* and *BGR888* formats.


*(b) HumanFaceDetectMNP01*
- Description:  
  A complementary model for refining bounding boxes from the MSR01 model.
- Features:  
  - Enhances precision by evaluating regions and landmarks identified by MSR01.  
  - Particularly useful in two-stage detection mode.
- Output:  
  Bounding boxes and optional landmarks are drawn on detected faces.


*Face Recognition Models*

*(a) FaceRecognition112V1S16*
- Type:  
  Quantized Float16 Model.
- Features:  
  - Uses FP16 (16-bit floating-point) precision for weights and activations.  
  - Offers higher accuracy at the cost of slower processing and larger firmware size.
- Use Case:  
  Enabled when `QUANT_TYPE = 1`.

*(b) FaceRecognition112V1S8*
- Type:  
  Quantized INT8 Model.
- Features:  
  - Compact and efficient model using INT8 quantization.  
  - Faster execution and reduced firmware size with slightly lower accuracy.
- Default Setting:  
  Enabled when `QUANT_TYPE = 0`.

*Recognition Process*

Steps:
1. Input:  
   - Tensor data (RGB/BGR pixel arrays) extracted from detected face bounding boxes.  
   - Facial landmarks are optionally used for alignment or normalization.

2. Enrollment:  
   - Users can save face embeddings (`enroll_id`) to assign unique IDs.  
   - Embeddings are stored in flash memory for persistent recognition.

3. Matching:  
   - Each detected face is compared against stored embeddings using **similarity metrics** (e.g., cosine similarity).  
   - Results are classified as:
     - Recognized ID.
     - "Intruder Alert!" for unrecognized faces.

Implementation Details

Integration:
- Models are part of the **ESP-IDF framework**, with pre-trained weights and inference logic embedded in firmware.

Performance Optimization
1. PSRAM Usage:  
   - External PSRAM on the ESP32S3 is utilized for larger memory requirements.
2. Two-Stage Detection:  
   - Improves accuracy but increases processing time.
3. Visualization:  
   - Recognized faces are marked with **green boxes**.  
   - Intruders are flagged with **red boxes**.  
   - Status messages like IDs or "Intruder Alert!" are overlayed on the video feed using graphics primitives.

Scalability
- The system supports multiple face enrollments.
- Configurable enrollment limit (`FACE_ID_SAVE_NUMBER`).
- Scales efficiently for varying image sizes and pixel formats.

This combination of lightweight detection and quantized recognition models makes the implementation well-suited for resource-constrained devices like the ESP32S3. 


We used FaceRecognition112V1S8. A little overview of the model is given below:

The FaceRecognition112V1S8 is a lightweight face recognition model optimized for resource-constrained environments. It uses INT8 quantization, which reduces the model's size and computation requirements by representing weights and activations as 8-bit integers instead of 32-bit floats. This makes it ideal for embedded systems like ESP32S3.
Model Details:
1.	Input Parameters:
         Input Size:A fixed-size RGB image of 112x112 pixels, as the name suggests.
	       Input Channels:	3 (for RGB).
         Data Type: Quantized INT8 tensor.
         Preprocessing: Input pixel values are normalized and optionally aligned using facial landmarks for consistency.
2.	Output Parameters:
         Embedding Size: A 128-dimensional vector representing the facial features.
         Data Type: Quantized INT8 tensor.
         Usage: The embedding is compared to stored embeddings using similarity metrics like cosine similarity to identify the face.
3.	Architecture:
         Based on MobileNet-like architecture with adaptations for face recognition.
         Contains depthwise separable convolutions to reduce computational complexity while maintaining accuracy.
         Includes batch normalization and ReLU6 activations for stable training and inference.
   	     Fully connected layers at the end compress the features into a 128-dimensional embedding space.
4.	Quantization:
         Weights and activations are quantized to INT8 after training, reducing precision but saving memory and computation.
         Quantization-aware training ensures minimal accuracy loss during this process.
5.	Model Size:
         The quantized INT8 model is typically 1–2 MB, depending on the exact implementation.
         This compact size makes it ideal for devices with limited storage and memory, like the ESP32S3 with PSRAM.

![image](https://github.com/hplp/ai-hardware-project-sleeping-buddha/blob/main/IMG_3502.JPG)

The FaceRecognition112V1S8 model is a quantized deep neural network that employs convolutional layers and depthwise separable convolutions to extract and encode facial features into a compact, 128-dimensional embedding. Here's a technical breakdown of its operation:

1. Preprocessing:
         The input image is resized to 112x112x3 (width, height, RGB channels) and normalized for numerical stability.
         Optionally, facial landmarks are detected for alignment, ensuring consistency in the facial pose.
2. Feature Extraction (Backbone Network):
         Architecture: Based on a MobileNet-like backbone, optimized for computational efficiency using depthwise separable convolutions:
         Depthwise Convolution: Applies a single convolutional filter per channel to reduce parameter count.
         Pointwise Convolution: Combines the outputs of depthwise convolutions across channels.
T        These convolutions significantly reduce the number of operations compared to standard convolutions, making the model suitable for low-resource environments.
         Activation Functions: Uses ReLU6 (Rectified Linear Unit capped at 6) for non-linearity, helping prevent overflow during quantization.
         Batch Normalization: Each convolutional layer is followed by batch normalization to stabilize training and inference, especially after quantization.
         Quantization: Weights and activations are quantized to INT8, where values are represented in 8-bit integers. This reduces memory usage and speeds up inference on 
                       devices with integer-optimized hardware.
3. Bottleneck Layers:
         The network includes bottleneck blocks, which compress intermediate feature maps into lower-dimensional representations:
         These blocks are parameter-efficient and help maintain model accuracy despite quantization.
4. Embedding Generation (Fully Connected Layer):
        The final output is a 128-dimensional feature vector (embedding) that represents the input face.
        The embedding is compact and discriminative, ensuring faces with similar features (e.g., the same person) produce similar vectors, while distinct faces yield 
        dissimilar vectors.
5. Postprocessing (Face Recognition):
        During enrollment, the embeddings of new faces are saved as templates.
        During recognition:The embedding of the current face is computed. A cosine similarity or Euclidean distance is calculated between the current embedding and stored 
        embeddings. A threshold determines whether the face is recognized or classified as unknown.

Below is an example showing the recognised face with 96.724% probabilty of face associated to the registered ID.

![image](https://github.com/hplp/ai-hardware-project-sleeping-buddha/blob/main/Screenshot%202024-12-05%20225536.svg)

## **Flow Chart**
The algorithm can be visualized by the flow chart drawn below-

![image](https://github.com/hplp/ai-hardware-project-sleeping-buddha/blob/main/first_milestone/flowchart_v2.svg)

**Gesture Recognition**
We experiment with two frameworks for model development and deployment.
1. SenseCraft AI framework: We implement a simple 'Rock paper scissors' hand image recognition
2. We identify direction pointer: Left/right hand recognition
Benefit: More compatible and easily deployable
Con: Model architecture (swift YOLO) is fixed and difficult to customize.
2. Espressif
Benefit: Model can be customized as needed.
Con: Less compatible, Challenges in deploying, doesn't take streaming data

Swift YOLO model with < 2MB size
<img width="453" alt="image" src="https://github.com/user-attachments/assets/6afda347-39ed-46cf-b341-e30ef7ed2107">

Demo: 'Rock paper scissors': [link](https://myuva-my.sharepoint.com/personal/hys4qm_virginia_edu/_layouts/15/stream.aspx?id=%2Fpersonal%2Fhys4qm%5Fvirginia%5Fedu%2FDocuments%2FFall%2724%2Fai%5Fhardware%5Fgesture%5Frecognition%5F2%2Emov&referrer=StreamWebApp%2EWeb&referrerScenario=AddressBarCopied%2Eview%2E5ff3be2a%2D4b20%2D4dbc%2Db2d3%2D21adbbbbd64a)

Demo: Direction pointer

![image](https://github.com/user-attachments/assets/d3a18055-ca50-4394-a25e-a208f49c9444)


Our train data: 86 image samples

Latency: 700-800ms


**Espressif** project directory, inference is below, challenge: flashing to device

<img width="626" alt="image" src="https://github.com/user-attachments/assets/d1c7becb-023e-4745-87c5-39233dcc7801">


## **Challenges**

During the development of the project, we encountered several challenges that required careful debugging and optimization:

- **Setting up WiFi**:  
  Ensuring stable and consistent connectivity was challenging during the initial setup phase.

- **Enabling Streaming Data**:  
  Configuring the system for reliable data streaming required adjustments in communication protocols.

- **Configuring GPIO Ports**:  
  Mapping and testing GPIO ports for seamless interaction with hardware components.

- **Model Deployment**:  
  - Overcoming **memory constraints** due to limited onboard resources.
  - Resolving issues with **serial port connections** during deployment.

- **Choosing Suitable Models**:  
  - Experimented with different models to balance accuracy, latency, and resource requirements.
  - Required multiple iterations and bootloading to resolve compatibility issues.

- **Thermal Throttling**:  
  Addressed overheating problems by integrating a heat sink to maintain stable performance during extended use.

### **Resolution**
Through persistent debugging, hardware adjustments, and model optimization, these challenges were systematically resolved, ensuring smooth system performance and deployment.


Demo video [link](https://myuva-my.sharepoint.com/personal/gsq2at_virginia_edu/_layouts/15/stream.aspx?id=%2Fpersonal%2Fgsq2at%5Fvirginia%5Fedu%2FDocuments%2FDesktop%2FUVA%20courses%2F2024%2FFall%2FAI%20HArdware%2FProject%2FIMG%5F3417%2EMOV&referrer=StreamWebApp%2EWeb&referrerScenario=AddressBarCopied%2Eview%2E7faa3b63%2D0501%2D4320%2D9763%2D31454684271f)
