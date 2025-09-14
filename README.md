# Live Location Share

**Share your live location with friends in real-time, across Android and the Web!**

**Core Features:**

*   **Real-time Location Sharing:** See your friends' current location on a map.
*   **Cross-Platform:** Works on Android devices and web browsers.
*   **Self-Hosted Backend:** Utilizes a WebSocket server ([MyTracksLoc/mytracks-ws-server](https://github.com/MyTracksLoc/mytracks-ws-server)) for data privacy and control.
*   **Easy to Use:** Simple interface for starting and stopping location sharing.

## Screenshots

## Screenshots

| Android - Settings Screen          | Android - Map View              | Android - List Users |
| :-------------------------: | :--------------------------: | :--------------------------: |
| ![Android Map View](https://raw.githubusercontent.com/MyTracksLoc/mytracks-flutter-client/master/screen1.jpg) | ![Web Map View](https://raw.githubusercontent.com/MyTracksLoc/mytracks-flutter-client/master/screen2.jpg) | ![Android Sharing Controls](https://raw.githubusercontent.com/MyTracksLoc/mytracks-flutter-client/master/screen3.jpg) |
| *Friends' locations on Android* | *Friends' locations on the Web* | *Starting/Stopping sharing on Android* |


## How it Works

The application consists of client and a server component:

1.  **Android App:** Allows users to share their location and view the live location of their friends.
2.  **Web App:** Provides a similar experience to the Android app, accessible from any modern web browser.
3.  **WebSocket Server:** The backend ([MyTracksLoc/mytracks-ws-server](https://github.com/MyTracksLoc/mytracks-ws-server)) that facilitates real-time communication between users. Location updates are sent to the server and then broadcasted to connected friends.

## Getting Started

### Prerequisites

*   **WebSocket Server:** You need to have an instance of the [MyTracksLoc/mytracks-ws-server](https://github.com/MyTracksLoc/mytracks-ws-server) up and running. Follow the instructions in its repository to set it up.
*   **Android Development Environment:** (For Android app)
    *   Android Studio (latest stable version recommended)
    *   Android SDK
*   **Web Server:** (For hosting the web app)
    *   Any static web server (e.g., Nginx, Apache, or even GitHub Pages for simple deployments).

### Configuration

1.  **WebSocket Server URL:**
    *   **Android App:** Update the WebSocket server URL in the app's configuration file (e.g., `constants.kt` or `build.gradle`).
    *   **Web App:** Update the WebSocket server URL in the web app's JavaScript configuration.
2.  **API Keys (if applicable):**
    *   If you are using map providers like Google Maps, ensure you have valid API keys configured for both the Android app and the Web app.
        *   **Android:** Typically in `local.properties` or `build.gradle`.
        *   **Web:** In your HTML or JavaScript files.

### Building and Running

**Android App:**

1.  Clone this repository.
2.  Open the Android project in Android Studio.
3.  Configure the WebSocket server URL as mentioned above.
4.  Build and run the app on an Android device or emulator.

**Web App:**

1.  Clone this repository.
2.  Navigate to the web app's directory.
3.  Configure the WebSocket server URL in the relevant JavaScript file.
4.  Deploy the web app files to your web server.
5.  Access the web app through your browser.

## Usage

1.  **Start Sharing:**
    *   Open the app (Android or Web).
    *   Tap the "Start Sharing" button. Your location will now be sent to the WebSocket server.
2.  **View Friends:**
    *   Friends who are also sharing their location and are connected to the same server instance will appear on your map.
3.  **Stop Sharing:**
    *   Tap the "Stop Sharing" button to cease broadcasting your location.

## Contributing

Contributions are welcome! If you have suggestions, bug reports, or want to contribute code, please:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature-name`).
3.  Make your changes.
4.  Commit your changes (`git commit -am 'Add some feature'`).
5.  Push to the branch (`git push origin feature/your-feature-name`).
6.  Create a new Pull Request.

## Tech Stack

*   **Android:** Kotlin, Jetpack (ViewModel, LiveData/Flow, Navigation), Google Maps SDK (or your preferred map SDK).
*   **Web:** HTML, CSS, JavaScript, (mention any frameworks like React, Vue, Angular if used), Leaflet.js / OpenLayers / Google Maps JavaScript API (or your preferred map library).
*   **Backend:** [MyTracksLoc/mytracks-ws-server](https://github.com/MyTracksLoc/mytracks-ws-server) (Node.js, WebSocket library like `ws` or `Socket.IO`).

## License

(Specify your project's license here, e.g., MIT, Apache 2.0)

