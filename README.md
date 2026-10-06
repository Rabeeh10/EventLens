# EventLens

### Augmented Reality Based Event Navigation System

EventLens is a Flutter-based mobile application designed to improve navigation
and discovery at large events. The application combines augmented reality,
Firebase, QR/marker-based stall identification, and machine learning to help
users discover event stalls and receive personalized recommendations.

---

## 📱 Overview

Navigating large events can be difficult when users need to locate specific
stalls, activities, or services.

EventLens provides a mobile solution that allows users to:

- Explore available events
- View event and stall information
- Identify stalls using markers/QR codes
- Access AR-based navigation features
- Receive personalized event recommendations
- View crowd-density predictions
- Access information with offline support
- Allow event organizers to manage event and stall information

---

## ✨ Key Features

### 👤 User Features

- User registration and authentication
- Event discovery and search
- Event details and stall information
- QR/marker-based stall identification
- AR-based event navigation
- Personalized recommendations
- Crowd-density information
- Offline data access
- Event and user activity tracking

### 🏢 Admin Features

- Admin authentication
- Create and manage events
- Add and manage event stalls
- Update event information
- Manage stall information
- Upload event and stall images
- Monitor event-related data

### 🤖 Machine Learning

EventLens includes machine-learning components for:

**Event Recommendation**
- Predicts whether a user is likely to be interested in an event
- Random Forest classification model
- Uses user engagement and event-related features

**Crowd Density Prediction**
- Predicts crowd density levels
- Decision Tree classification model
- Classes: Low, Medium, High

---

## 🥽 Augmented Reality

The AR component is designed to connect physical event markers with
digital event information.

### Basic workflow

```text
User opens EventLens
        ↓
Selects an event
        ↓
Scans an event/stall marker
        ↓
Marker is identified
        ↓
Stall information is retrieved
        ↓
AR interface displays relevant information
