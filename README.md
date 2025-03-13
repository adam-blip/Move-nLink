# Move'nLink

A PowerShell utility that moves directories to a new location while creating junction links at the original paths to maintain compatibility with existing applications.

## Description

Move'nLink helps reorganize your file system by moving directories to a new location (e.g., a different drive) while maintaining functionality for applications that expect the directories to be in their original location. This is particularly useful for:

- Moving large application data to a secondary drive
- Reorganizing your file structure without breaking application dependencies
- Managing disk space by relocating folders to drives with more capacity

## Features

- Moves directories from source to target location
- Creates junction links at the original locations pointing to the new locations
- Automatically requests administrator privileges when needed
- Simple command-line interface with two parameters

## Requirements

- Windows PowerShell 5.1 or later
- Administrator privileges (requested automatically if needed)

## Installation

1. Download `Move-nLink.ps1` from this repository
2. Save it to a location on your computer

## Usage

```powershell
.\Move-nLink.ps1 -SourceDir "C:\OriginalPath" -TargetDir "D:\NewPath"
```

### Parameters

- `-SourceDir`: The directory containing the folders you want to move
- `-TargetDir`: The destination directory where folders will be moved to

## Example

Moving game data folders to a secondary drive:

```powershell
.\Move-nLink.ps1 -SourceDir "C:\Users\YourName\AppData\Local\GameData" -TargetDir "D:\GameData"
```

This will:
1. Move all subdirectories from `C:\Users\YourName\AppData\Local\GameData` to `D:\GameData`
2. Create junction links in the original location pointing to the new locations
3. Applications will continue to work as if the directories were still in their original location

## Notes

- The script only moves directories, not individual files
- Existing directories in the target location will be skipped
- Administrator privileges are required to create junction links

## License

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
