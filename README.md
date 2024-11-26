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

## Challenge
- Only connects to wifi when PSRAM is disabled, then face detection does not work.  
- thermal throttling (face detection stops working)
