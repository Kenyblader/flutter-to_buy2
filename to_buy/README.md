# To Buy Application

This Flutter application is designed to help users manage their shopping lists efficiently. It features a reusable styled button component that can be utilized throughout the app.

## Project Structure

```
to_buy
├── lib
│   ├── components
│   │   ├── style_button.dart
│   ├── main.dart
├── pubspec.yaml
└── README.md
```

## Components

### StyleButton

The `StyleButton` class is a reusable styled button component located in `lib/components/style_button.dart`. It accepts two parameters:
- `onpressed`: A function that is called when the button is pressed.
- `child`: A widget that represents the content of the button.

### Main Entry Point

The main entry point of the application is defined in `lib/main.dart`. This file initializes the Flutter app and may include the main widget that utilizes the `StyleButton`.

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd to_buy
   ```

3. Install the dependencies:
   ```
   flutter pub get
   ```

4. Run the application:
   ```
   flutter run
   ```

## Usage Example

To use the `StyleButton` in your application, import it and include it in your widget tree:

```dart
import 'package:to_buy/components/style_button.dart';

// Inside your widget build method
StyleButton(
  onpressed: () {
    // Handle button press
  },
  child: Text('Click Me'),
)
```

## License

This project is licensed under the MIT License. See the LICENSE file for more details.