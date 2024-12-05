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
1. Face Detection Models:
(a) HumanFaceDetectMSR01
Description:
A one-stage or two-stage face detection model that identifies facial regions in an image.
Used to detect bounding boxes around faces in an input frame.
Implementation:
The HumanFaceDetectMSR01 model operates with configurable parameters for thresholds (e.g., confidence levels) and scales.
Two-stage detection is optional, where:
Stage 1: Rough detection of face candidates.
Stage 2: Refines the results using keypoints (more accurate but slower).
(b) HumanFaceDetectMNP01
Description:
A complementary model for the second stage of detection, refining the face bounding boxes.
Particularly useful when more precision is required after the first detection stage.
Implementation:
The HumanFaceDetectMNP01 refines detections from MSR01 in two-stage mode by evaluating the regions and landmarks identified.
Key Features:
These models handle face detection in both RGB565 and BGR888 pixel formats.
Detection is performed using iterative inference over image data stored in buffers.
Results are visualized by drawing bounding boxes and optional landmarks over detected faces.
2. Face Recognition Models:
(a) FaceRecognition112V1S16 (Quantized Float16 Model)
Description:
A face recognition model using FP16 (16-bit floating-point) precision for weights and activations.
Provides higher accuracy but results in slower processing and larger firmware.
Implementation:
Used when QUANT_TYPE is set to 1.
Operates on tensors extracted from detected face regions and matches them against enrolled identities.
(b) FaceRecognition112V1S8 (Quantized Int8 Model)
Description:
A more compact model using INT8 (8-bit integer) quantization.
Offers faster execution and reduced firmware size at the cost of slightly lower accuracy.
Implementation:
Default model when QUANT_TYPE is set to 0.
Performs face matching using compact and efficient INT8 tensors.
Recognition Process:
Input:
Tensor data (RGB/BGR pixel arrays) extracted from the detected face bounding boxes.
Facial landmarks are optionally used for alignment or normalization.
Enrollment:
Users can save face embeddings (enroll_id) to assign unique IDs.
Embeddings are stored in flash memory for persistent recognition.
Matching:
Each detected face is compared against enrolled embeddings using similarity metrics (e.g., cosine similarity).
Results are classified as a recognized ID or "Intruder Alert!" if no match is found.
Implementation Details:
Integration:
Models are implemented as part of the ESP-IDF framework with pre-trained weights and inference logic embedded in the firmware.
Performance Optimization:
PSRAM Usage: The ESP32S3's external PSRAM is used for larger memory requirements.
Two-Stage Detection (Optional): Improves detection accuracy at the cost of speed.
Visualization:
Recognized faces are marked with green boxes and intruders with red boxes.
Status messages (e.g., ID or "Intruder Alert!") are overlayed on the video feed using graphics primitives.
Scalability:
The system supports multiple face enrollments (FACE_ID_SAVE_NUMBER is configurable).
The processing scales for varying image sizes and pixel formats.
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


## Challenge
- Only connects to wifi when PSRAM is disabled, then face detection does not work.  
- thermal throttling (face detection stops working)

video [link](https://myuva-my.sharepoint.com/personal/gsq2at_virginia_edu/_layouts/15/stream.aspx?id=%2Fpersonal%2Fgsq2at%5Fvirginia%5Fedu%2FDocuments%2FDesktop%2FUVA%20courses%2F2024%2FFall%2FAI%20HArdware%2FProject%2FIMG%5F3417%2EMOV&referrer=StreamWebApp%2EWeb&referrerScenario=AddressBarCopied%2Eview%2E7faa3b63%2D0501%2D4320%2D9763%2D31454684271f)
