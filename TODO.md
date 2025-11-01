# TODO: Implement Webcam Photo Taking and Database Insertion on Web

## Information Gathered
- The Flutter app already supports taking photos via webcam on web using the browser's camera picker (via `image_picker` package).
- Images are uploaded as multipart files to the PHP backend (`add_product.php`), saved to `lib/api/picture/images/`, and product data is inserted into the database.
- Permissions are configured in `web/index.html` (meta tag for camera) and `android/app/src/main/AndroidManifest.xml` (camera permissions).
- The `camera` package is in `pubspec.yaml` but not yet integrated for live preview; current implementation uses image picker for camera/gallery selection.
- User confirmed they want to proceed with testing/enhancing the current webcam functionality on web.

## Plan
- [x] Ensure Flutter dependencies are installed (`flutter pub get`).
- [x] Run the Flutter web app in Chrome to test current functionality (`flutter run -d chrome`).
- [x] Test current implementation - webcam not opening on web (user reported issue).
- [ ] Stop the running app.
- [ ] Integrate `camera` package for live webcam preview on web.
- [ ] Update `add_product_controller.dart` to initialize camera and handle capture.
- [ ] Update `add_product_view.dart` to show camera preview widget.
- [ ] Test the enhanced webcam functionality.
- [ ] Verify that photos are taken, uploaded, and inserted into the database.

## Dependent Files to Edit
- No edits needed initially; test current implementation first.
- If enhancing: Modify `add_product_view.dart`, `add_product_controller.dart`, and potentially add camera preview widget.

## Followup Steps
- [ ] After testing, confirm if the current browser camera picker is sufficient or if live preview is required.
- [ ] If live preview is needed, integrate `camera` package for real-time webcam feed and capture.
- [ ] Update database schema or PHP if additional features are added (e.g., multiple captures).
- [ ] Test on different browsers/devices for compatibility.
