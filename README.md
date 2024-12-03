# **AxisTrack**  
**A Robot to Measure Distance on a Single Axis**  

AxisTrack is a robotic system built on a Cortex-M3 microcontroller (Texas Instruments Evalbot) that calculates the distance traveled along a single axis with precision. The project leverages assembly language to implement efficient motor control and distance measurement using hardware timers and interrupts.

## **Features**

### **Precise Distance Calculation:**
- The robot uses encoder feedback and interrupt-based distance measurement.
- Distance is calculated in real-time and displayed using LEDs (units and tens are represented by blinking patterns).

### **Motor Control:**
- Control includes start/stop, forward/reverse motion, and turning.
- Speed adjustment and direction inversion are implemented using PWM signals.

### **Timer Utilization:**
- A hardware timer (SysTick) is used for precise timing and distance calculations.
- Supports timer reset, freeze, and unfreeze operations to ensure flexible measurements.

---

## **File Descriptions**

### **1. RK_PriseEnMain_Moteurs.s**  
This file focuses on the motor control logic and interrupt-based operations, including:
- Configuring GPIO ports and PWM for motor drivers.
- Enabling/disabling motors and setting their direction (forward, reverse, stop).
- Implementing real-time control loops that:
  - Adjust motor behavior based on sensor inputs (bumpers, switches).
  - Measure distance traveled using encoder signals and update the timer.

**Key Functionalities:**
- Handles dynamic robot movement and navigation.
- Uses LED blinking to display distance in units and tens.
- Freezes and unfreezes timers during specific events to maintain accurate measurements.

### **2. RK_Config_Moteur.s**  
This file primarily focuses on the hardware initialization and configuration, including:
- Setting up PWM for motor control (adjusting speed and phase signals).
- Initializing GPIO pins for motor driver inputs (direction, enable signals).
- Configuring timers (SysTick and General Purpose Timers) to generate precise timing events.
- Preparing the system for efficient motor and distance measurement.

**Key Functionalities:**
- Initializes all necessary peripherals for motor control and distance measurement.
- Defines constants and macros for hardware register addresses, ensuring clean and modular code.
- Prepares the robot to run smoothly under the main control loop implemented in `RK_PriseEnMain_Moteurs.s`.

---

## **How It Works**

### **Setup and Initialization:**
- Motors and GPIO pins are initialized via `RK_Config_Moteur.s`.
- Timers and interrupts are configured for precise distance measurement.

### **Motor Control and Measurement:**
- The main control logic in `RK_PriseEnMain_Moteurs.s` runs in a loop:
  - Controls motor movement based on sensor feedback.
  - Measures the traveled distance and calculates it in centimeters.
  - Displays the result using LEDs.

### **Timers and LEDs:**
- Timers count encoder ticks to calculate distance.
- LED patterns represent the traveled distance (e.g., blinking for tens and units).

---

## **Requirements**

### **Hardware:**
- Texas Instruments Evalbot with Cortex-M3.
- Motors with encoder feedback.
- LEDs and switches for interaction.

### **Software:**
- ARM assembly language support.
- Keil MDK or similar tools for programming the Cortex-M3.

---

## **Usage**
1. Load `RK_Config_Moteur.s` to configure the hardware and peripherals.
2. Run `RK_PriseEnMain_Moteurs.s` to control the robot and calculate distance.
3. Observe the robot’s motion and distance output through LEDs.
