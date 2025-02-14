# kiwi

Hyper-local chat application


kiwi is a Flutter-based hyperlocal chat app that groups users into dynamic chat rooms based on real-time geolocation. A custom REST API (deployed on Vercel) computes Uber’s H3 hexagonal index for spatial segmentation, while Firebase Cloud Firestore and Auth power real-time messaging and secure authentication.

## Getting Started

1. Clone the repository.
2. Run `flutter pub get`.
3. Add your Firebase config files (google-services.json/GoogleService-Info.plist).
4. Launch the app with `flutter run`.

