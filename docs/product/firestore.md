# Firestore Setup (Sivra V1)

## Enable Anonymous Auth (required)

Firebase Console → Authentication → Sign-in method → Enable **Anonymous**.

## Create Firestore Database (required)

Firebase Console → Firestore Database → Create database.

Choose the production mode prompt if asked, then apply the development rules below.
Pick the database location deliberately; it cannot be changed later for the default database.

## Minimal Security Rules (development)

Firebase Console → Firestore Database → Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;

      match /daily/{dayId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```