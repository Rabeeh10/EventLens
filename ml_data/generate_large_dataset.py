"""
Generate large realistic dataset for EventLens ML model training
Creates 100 users, 30 events, 100 stalls, and 5000 user activity records
"""

import csv
import random
from datetime import datetime, timedelta
import json

# Seed for reproducibility
random.seed(42)

# Configuration
NUM_USERS = 100
NUM_EVENTS = 30
NUM_STALLS = 100
NUM_ACTIVITIES = 5000

# Data for realistic generation
FIRST_NAMES = [
    "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
    "William", "Barbara", "David", "Elizabeth", "Richard", "Susan", "Joseph", "Jessica",
    "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa",
    "Matthew", "Betty", "Anthony", "Margaret", "Mark", "Sandra", "Donald", "Ashley",
    "Steven", "Kimberly", "Paul", "Emily", "Andrew", "Donna", "Joshua", "Michelle",
    "Kenneth", "Dorothy", "Kevin", "Carol", "Brian", "Amanda", "George", "Melissa",
    "Edward", "Deborah", "Ronald", "Stephanie", "Timothy", "Rebecca", "Jason", "Sharon",
    "Jeffrey", "Laura", "Ryan", "Cynthia", "Jacob", "Kathleen", "Gary", "Amy",
    "Nicholas", "Shirley", "Eric", "Angela", "Jonathan", "Helen", "Stephen", "Anna",
    "Larry", "Brenda", "Justin", "Pamela", "Scott", "Nicole", "Brandon", "Emma",
    "Benjamin", "Samantha", "Samuel", "Katherine", "Frank", "Christine", "Gregory", "Debra",
    "Raymond", "Rachel", "Alexander", "Catherine", "Patrick", "Carolyn", "Jack", "Janet",
    "Dennis", "Ruth", "Jerry", "Maria", "Tyler", "Heather"
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas",
    "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White",
    "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker", "Young",
    "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
    "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
    "Carter", "Roberts", "Gomez", "Phillips", "Evans", "Turner", "Diaz", "Parker",
    "Cruz", "Edwards", "Collins", "Reyes", "Stewart", "Morris", "Morales", "Murphy",
    "Cook", "Rogers", "Gutierrez", "Ortiz", "Morgan", "Cooper", "Peterson", "Bailey",
    "Reed", "Kelly", "Howard", "Ramos", "Kim", "Cox", "Ward", "Richardson"
]

EVENT_TEMPLATES = [
    {"name": "Tech Innovation Summit {}", "category": "Conference", "description": "Annual technology conference showcasing latest innovations", "capacity": 500},
    {"name": "Summer Music Festival {}", "category": "Concert", "description": "Outdoor music festival featuring top artists", "capacity": 5000},
    {"name": "Local Food Fair {}", "category": "Food & Drink", "description": "Celebration of local cuisine and culinary arts", "capacity": 1000},
    {"name": "Career Expo {}", "category": "Career Fair", "description": "Connect with top employers and recruiters", "capacity": 2000},
    {"name": "Art & Design Showcase {}", "category": "Arts & Culture", "description": "Contemporary art exhibition and workshops", "capacity": 800},
    {"name": "Marathon Charity Run {}", "category": "Sports", "description": "Annual charity marathon supporting local causes", "capacity": 3000},
    {"name": "Gaming Convention {}", "category": "Gaming", "description": "Esports tournaments and game developer showcases", "capacity": 1500},
    {"name": "Business Networking Night {}", "category": "Business", "description": "Professional networking for entrepreneurs", "capacity": 300},
    {"name": "Green Energy Summit {}", "category": "Conference", "description": "Sustainable energy solutions and innovations", "capacity": 600},
    {"name": "Jazz & Blues Festival {}", "category": "Concert", "description": "Classic jazz and blues performances", "capacity": 2000},
    {"name": "Wine Tasting Event {}", "category": "Food & Drink", "description": "Premium wine selection from local vineyards", "capacity": 400},
    {"name": "Startup Pitch Competition {}", "category": "Business", "description": "Emerging startups compete for funding", "capacity": 500},
    {"name": "Photography Exhibition {}", "category": "Arts & Culture", "description": "International photography showcase", "capacity": 700},
    {"name": "Yoga & Wellness Retreat {}", "category": "Sports", "description": "Mind and body wellness activities", "capacity": 200},
    {"name": "Blockchain Conference {}", "category": "Conference", "description": "Cryptocurrency and blockchain technology", "capacity": 800},
]

STALL_TEMPLATES = [
    {"name": "Microsoft Booth", "category": "Technology", "description": "Latest Azure and AI solutions"},
    {"name": "Google Developer Zone", "category": "Technology", "description": "Android and Cloud Platform demos"},
    {"name": "Apple Experience Center", "category": "Technology", "description": "Latest iOS and Mac products"},
    {"name": "Amazon Recruiting", "category": "Career", "description": "Software engineering opportunities"},
    {"name": "Goldman Sachs", "category": "Career", "description": "Finance and tech positions"},
    {"name": "Coffee Corner", "category": "Food & Beverage", "description": "Premium coffee and snacks"},
    {"name": "Food Truck Plaza", "category": "Food & Beverage", "description": "Gourmet food trucks"},
    {"name": "Event Merchandise", "category": "Merchandise", "description": "Official event swag"},
    {"name": "Artisan Bakery", "category": "Food & Beverage", "description": "Fresh baked goods"},
    {"name": "Local Cheese Stand", "category": "Food & Beverage", "description": "Regional cheese varieties"},
    {"name": "Main Stage", "category": "Performance", "description": "Live performances and concerts"},
    {"name": "Workshop Area", "category": "Information", "description": "Hands-on learning sessions"},
    {"name": "VIP Lounge", "category": "Hospitality", "description": "Exclusive networking space"},
    {"name": "Photo Booth", "category": "Entertainment", "description": "Professional photo opportunities"},
    {"name": "Information Desk", "category": "Information", "description": "Event information and support"},
]

LOCATIONS = [
    "Convention Center Hall A", "Convention Center Hall B", "City Park Amphitheater",
    "Downtown Market Square", "University Sports Complex", "Modern Art Gallery",
    "City Center Route", "Skyline Hotel Ballroom", "Tech Campus Auditorium",
    "Sports Arena", "Community Center", "Exhibition Grounds", "Waterfront Plaza"
]

ORGANIZERS = [
    "Tech Corp", "Music Events Inc", "City Tourism Board", "University Career Services",
    "Arts Council", "Community Sports Club", "Gamers United", "Chamber of Commerce",
    "Green Energy Foundation", "Cultural Events Org", "Business Leaders Network"
]

def generate_users():
    """Generate realistic user data"""
    users = []
    for i in range(1, NUM_USERS + 1):
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        email = f"{first_name.lower()}.{last_name.lower()}{random.randint(1, 999)}@email.com"
        role = "admin" if i <= 5 else "user"
        
        # Create date between 1-3 months ago
        days_ago = random.randint(1, 90)
        created_at = datetime(2026, 2, 22) - timedelta(days=days_ago)
        
        # Vary activity levels
        ar_sessions = random.choices([0, 1, 2, 3, 5, 8, 12, 15, 20, 25], 
                                     weights=[5, 10, 15, 20, 20, 15, 10, 3, 1, 1])[0]
        events_registered = random.randint(0, min(ar_sessions + 2, 8))
        avg_duration = random.uniform(120, 400) if ar_sessions > 0 else 0
        
        users.append({
            'user_id': f'u{i:03d}',
            'email': email,
            'display_name': f'{first_name} {last_name}',
            'role': role,
            'created_at': created_at.isoformat() + 'Z',
            'ar_sessions_count': ar_sessions,
            'events_registered': events_registered,
            'avg_session_duration': round(avg_duration, 1)
        })
    
    return users

def generate_events():
    """Generate realistic event data"""
    events = []
    base_date = datetime(2026, 2, 15)
    
    for i in range(1, NUM_EVENTS + 1):
        template = EVENT_TEMPLATES[(i - 1) % len(EVENT_TEMPLATES)]
        
        # Spread events over 6 months
        days_offset = random.randint(0, 180)
        start_date = base_date + timedelta(days=days_offset)
        
        # Event duration 1-3 days
        duration_hours = random.choice([8, 10, 24, 48, 72])
        end_date = start_date + timedelta(hours=duration_hours)
        
        capacity = template['capacity']
        registered = int(capacity * random.uniform(0.3, 0.9))
        
        events.append({
            'event_id': f'e{i:03d}',
            'name': template['name'].format(2026) if '{}' in template['name'] else f"{template['name']} {i}",
            'description': template['description'],
            'category': template['category'],
            'location': random.choice(LOCATIONS),
            'start_date': start_date.isoformat() + 'Z',
            'end_date': end_date.isoformat() + 'Z',
            'organizer': random.choice(ORGANIZERS),
            'capacity': capacity,
            'registered_count': registered,
            'ar_enabled': random.choice([True, True, True, False])  # 75% AR enabled
        })
    
    return events

def generate_stalls(events):
    """Generate realistic stall data for events"""
    stalls = []
    stall_id = 1
    
    # Distribute stalls across events
    for event in events:
        if not event['ar_enabled']:
            continue
        
        # Number of stalls per event (3-7)
        num_stalls = random.randint(3, 7)
        
        for _ in range(num_stalls):
            if stall_id > NUM_STALLS:
                break
                
            template = random.choice(STALL_TEMPLATES)
            
            stalls.append({
                'stall_id': f's{stall_id:03d}',
                'event_id': event['event_id'],
                'name': f"{template['name']} {stall_id}",
                'category': template['category'],
                'description': template['description'],
                'location': f"Zone {random.choice(['A', 'B', 'C', 'D'])} - Booth {random.randint(1, 50)}",
                'contact': f"info{stall_id}@stall.com",
                'marker_id': f'marker_{stall_id:03d}',
                'qr_code': f'QR_{stall_id:03d}'
            })
            stall_id += 1
    
    return stalls

def generate_user_activities(users, events, stalls):
    """Generate realistic user activity data with proper AR session flows"""
    activities = []
    activity_id = 1
    
    # Create event_id to stalls mapping
    event_stalls = {}
    for stall in stalls:
        event_id = stall['event_id']
        if event_id not in event_stalls:
            event_stalls[event_id] = []
        event_stalls[event_id].append(stall)
    
    # Get AR-enabled events
    ar_events = [e for e in events if e['ar_enabled']]
    
    # Active users (users who will have significant activity)
    active_user_weights = [max(1, u['ar_sessions_count']) for u in users]
    
    while activity_id <= NUM_ACTIVITIES:
        # Select a user (weighted by activity level)
        user = random.choices(users, weights=active_user_weights)[0]
        
        # Select an event
        event = random.choice(ar_events)
        event_id = event['event_id']
        
        # Parse event start date
        event_date = datetime.fromisoformat(event['start_date'].replace('Z', ''))
        
        # Should user register for this event? (40% chance)
        will_register = random.random() < 0.4
        
        if will_register and activity_id <= NUM_ACTIVITIES:
            # Registration happens 1-14 days before event
            reg_date = event_date - timedelta(days=random.randint(1, 14), 
                                              hours=random.randint(8, 20))
            activities.append({
                'activity_id': f'a{activity_id:04d}',
                'user_id': user['user_id'],
                'event_id': event_id,
                'stall_id': '',
                'activity_type': 'event_registered',
                'timestamp': reg_date.isoformat() + 'Z',
                'duration_seconds': 0,
                'metadata': '{}'
            })
            activity_id += 1
        
        # Should user browse the event? (30% chance)
        if not will_register and random.random() < 0.3 and activity_id <= NUM_ACTIVITIES:
            browse_date = event_date - timedelta(days=random.randint(1, 30),
                                                 hours=random.randint(8, 22))
            activities.append({
                'activity_id': f'a{activity_id:04d}',
                'user_id': user['user_id'],
                'event_id': event_id,
                'stall_id': '',
                'activity_type': 'event_viewed',
                'timestamp': browse_date.isoformat() + 'Z',
                'duration_seconds': 0,
                'metadata': '{}'
            })
            activity_id += 1
        
        # Should user attend and use AR? (50% chance if registered, 20% if not)
        attend_probability = 0.5 if will_register else 0.2
        if random.random() < attend_probability and event_id in event_stalls:
            # AR session during event (on event day)
            session_start = event_date + timedelta(hours=random.uniform(0, 6))
            
            # AR session start
            if activity_id > NUM_ACTIVITIES:
                break
                
            activities.append({
                'activity_id': f'a{activity_id:04d}',
                'user_id': user['user_id'],
                'event_id': event_id,
                'stall_id': '',
                'activity_type': 'ar_session_start',
                'timestamp': session_start.isoformat() + 'Z',
                'duration_seconds': 0,
                'metadata': '{}'
            })
            activity_id += 1
            
            # User scans markers (1-5 markers)
            available_stalls = event_stalls[event_id]
            num_scans = min(random.randint(1, 5), len(available_stalls))
            scanned_stalls = random.sample(available_stalls, num_scans)
            
            time_offset = timedelta(minutes=random.randint(2, 5))
            markers_scanned = 0
            overlays_viewed = 0
            
            for stall in scanned_stalls:
                if activity_id > NUM_ACTIVITIES - 2:  # Need room for scan + view
                    break
                    
                # Marker scanned
                scan_time = session_start + time_offset
                activities.append({
                    'activity_id': f'a{activity_id:04d}',
                    'user_id': user['user_id'],
                    'event_id': event_id,
                    'stall_id': stall['stall_id'],
                    'activity_type': 'marker_scanned',
                    'timestamp': scan_time.isoformat() + 'Z',
                    'duration_seconds': 0,
                    'metadata': json.dumps({'marker_id': stall['marker_id']})
                })
                activity_id += 1
                markers_scanned += 1
                
                # Overlay view (immediately after scan)
                view_duration = random.randint(20, 300)
                view_time = scan_time + timedelta(seconds=5)
                activities.append({
                    'activity_id': f'a{activity_id:04d}',
                    'user_id': user['user_id'],
                    'event_id': event_id,
                    'stall_id': stall['stall_id'],
                    'activity_type': 'overlay_view',
                    'timestamp': view_time.isoformat() + 'Z',
                    'duration_seconds': view_duration,
                    'metadata': json.dumps({'stall_name': stall['name']})
                })
                activity_id += 1
                overlays_viewed += 1
                
                time_offset += timedelta(minutes=random.randint(3, 8))
            
            # AR session end
            if activity_id <= NUM_ACTIVITIES:
                session_duration = int(time_offset.total_seconds())
                session_end = session_start + time_offset
                activities.append({
                    'activity_id': f'a{activity_id:04d}',
                    'user_id': user['user_id'],
                    'event_id': event_id,
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
    """Save data to CSV file"""
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    print(f"✅ Created {filename} with {len(data)} rows")

def main():
    print("Generating large EventLens dataset...")
    print(f"Target: {NUM_USERS} users, {NUM_EVENTS} events, {NUM_STALLS} stalls, {NUM_ACTIVITIES} activities\n")
    
    # Generate data
    print("1/4 Generating users...")
    users = generate_users()
    
    print("2/4 Generating events...")
    events = generate_events()
    
    print("3/4 Generating stalls...")
    stalls = generate_stalls(events)
    
    print("4/4 Generating user activities (this may take a moment)...")
    activities = generate_user_activities(users, events, stalls)
    
    print("\nSaving to CSV files...\n")
    
    # Save to CSV
    save_to_csv('ml_data/large_dataset/users.csv', users,
                ['user_id', 'email', 'display_name', 'role', 'created_at', 
                 'ar_sessions_count', 'events_registered', 'avg_session_duration'])
    
    save_to_csv('ml_data/large_dataset/events.csv', events,
                ['event_id', 'name', 'description', 'category', 'location', 
                 'start_date', 'end_date', 'organizer', 'capacity', 
                 'registered_count', 'ar_enabled'])
    
    save_to_csv('ml_data/large_dataset/stalls.csv', stalls,
                ['stall_id', 'event_id', 'name', 'category', 'description', 
                 'location', 'contact', 'marker_id', 'qr_code'])
    
    save_to_csv('ml_data/large_dataset/user_activity.csv', activities,
                ['activity_id', 'user_id', 'event_id', 'stall_id', 
                 'activity_type', 'timestamp', 'duration_seconds', 'metadata'])
    
    print("\n" + "="*60)
    print("Dataset generation complete!")
    print("="*60)
    print(f"\n📊 Dataset Statistics:")
    print(f"  Users: {len(users)}")
    print(f"  Events: {len(events)}")
    print(f"  Stalls: {len(stalls)}")
    print(f"  Activities: {len(activities)}")
    print(f"\n📁 Files saved to: ml_data/large_dataset/")
    print(f"\n✅ Ready for ML model training!")

if __name__ == "__main__":
    main()
