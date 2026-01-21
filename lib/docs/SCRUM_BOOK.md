# Scrum Book - EventLens Project

## January 20, 2026 (Yesterday)

We set up Firebase in the app and built the complete authentication system. Users can now register and login with their email and password. The app saves user profiles in Firestore with their role information. We also created role-based routing so admins go to the admin dashboard while regular users see the home screen.

We built security rules in Firestore to protect admin features. Only users with admin role can access admin functions. We added session handling so users stay logged in when they reopen the app, and they can logout when needed. All Phase 2 tasks were completed.

## January 21, 2026 (Today)

We fixed authentication bugs and improved the app design. The home screen, login screen, and register screen now look better. We built the complete event management system for admins. They can now add, edit, and delete events with all details like name, description, dates, and location.

We created stall management features where admins can add and edit stalls linked to events. Each stall has marker validation to prevent duplicate AR markers. We also implemented image upload for both events and stalls using Firebase Storage.

For regular users, we built screens to view all events and see detailed information about each event. We added error handling throughout the app so users see helpful messages when something goes wrong. The app now also works offline using Firestore cache. Most of Phase 3 is now complete.
