# GoFile Upload Action

A GitHub Action that uploads files to [GoFile.io](https://gofile.io/). This action accepts a space-separated list of file paths as input and uploads each file, returning a download URL for each upload.

## Features

- **Easy file uploads:** Simply specify one or more file paths.
- **Automatic dependency installation:** Installs required tools (`jq` and `bc`) automatically (when using a compatible package manager).
- **Colored output:** Provides clear, colored status messages for a better user experience.
- **Random server selection:** Automatically chooses a GoFile server for each upload.

## Usage

### Workflow Example

Create a workflow file (e.g., `.github/workflows/upload.yml`) in your repository and add the following content:

```yaml
name: Upload Files Using GoFile

on:
  push:
    branches: [ main ]

jobs:
  upload:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Upload files to GoFile
        uses: toiletpuppy/gofile@New
        with:
          files: "path/to/file1.txt path/to/file2.zip"
```
