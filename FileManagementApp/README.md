# File Management Application - Task Assignment

## Project Overview
This project aims to create a file management application with features such as file operations (copy, move, delete, rename), secure vault encryption, task scheduling, file health checks, insights dashboard, and more. The application will have both a GUI interface and a browser-based HTML Application (HTA) interface.

---

## 1. Project Management  
**Assigned to: Simone (Project Manager)**

- [ ] Coordinate tasks among team members.
- [ ] Ensure deadlines are met.
- [ ] Oversee integration of all components.
- [ ] Conduct regular check-ins and resolve blockers.
- [ ] Maintain project documentation (README, progress reports).

---

## 2. Programming (Back-End)  
**Leader: Daniel**  
**Members: Edriane, Kevin, Gerald, Michael**

### 2.1 Core Modules (in `modules/`)

#### **File Operations (`FileOperations.ps1`)**  
- **Assigned to: Daniel**
    - [ ] Implement functions for basic file operations:
        - `Copy-File`: Copy files from one location to another.
        - `Move-File`: Move files to a different directory.
        - `Delete-File`: Delete files.
        - `Rename-File`: Rename files or folders.
    - [ ] Ensure each operation includes error handling (e.g., file not found, permissions).
    - **Contents of File**:
        - Functions for each file operation.
        - Error handling logic.
        - Logging actions for file operations.

#### **File Insights Dashboard (`InsightsModule.ps1`)**  
- **Assigned to: Edriane**
    - [ ] Create functions for:
        - Usage statistics (most accessed files, large files).
        - File heatmap visualization (identify which files/folders are accessed most).
    - **Contents of File**:
        - Functions for collecting file usage data.
        - Code to generate file heatmap.
        - Reporting features (e.g., displaying insights in the console or GUI).

#### **Secure Vault (`SecureVaultModule.ps1`)**  
- **Assigned to: Kevin**
    - [ ] Implement encryption and decryption functionality for sensitive files.
    - [ ] Create password protection for encrypted files.
    - **Contents of File**:
        - Functions for encrypting/decrypting files using PowerShell's cryptography libraries.
        - Methods for password protection.
        - Logging actions related to encryption.

#### **Task Scheduler (`TaskScheduler.ps1`)**  
- **Assigned to: Gerald**
    - [ ] Develop scheduling functionality for file operations (e.g., moving, deleting, or backing up files).
    - [ ] Allow users to schedule tasks at specific times or intervals.
    - **Contents of File**:
        - Functions for creating, managing, and executing scheduled tasks.
        - Scheduling options for file operations.
        - Error handling for scheduling conflicts.

#### **File Health Check (`FileHealthCheck.ps1`)**  
- **Assigned to: Michael**
    - [ ] Implement a feature to detect and handle corrupted files or duplicate files.
    - [ ] Create a system for repairing or removing corrupted files.
    - **Contents of File**:
        - Functions to scan files for corruption or duplicates.
        - Code for repair or deletion of problematic files.
        - Reporting features for file integrity status.

---

## 3. Programming (Front-End)  
**Leader: Daniel**  
**Members: Edriane, Kevin, Gerald, Michael**

### 3.1 Windows GUI Interface (`FileManagerGUI.ps1`)  
- **Assigned to: Kirby**
    - [ ] Design and implement the PowerShell GUI interface.
    - [ ] Create interactive elements (buttons, menus, file viewers).
    - [ ] Integrate with the back-end functions.
    - **Contents of File**:
        - PowerShell script for GUI layout.
        - UI components like buttons, labels, and input fields.
        - Code to connect UI elements with back-end functions.

### 3.2 Browser-Based Interface (`FileManager.hta`)  
- **Assigned to: Kirby**
    - [ ] Create a browser-based HTML Application (HTA).
    - [ ] Design the layout using HTML and style it with CSS.
    - [ ] Integrate JavaScript for dynamic file operations (copy, delete, etc.).
    - **Contents of File**:
        - HTML structure for the app (layout, form elements, buttons).
        - CSS for styling the app's appearance.
        - JavaScript to handle dynamic actions (e.g., triggering file operations from the UI).

### 3.3 Main Entry Script (`FileManager.ps1`)  
- **Assigned to: Edriane**
    - [ ] Create the main entry point for launching the GUI or HTA interface.
    - [ ] Ensure it detects the preferred interface (PowerShell GUI or HTA).
    - **Contents of File**:
        - Code to check which interface to launch (PowerShell GUI or HTA).
        - Basic setup for starting the app.

---

## 4. Configuration  
**Assigned to: Kevin**  
- [ ] Set up configuration files for the application:
    - `AppConfig.json`: General app settings (e.g., theme preferences, default paths).
    - `SecureVaultConfig.json`: Secure Vault settings (e.g., encryption algorithms, password policies).
- **Contents of Files**:
    - **AppConfig.json**:
        - JSON object containing application settings (paths, theme, etc.).
    - **SecureVaultConfig.json**:
        - JSON object with encryption settings and secure vault configurations.

---

## 5. Logs  
**Assigned to: Michael**  
- [ ] Set up logging functionality to capture user actions and errors:
    - `ActivityLog.txt`: Record user actions (file accesses, modifications).
    - `ErrorLog.txt`: Capture errors, such as failed file operations.
- **Contents of Files**:
    - **ActivityLog.txt**:
        - Text-based log with user actions and timestamps.
    - **ErrorLog.txt**:
        - Log entries for errors encountered during app usage.

---

## 6. UI and UX Design  
**Assigned to: Kirby**

- **What should be inside**:
    - Wireframes and mockups for the UI (both for PowerShell GUI and browser-based HTA).
    - Style guide including colors, fonts, button styles, and other design elements.
    - Suggestions for UI/UX improvements based on user flow and interactions.
- [ ] Design the wireframes and mockups for both interfaces.
- [ ] Ensure a consistent, intuitive user experience across both GUI and browser interfaces.

---

## 7. Documentation  
**Leader: Marc**  
**Members: Ivan**

### 7.1 Technical Documentation  
- **Assigned to: Marc**
    - [ ] Write detailed technical documentation for the app’s back-end modules.
    - [ ] Include explanations of file operations, encryption methods, task scheduling, etc.
- **Contents of File**:
    - Overview of each module.
    - Code documentation with comments for clarity.
    - Setup and installation instructions.

### 7.2 User Documentation  
- **Assigned to: Ivan**
    - [ ] Write user manual for the application.
    - [ ] Include step-by-step instructions for file operations, using the Secure Vault, scheduling tasks, etc.
    - [ ] Add troubleshooting steps for common issues.
- **Contents of File**:
    - Instructions for installing and running the app.
    - Detailed guides for using all features.
    - FAQs and troubleshooting tips.

---

## 8. Integration and Testing  
**Leader: Daniel**  
**Support: Simone**

- [ ] Integrate all back-end modules with both the GUI and browser interfaces.
- [ ] Conduct comprehensive testing of all features (file operations, encryption, health checks, etc.).
- [ ] Perform User Acceptance Testing (UAT) and address any feedback.

---

## 9. Finalization

- [ ] Finalize the application for deployment.
- [ ] Polish UI/UX based on testing feedback.
- [ ] Prepare the project for release.

---

### Additional Notes:
- The `README.md` file will include a general overview of the project, instructions for setup and usage, and any other relevant information.
- All files in `logs/` should be updated dynamically by the app during use to track actions and errors.

