# SmartSight  
**AI-Powered Assistive Device for the Visually Impaired and Elderly**

SmartSight is a wearable AI-driven assistive solution designed to empower visually impaired and elderly individuals. This Flutter-based mobile application connects with a clip-on hardware device and provides intelligent assistance through voice-based interaction.

> This repository contains only the `lib` folder, `assets`, and `pubspec.yaml` file for the Flutter frontend. Clone and integrate into your existing Flutter project to run the app.

---

## Features

### 1. Scene Analysis  
Capture the surroundings using the clip-on ESP32 camera and receive voice-based descriptions powered by the **BLIP model**.

### 2. Navigation  
Voice-activated navigation from one location to another using **Google Maps** and identify nearby objects using **YOLOv8**.

### 3. Face Recognition  
Recognizes known individuals using **Haar Cascades** and **DeepFace**.

### 4. Text Recognition (OCR Suite)  
- **Printed Text:** Detected using **Google ML Kit**  
- **Handwritten Text:** Recognized via **Meta's LLaMA**  
- **SmartRead:** Uses **Gemini + ML Kit** for context-aware reading

### 5. Social Media Integration  
Provides real-time Instagram updates from selected profiles to keep users socially informed.

---

## Hardware

![1000171054_402980d9f5786ae904b37f559180c922-3_22_2025, 4_18_01 PM (1)1](https://github.com/user-attachments/assets/c3c78a3d-ba77-4544-a8e5-4854fc1849b7)


The SmartSight system includes a clip-on hardware module made up of:
- **ESP32 Camera**
- **LiPo Battery**


This device can be clipped onto spectacles or clothing, acting as an always-available smart assistant.

---

## User Interface

- **Dark-themed UI** with black background, white/blue text for readability
- Optimized for **Android screen reader** and accessibility services
- **Completely voice-controlled**



![Screenshot 2025-05-16 023810](https://github.com/user-attachments/assets/a50ca202-5349-4110-b581-84eb913b68aa)


![Screenshot 2025-05-16 023842](https://github.com/user-attachments/assets/965fd41b-a215-466f-b85b-e1f280c0f788)


![Screenshot 2025-05-16 024431](https://github.com/user-attachments/assets/0d16b771-42ff-42a4-85b2-6cde5a224d67)




