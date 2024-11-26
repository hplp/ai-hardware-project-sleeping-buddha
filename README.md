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

## Install Android studio IDE
Install Android Studio and load necessary packages from https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json

## Installation of antenna
At the bottom left corner of the XIAO ESP32S3's front side, you'll find a dedicated "WiFi/BT Antenna Connector." To enhance the WiFi and Bluetooth signal, simply take the antenna provided in the package and attach it to this connector.

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
