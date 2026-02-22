# Sample Dataset for EventLens ML Model

This directory contains sample data for testing the event recommendation ML pipeline.

## Dataset Overview

- **users.csv**: 12 users with various activity levels
- **events.csv**: 8 events across different categories
- **stalls.csv**: 15 stalls distributed across events
- **user_activity.csv**: 76 interaction records (exceeds 50 row requirement)

## Data Statistics

### User Activity Distribution
- Total interactions: 76 rows
- AR sessions: 12 complete sessions
- Marker scans: 24 scans
- Overlay views: 24 views
- Event registrations: 12 registrations
- Event views only: 4 views

### Event Popularity
- e001 (Tech Summit): 8 users, 56 interactions (most popular)
- e004 (Career Expo): 2 users, 8 interactions
- e003 (Food Fair): 2 users, 8 interactions
- e005 (Art Showcase): 1 user, 4 interactions
- e002 (Music Festival): 2 users, 4 interactions

### User Engagement Levels
- **High engagement**: u003 (21 interactions, 3 events)
- **Medium engagement**: u001, u008, u012 (6-7 interactions each)
- **Low engagement**: u004, u007, u010, u011 (2-4 interactions)

## Data Characteristics

### Realistic User Patterns
1. **AR session flow**: session_start → marker_scanned → overlay_view → session_end
2. **Registration timing**: Users typically register before attending events
3. **Browsing behavior**: Some users view events without registering
4. **Session duration**: Ranges from 15-45 minutes (900-2700 seconds)
5. **Overlay engagement**: View durations from 30-300 seconds

### Event Categories
- Conference (Tech Innovation Summit)
- Concert (Music Festival)
- Food & Drink (Local Food Fair)
- Career Fair (University Career Expo)
- Arts & Culture (Art & Design Showcase)
- Sports (Marathon Charity Run)
- Gaming (Gaming Convention)
- Business (Networking Night)

### Stall Categories
- Technology (3 stalls)
- Food & Beverage (5 stalls)
- Merchandise (2 stalls)
- Career (2 stalls)
- Exhibition (1 stall)
- Information (1 stall)
- Performance (1 stall)

## Usage Instructions

### 1. Load Data in Python
```python
import pandas as pd

users_df = pd.read_csv('users.csv')
events_df = pd.read_csv('events.csv')
stalls_df = pd.read_csv('stalls.csv')
activity_df = pd.read_csv('user_activity.csv')

print(f"Users: {len(users_df)} rows")
print(f"Events: {len(events_df)} rows")
print(f"Stalls: {len(stalls_df)} rows")
print(f"Activities: {len(activity_df)} rows")
```

### 2. Load Data in Google Colab
```python
from google.colab import drive
drive.mount('/content/drive')

import pandas as pd

base_path = '/content/drive/MyDrive/EventLens_Data/sample_dataset/'
users_df = pd.read_csv(base_path + 'users.csv')
events_df = pd.read_csv(base_path + 'events.csv')
stalls_df = pd.read_csv(base_path + 'stalls.csv')
activity_df = pd.read_csv(base_path + 'user_activity.csv')
```

### 3. Create Interaction Matrix
```python
# Filter registration and strong engagement signals
strong_interactions = activity_df[
    activity_df['activity_type'].isin(['event_registered', 'ar_session_end', 'overlay_view'])
].copy()

# Create interaction matrix
interaction_matrix = strong_interactions.pivot_table(
    index='user_id',
    columns='event_id',
    values='activity_type',
    aggfunc='count',
    fill_value=0
)

print("Interaction Matrix Shape:", interaction_matrix.shape)
print(interaction_matrix)
```

## Expected Model Performance

With this dataset size (76 interactions, 12 users, 8 events):

### Training Recommendations
- **Split**: 60/40 train/test (due to small size)
- **Validation**: Use K-fold cross-validation (k=3 or k=5)
- **Metrics focus**: Precision@K, Recall@K (K=2 or K=3)

### Anticipated Results
- **Baseline (popularity)**: Precision@3 ≈ 0.25-0.35
- **Collaborative filtering**: Precision@3 ≈ 0.35-0.45
- **Hybrid model**: Precision@3 ≈ 0.40-0.55

### Limitations
⚠️ **Note**: This is a **sample dataset** for testing the ML pipeline. For production:
- Target: 500+ users
- Target: 50+ events
- Target: 5,000+ interactions
- Includes multiple interaction types per user
- Spans 3-6 months of activity

## Data Quality Checks

Run these checks before training:

```python
# 1. Check for missing values
print("Missing values:")
print(activity_df.isnull().sum())

# 2. Verify referential integrity
user_ids = set(users_df['user_id'])
event_ids = set(events_df['event_id'])
stall_ids = set(stalls_df['stall_id'])

activity_users = set(activity_df['user_id'])
activity_events = set(activity_df['event_id'])
activity_stalls = set(activity_df['stall_id'].dropna())

print(f"All users exist: {activity_users.issubset(user_ids)}")
print(f"All events exist: {activity_events.issubset(event_ids)}")
print(f"All stalls exist: {activity_stalls.issubset(stall_ids)}")

# 3. Check timestamp ordering
activity_df['timestamp'] = pd.to_datetime(activity_df['timestamp'])
print(f"Date range: {activity_df['timestamp'].min()} to {activity_df['timestamp'].max()}")
```

## Next Steps

1. ✅ Upload these CSV files to Google Drive
2. ✅ Open the EventLens ML Colab notebook
3. ✅ Mount Drive and load the data
4. ✅ Run data quality checks
5. ✅ Create interaction matrix
6. ✅ Train baseline models
7. ✅ Evaluate and iterate

---

**Dataset Version**: 1.0  
**Created**: February 22, 2026  
**Last Updated**: February 22, 2026  
**Total Rows**: 76 activity records (exceeds 50 requirement)
