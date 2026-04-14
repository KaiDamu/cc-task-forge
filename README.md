# CC Task Forge

This repository contains Lua scripts for the [CC:Tweaked](https://tweaked.cc/) mod, designed to automate tasks, manage peripherals, and enhance in-game functionality.

## Features
- **Dynamic Startup Script**: Automatically downloads and runs the latest scripts for each computer.
- **TaskForge Library**: A versatile utility library for peripheral management, networking, and chat.
- **Error Handling**: Robust fallback mechanisms for offline use.
- **Modular Design**: Easily extendable with additional modules.

## File Structure
```
.
├── install/
│   └── script.lua       # Installation script
├── lib/
│   └── tflib.lua        # Core TaskForge library
├── pc/
│   ├── chester.lua      # Script for Chester computer
│   ├── gps.lua          # GPS management script
│   └── main.lua         # Default script for the main computer
├── cc-globals.lua       # Global constants and utilities
└── README.md            # Project documentation
```

## Getting Started

To set up a new computer, follow these steps:

1. Turn on the new computer.
2. Paste the following command into the terminal:

   ```lua
   wget run https://raw.githubusercontent.com/KaiDamu/cc-task-forge/main/install/script.lua
   ```

This will download and run the installer, setting up everything you need automatically.

## Dependencies
- [CC:Tweaked](https://tweaked.cc/)
- Internet access for downloading scripts.

## Usage
### Startup Script
The `startup.lua` script:
- Downloads the latest version of the computer's script and `tflib`.
- Checks file versions to avoid redundant downloads.
- Uses local files if downloads fail.
- Logs file statuses (updated, up-to-date, or fallback).

### TaskForge Library
The `tflib.lua` library includes:
- Peripheral management utilities.
- Networking and communication tools.
- Logging and debugging helpers.

## Contributing
Contributions are welcome! Submit issues or pull requests to improve the project.

## Acknowledgments
- [CC:Tweaked](https://tweaked.cc/) for the mod.
- The open-source community for inspiration and support.
