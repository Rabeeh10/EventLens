"""
Generate large user_activity.csv with 2000+ realistic activity records
This script creates proper AR session flows with varied user engagement patterns
"""

import csv
import random
from datetime import datetime, timedelta
import json

# Seed for reproducibility
random.seed(42)

# Load existing data to reference
users = [f'u{i:03d}' for i in range(1, 101)]  # 100 users
events = [f'e{i:03d}' for i in range(1, 31)]  # 30 events
# AR-enabled events (75% of events)
ar_events = [f'e{i:03d}' for i in [1,2,3,4,5,7,9,10,11,13,15,16,17,18,20,21,23,25,26,27,29]]

# Event to stalls mapping
event_stalls = {
    'e001': ['s001', 's002', 's003', 's004', 's005', 's006'],
    'e002': ['s007', 's008', 's009', 's010', 's011'],
    'e003': ['s012', 's013', 's014', 's015', 's016'],
    'e004': ['s017', 's018', 's019', 's020', 's021', 's022'],
    'e005': ['s023', 's024', 's025', 's026'],
    'e007': ['s027', 's028', 's029', 's030', 's031'],
    'e009': ['s032', 's033', 's034', 's035'],
    'e010': ['s036', 's037', 's038', 's039'],
    'e011': ['s040', 's041', 's042', 's043'],
    'e013': ['s044', 's045', 's046', 's047'],
    'e015': ['s048', 's049', 's050', 's051'],
    'e016': ['s052', 's053', 's054', 's055'],
    'e017': ['s056', 's057', 's058', 's059'],
    'e018': ['s060', 's061', 's062', 's063'],
    'e020': ['s064', 's065', 's066', 's067'],
    'e021': ['s068', 's069', 's070', 's071'],
    'e023': ['s072', 's073', 's074', 's075'],
    'e025': ['s076', 's077', 's078', 's079'],
    'e026': ['s080', 's081', 's082', 's083'],
    'e027': ['s084', 's085', 's086', 's087'],
    'e029': ['s088', 's089', 's090', 's091'],
}

# Event dates (approximated based on events.csv)
event_dates = {
    'e001': datetime(2026, 2, 15, 9, 0),
    'e002': datetime(2026, 6, 20, 14, 0),
    'e003': datetime(2026, 3, 10, 11, 0),
    'e004': datetime(2026, 4, 5, 10, 0),
    'e005': datetime(2026, 5, 12, 10, 0),
    'e007': datetime(2026, 8, 15, 10, 0),
    'e009': datetime(2026, 3, 18, 9, 0),
    'e010': datetime(2026, 7, 25, 16, 0),
    'e011': datetime(2026, 4, 22, 17, 0),
    'e013': datetime(2026, 6, 15, 10, 0),
    'e015': datetime(2026, 5, 5, 9, 0),
    'e016': datetime(2026, 3, 28, 10, 0),
    'e017': datetime(2026, 6, 10, 10, 0),
    'e018': datetime(2026, 3, 25, 10, 0),
    'e020': datetime(2026, 5, 30, 15, 0),
    'e021': datetime(2026, 6, 3, 9, 0),
    'e023': datetime(2026, 4, 8, 18, 0),
    'e025': datetime(2026, 7, 5, 11, 0),
    'e026': datetime(2026, 6, 28, 11, 0),
    'e027': datetime(2026, 7, 20, 9, 0),
    'e029': datetime(2026, 7, 12, 10, 0),
}

def generate_activities():
    activities = []
    activity_id = 1
    target_count = 2000
    
    # Track user-event combinations to create realistic patterns
    user_event_interactions = {}
    
    while activity_id <= target_count:
        # Select random user (with weight towards more active users)
        user_weights = [1 + (i // 10) for i in range(100)]
        user = random.choices(users, weights=user_weights)[0]
        
        # Select AR-enabled event
        event = random.choice(ar_events)
        
        if event not in event_dates or event not in event_stalls:
            continue
            
        event_date = event_dates[event]
        
        # Check if we have enough capacity left
        if activity_id + 10 > target_count:
            # Just add simple event views
            browse_date = event_date - timedelta(days=random.randint(1, 20))
            activities.append({
                'activity_id': f'a{activity_id:04d}',
                'user_id': user,
                'event_id': event,
                'stall_id': '',
                'activity_type': 'event_viewed',
                'timestamp': browse_date.isoformat() + 'Z',
                'duration_seconds': 0,
                'metadata': '{}'
            })
            activity_id += 1
            continue
        
        # Create engagement pattern for this user-event combo
        will_register = random.random() < 0.4
        will_attend_ar = random.random() < 0.5 if will_register else random.random() < 0.15
        
        # Event registration
        if will_register:
            reg_date = event_date - timedelta(days=random.randint(1, 14), hours=random.randint(8, 20))
            activities.append({
                'activity_id': f'a{activity_id:04d}',
                'user_id': user,
                'event_id': event,
                'stall_id': '',
                'activity_type': 'event_registered',
                'timestamp': reg_date.isoformat() + 'Z',
                'duration_seconds': 0,
                'metadata': '{}'
            })
            activity_id += 1
        elif random.random() < 0.3:
            # Just browsing
            browse_date = event_date - timedelta(days=random.randint(1, 30), hours=random.randint(8, 22))
            activities.append({
                'activity_id': f'a{activity_id:04d}',
                'user_id': user,
                'event_id': event,
                'stall_id': '',
                'activity_type': 'event_viewed',
                'timestamp': browse_date.isoformat() + 'Z',
                'duration_seconds': 0,
                'metadata': '{}'
            })
            activity_id += 1
        
        # AR session
        if will_attend_ar and activity_id + 8 <= target_count:
            session_start = event_date + timedelta(hours=random.uniform(0, 6))
            
            # AR session start
            activities.append({
                'activity_id': f'a{activity_id:04d}',
                'user_id': user,
                'event_id': event,
                'stall_id': '',
                'activity_type': 'ar_session_start',
                'timestamp': session_start.isoformat() + 'Z',
                'duration_seconds': 0,
                'metadata': '{}'
            })
            activity_id += 1
            
            # Scan markers (1-4 markers)
            available_stalls = event_stalls[event]
            num_scans = min(random.randint(1, 4), len(available_stalls))
            scanned_stalls = random.sample(available_stalls, num_scans)
            
            time_offset = timedelta(minutes=random.randint(2, 5))
            markers_scanned = 0
            overlays_viewed = 0
            
            for stall in scanned_stalls:
                # Marker scanned
                scan_time = session_start + time_offset
                activities.append({
                    'activity_id': f'a{activity_id:04d}',
                    'user_id': user,
                    'event_id': event,
                    'stall_id': stall,
                    'activity_type': 'marker_scanned',
                    'timestamp': scan_time.isoformat() + 'Z',
                    'duration_seconds': 0,
                    'metadata': json.dumps({'marker_id': f'marker_{stall[1:]}'})
                })
                activity_id += 1
                markers_scanned += 1
                
                # Overlay view
                view_duration = random.randint(20, 240)
                view_time = scan_time + timedelta(seconds=5)
                activities.append({
                    'activity_id': f'a{activity_id:04d}',
                    'user_id': user,
                    'event_id': event,
                    'stall_id': stall,
                    'activity_type': 'overlay_view',
                    'timestamp': view_time.isoformat() + 'Z',
                    'duration_seconds': view_duration,
                    'metadata': json.dumps({'stall_name': f'Stall {stall}'})
                })
                activity_id += 1
                overlays_viewed += 1
                
                time_offset += timedelta(minutes=random.randint(2, 7))
            
            # AR session end
            session_duration = int(time_offset.total_seconds())
            session_end = session_start + time_offset
            activities.append({
                'activity_id': f'a{activity_id:04d}',
                'user_id': user,
                'event_id': event,
                'stall_id': '',
                'activity_type': 'ar_session_end',
                'timestamp': session_end.isoformat() + 'Z',
                'duration_seconds': session_duration,
                'metadata': json.dumps({
                    'markers_scanned': markers_scanned,
                    'overlays_viewed': overlays_viewed
                })
            })
            activity_id += 1
    
    return activities

def save_to_csv(filename, data, fieldnames):
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    print(f"✅ Created {filename} with {len(data)} rows")

print("Generating large user activity dataset...")
print("Target: 2000+ activity records\n")

activities = generate_activities()

save_to_csv('ml_data/large_dataset/user_activity.csv', activities,
            ['activity_id', 'user_id', 'event_id', '

stall_id', 
             'activity_type', 'timestamp', 'duration_seconds', 'metadata'])

print(f"\n✅ Dataset generation complete!")
print(f"📊 Total activities: {len(activities)}")
print(f"📁 File saved to: ml_data/large_dataset/user_activity.csv")
