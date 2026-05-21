# Firestore Setup (Sivra V1)

## Enable Anonymous Auth (required)

Firebase Console → Authentication → Sign-in method → Enable **Anonymous**.

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

