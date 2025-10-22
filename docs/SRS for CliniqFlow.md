# **Software Requirements Specification for CliniqFlow**

Prepared by:

* Pranjal Mathew Lobo (Reg. No: 230905051\)  
* Arnav Yash Chandra (Reg. No: 230905268\)

Date: August 21, 2025

# **1\. Introduction**

## **1.1 Purpose**

The purpose of this document is to provide a detailed specification for the CliniqFlow software. This system is intended to be a lightweight, high-performance mobile application for dental clinic management, designed to centralize patient records, appointments, and visit notes.

## **1.2 Project Scope**

The software will provide doctors and clinic staff with a centralized platform to manage core clinic operations. Key functionalities will include a dashboard for daily schedules, a comprehensive appointment calendar, a searchable patient directory with rich profiles, and a detailed Case Sheet system for each visit. The Case Sheet will include sections for diagnosis, treatment plans, and secure file attachments. The system is designed for single-clinic practices and will prioritize offline performance and reliability.

## **1.3 Environmental Characteristics**

The software will be a mobile-first application. It is required to run on iOS, iPadOS, and Android devices. The backend will utilize a suitable database, with a thin data layer to abstract the backend for future portability.

# **2\. Overall Description**

## **2.1 Product Perspective**

CliniqFlow is a self-contained product designed to replace fragmented paper-based or digital record-keeping systems in dental clinics. It aims to solve issues like slow patient lookup, inconsistent notes, and scheduling conflicts by digitizing the entire patient record process.

## **2.2 Product Features**

The major features of the CliniqFlow system are:

* Dashboard: An overview of the day's schedule and upcoming appointments.  
* Patient Records Management: A centralized and searchable directory of comprehensive patient profiles.  
* Case Sheet Management: A complete digital record for each patient visit, including diagnosis, treatment plans, and prescriptions.  
* Calendar & Appointments: A visual calendar for scheduling and managing appointments.

## **2.3 User Classes and Characteristics**

The user classes for this system are Dentists and Clinic Staff. These users are responsible for all data entry and management within the application. They are expected to be proficient with modern mobile applications but require a clean, intuitive, and fast interface for use during busy clinical hours. The application is not intended for patient use.

## **2.4 Operating Environment**

The application must run on standard mobile and tablet devices operating on iOS, iPadOS, and Android. It will require an internet connection for initial setup and data synchronization, but core features must be available offline.

2.5 Design & Implementation Constraints

* The backend must use a database for data storage.  
* The system must support offline persistence for core data.  
* The development process will follow the Incremental Development Model.  
* The UI must be clean and component-based for reusability and maintainability.

## **2.6 User Documentation**

The final product will be delivered with a user manual and in-app help features to guide users through the software's functionalities.

# **3\. Functional Requirements**

The functionalities are organized into logical groups based on the system's core modules.

## **1\. Dashboard**

* **R.1.1: Display Next Appointment**  
  * Description: The dashboard shall display a summary card for the next immediate appointment of the day.  
  * Input: Current date and time.  
  * Output: Display of patient name, time, and purpose for the next appointment.  
* **R.1.2: Display Today's Schedule**  
  * Description: The dashboard shall display a summarized list of all appointments scheduled for the current day.  
  * Input: Current date.  
  * Output: A scrollable list of today's appointments, showing the patient name and time.

## **2\. Patient Records Management**

* **R.2.1: Create Patient Profile**  
  * **Description**: Allows staff to create a new patient profile. The profile shall capture comprehensive patient information equivalent to the physical "Dental Record Sheet."  
  * **Input**: Comprehensive patient data as listed in sub-requirements.  
  * **Output**: A new patient profile is created with a unique ID (UID) and displayed; confirmation message.  
  * **R.2.1.1: Capture Personal & Contact Information**: Name, UID, Date, Birth Date, Age, Sex, Address, Occupation, Email, Phone numbers (Residential/Office).  
  * **R.2.1.2: Capture Emergency Contact**: Name, Relation, Phone numbers (Mobile/Office).  
  * **R.2.1.3: Capture Medical History**: Referred by, General Medical History, Allergies, Current Medications, and Habits (Smoking, Alcohol, Pan & Tobacco Chewing).  
  * **R.2.1.4: Capture Past Health History**: A dedicated section to record the patient's detailed past health history, including previous conditions, surgeries, and treatments.  
* **R.2.2: Search Patient Directory**  
  * Description: Provides a search functionality to quickly find a patient in the directory.  
  * Input: A search query (e.g., patient name, phone number, UID).  
  * Output: A list of patient profiles matching the search query.  
* **R.2.3: View/Edit Patient Profile**  
  * Description: Allows the doctor/staff to view and edit the details of an existing patient profile.  
  * Input: Selection of a patient profile; updated patient information.  
  * Output: Display of the full patient profile; confirmation of saved changes.

## **3\. Case Sheet Management**

* **R.3.1: Create New Case Sheet**  
  * Description: For each visit, the doctor/staff can create a new dated case sheet linked to a patient's profile.  
  * Input: Patient selection, Dr. Incharge, Date.  
  * Output: A new, empty case sheet is created and associated with the patient.  
* **R.3.2: Record Chief Complaint**  
  * Description: Allows entry of the patient's primary complaint for the visit.  
  * Input: Free text entry.  
  * Output: The complaint is saved to the current case sheet.  
* **R.3.3: Record Provisional Diagnosis**  
  * Description: Allows entry of the doctor's provisional diagnosis.  
  * Input: Free text entry.  
  * Output: The diagnosis is saved to the current case sheet.  
* **R.3.4: Record Treatment Plan**  
  * Description: Allows entry of the planned course of treatment.  
  * Input: Free text entry.  
  * Output: The treatment plan is saved to the current case sheet.  
* **R.3.5: Record Consent**  
  * Description: Provides a digital version of the consent statement for the patient/guardian to acknowledge.  
  * Input: Digital signature or checkbox confirmation.  
  * Output: Consent status is recorded in the case sheet.  
* **R.3.6: Manage Case Sheet Attachments**  
  * Description: Allows uploading and associating files (X-rays, PDFs, photos) with a specific case sheet.  
  * Input: A file to be uploaded from the device.  
  * Output: The file is attached to the case sheet.

## **4\. Calendar & Appointments**

* **R.4.1: View Calendar**  
  * Description: Provides a visual calendar to view appointments.  
  * Input: User selection of a date.  
  * Output: Display of all scheduled appointments for the selected date.  
* **R.4.2: Create Appointment**  
  * **Description**: Allows the doctor/staff to schedule a new appointment for a patient on a specific date and time.  
  * **Input**: Patient selection, date, time, duration (15/30/60-min slots), and purpose.  
  * **Output**: The new appointment appears on the calendar; confirmation message.  
* **R.4.3: Reschedule/Cancel Appointment**  
  * **Description**: Allows the doctor/staff to modify the time of or cancel an existing appointment.  
  * **Input**: Selection of an existing appointment; new date/time or cancellation confirmation.  
  * **Output**: The calendar is updated to reflect the change; confirmation message.

## **5\. Prescription Management**

* **R.5.1: Create Prescription**  
  * **Description**: Allows the doctor to create a digital prescription for a patient.  
  * **Input**: Patient selection, drug name, dosage, frequency, duration.  
  * **Output**: A generated digital prescription that can be printed or shared.

# **4\. External Interface Requirements**

## **4.1 User Interfaces**

* The UI will be designed for touch-based interaction on mobile and tablet devices.  
* It will feature a clean, minimalist aesthetic to ensure ease of use and fast data entry.  
* The system shall provide a digital interface to capture all fields present in the physical Dental Record Sheet.

## **4.2 Hardware Interfaces**

The software will run on standard consumer mobile and tablet hardware (iOS/Android) and will utilize the device's camera for photo attachments and internal storage for offline data persistence.

## **4.3 Software Interfaces**

The application will interface with a backend database for data synchronization and storage. All database interactions will be handled through an abstracted data service layer.

## **4.4 Communication Interfaces**

The application should use standard HTTPS protocols for secure communication between the mobile client and the backend server for data synchronization.

# **5\. Other Non-functional Requirements**

## **5.1 Performance Requirements**

* The application must be high-performance with fast patient lookups and minimal loading times.  
* It must be tolerant of offline conditions, allowing core functionalities to work without an active internet connection.  
* The UI must be responsive, using techniques like memoized lists and image caching to ensure smooth scrolling and interaction.

## **5.2 Security Requirements**

* All patient data, especially attachments like X-rays and PDFs, must be stored and transmitted securely.  
* Backend security rules must be implemented to prevent unauthorized access to patient records.

## **5.3 Software Quality Attributes**

* Reliability: The system must be reliable, with clear error states and empty states to guide the user.  
* Usability: The interface must be intuitive and easy to navigate for busy medical professionals performing data entry.  
* Maintainability: The codebase must be modular, with reusable components and a clear separation between the UI and data layers to facilitate future updates.

# **Data Flow Diagrams**

## **DFD 0 (Context Diagram)**

![][image1]

## **DFD 1**

![][image2]

## **DFD 2**

### **0.1 Manage Patient Records**

![][image3]

### **0.2 Manage Appointments**

![][image4]

### **0.3 Manage Case Sheets**

![][image5]

### **0.4 Manage Prescriptions**

![][image6]

---

# **Data Dictionary for CliniqFlow**

**Appointment\_Change\_Data:** Existing\_Appointment\_Selection \+ \[New\_Date \+ New\_Time, Cancellation\_Confirmation\]

**Appointment\_Details:** Patient\_Selection \+ Date \+ Time \+ Duration \+ Purpose

**Appointment\_Summary:** Patient\_Name \+ Time

**Confirmation:** Confirmation\_Message

**Daily\_Schedule:** {Appointment\_Summary}\*

**Generated\_Prescription:** Patient\_Name \+ Date \+ {Prescription\_Item}\*

**Matching\_Profiles:** {Patient\_Profile\_Summary}\*

**New\_Patient\_Data:** Personal\_Info \+ Contact\_Info \+ Emergency\_Contact \+ Medical\_History \+ Past\_Health\_History

**Patient\_Info:** New\_Patient\_Data

**Prescription\_Details:** Patient\_Selection \+ {Prescription\_Item}\*

**Profile\_Confirmation:** Confirmation \+ UID

**Query:** \[Search\_Query, Date\_Selection\]

**Schedule:** Daily\_Schedule

**Search\_Query:** \[Patient\_Name, Phone\_Number, UID\]

**Visit\_Data:** Patient\_Selection \+ Dr\_Incharge \+ Date \+ Chief\_Complaint \+ Provisional\_Diagnosis \+ Treatment\_Plan \+ Consent \+ (File\_to\_Upload)

**D1: Patient\_Records:** {Patient\_Profile}\*

**D2: Appointments\_Schedule:** {Appointment}\*

**D3: Case\_Sheets:** {Case\_Sheet}\*

**Address:** Street\_Address \+ City \+ State \+ Postal\_Code

**Appointment:** Patient\_UID \+ Date \+ Time \+ Duration \+ Purpose

**Case\_Sheet:** Patient\_UID \+ Dr\_Incharge \+ Date \+ Chief\_Complaint \+ Provisional\_Diagnosis \+ Treatment\_Plan \+ Consent \+ {Attachment}\*

**Contact\_Info:** Address \+ Occupation \+ Email \+ Phone\_Numbers

**Emergency\_Contact:** Contact\_Name \+ Relation \+ Emergency\_Phone\_Numbers

**Medical\_History:** Referred\_By \+ General\_Medical\_History \+ Allergies \+ Current\_Medications \+ Habits

**Patient\_Profile:** Personal\_Info \+ Contact\_Info \+ Emergency\_Contact \+ Medical\_History \+ Past\_Health\_History

**Patient\_Profile\_Summary:** Patient\_Name \+ UID \+ Phone\_Number

**Personal\_Info:** Patient\_Name \+ UID \+ Registration\_Date \+ Birth\_Date \+ Age \+ Sex

**Phone\_Numbers:** Residential\_Phone \+ (Office\_Phone)

**Prescription\_Item:** Drug\_Name \+ Dosage \+ Frequency \+ Duration

**Age:** integer

**UID:** integer

**Phone\_Number:** integer

**Residential\_Phone:** integer

**Office\_Phone:** integer

**Allergies:** string

**Chief\_Complaint:** string

**Confirmation\_Message:** string

**Current\_Medications:** string

**Dosage:** string

**Dr\_Incharge:** string

**Drug\_Name:** string

**Email:** string

**Frequency:** string

**General\_Medical\_History:** string

**Habits:** string

**Past\_Health\_History:** string

**Patient\_Name:** string

**Provisional\_Diagnosis:** string

**Purpose:** string

**Referred\_By:** string

**Relation:** string

**Treatment\_Plan:** string

**Attachment:** file

**File\_to\_Upload:** file

**Birth\_Date:** datetime

**Date:** datetime

**Registration\_Date:** datetime

**Time:** datetime

**Consent:** boolean

**Duration:** \[15-min, 30-min, 60-min\]

**Sex:** \[Male, Female, Other\]
