#!/usr/bin/env python
import json
import argparse

# List of possible targets
targets = [
    'Linux-x86_64.AppImage',
    'Linux-x86_64.AppImage-SHA256.txt',
    'Linux-aarch64.AppImage',
    'Linux-aarch64.AppImage-SHA256.txt',
    'macOS-apple-silicon-arm64.dmg',
    'macOS-apple-silicon-arm64.dmg-SHA256.txt',
    'macOS-intel-x86_64.dmg',
    'macOS-intel-x86_64.dmg-SHA256.txt',
    'Windows-x86_64-installer.exe',
    'Windows-x86_64-installer.exe-SHA256.txt',
    'Windows-x86_64.7z'
]

def target_from_filename(filename):
    for target in targets:
        if filename.endswith(target):
            return target
    return None

def generate_asset_json(filename, uploaded_unique_filename, tag_name):
    # Infer the target from the filename
    target = target_from_filename(filename)

    # Determine releaseCadence and release
    if tag_name == "weekly-builds":
        release_cadence = tag_name
        release = ""
    else:
        release_cadence = "stable"
        release = tag_name

    # Create the output dictionary
    output = {
        "target": target,
        "releaseCadence": release_cadence,
        "release": release,
        "filename": filename,
        "uploadedUniqueFilename": uploaded_unique_filename
    }

    # Convert the dictionary to JSON format
    return json.dumps(output)

def main():
    parser = argparse.ArgumentParser(description="Generate JSON output based on filename, uploadedUniqueFilename, and release tag name.")
    parser.add_argument("filename", type=str, help="The original name of the file")
    parser.add_argument("uploaded_unique_filename", type=str, help="The unique name of the file as uploaded to S3")
    parser.add_argument("tag_name", type=str, help="The release tag name (e.g., 'weekly-builds', '2024.2.2')")

    args = parser.parse_args()

    print(generate_asset_json(args.filename, args.uploaded_unique_filename, args.tag_name))

if __name__ == "__main__":
    main()
