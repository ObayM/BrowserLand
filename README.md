# BrowserLand

Simply this is a browser that gives you the ability to customize everything, it should work on linux, mac and windows!

It should be fast, have a customizable easy to learn language where you can write in it
jus like the way you do with hyprland and quickshell
For example, you can add your own widgets, UI elments, change anything

Your are not limited but except with your imagination

## Tech Stack:

This would be using:

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
