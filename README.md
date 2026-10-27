# BrowserLand

This is a browser that gives you the ability to customize everything. It should work on Linux perfectly fine!

It's fast and have a customizable, easy-to-learn language where you can write just like you do with Hyprland and Quickshell. For example, you can add your own widgets and UI elements, and change anything.

You are limited only by your imagination :)


## Tech Stack:
- C++ as the backend
- QML/Qt6 for the UI
- QtWebEngine (Chromium)


## Development

Compile the code using:
```
cmake -S . -B build -G Ninja
cmake --build build
```

Launch the browser:
`./build/browserland` or if you want to use a config `./build/browserland --config-dir examples`
