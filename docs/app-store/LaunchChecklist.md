# SheetSnap App Store Launch Checklist

Use this file as the final submission checklist for `SheetSnap: Table OCR`.

## Status

Repo-side launch prep is largely done:

- App Store title, subtitle, keywords, pricing, screenshots, support/privacy pages, and review-note copy are prepared.
- Premium screenshot assets are ready in `docs/app-store/app-store-upload-screenshots`.
- App icon assets are wired in `SheetSnap/Assets.xcassets/AppIcon.appiconset`.

The remaining steps are mostly account-side or store-side actions.

## App Store Connect Fields

Use these values:

- Name: `SheetSnap: Table OCR`
- Subtitle: `Photo to CSV, Excel, Sheets`
- Category: `Productivity`
- Price: `$14.99`
- Keywords: `table,image,ocr,excel,csv,spreadsheet,scan,sheets,data,photo to excel`

## URLs

These are the intended public URLs:

- Support URL: `https://casstao1.github.io/SheetSnapOFFICIAL/support/`
- Privacy Policy URL: `https://casstao1.github.io/SheetSnapOFFICIAL/privacy/`

These pages already exist in `docs/`, but GitHub Pages must be enabled on the repo before they will resolve publicly.

## GitHub Pages

In GitHub:

1. Open repository settings.
2. Go to `Pages`.
3. Set `Deploy from a branch`.
4. Select branch `main`.
5. Select folder `/docs`.
6. Save.
7. Wait a few minutes, then verify both URLs load publicly.

## Screenshot Upload Set

Use these screenshots for App Store upload:

- `docs/app-store/app-store-upload-screenshots/01-import-marketing.png`
- `docs/app-store/app-store-upload-screenshots/02-processing-marketing.png`
- `docs/app-store/app-store-upload-screenshots/03-results-marketing.png`
- `docs/app-store/app-store-upload-screenshots/04-history-marketing.png`
- `docs/app-store/app-store-upload-screenshots/05-editing-marketing.png`

Current size is `2560x1600`, which is valid for Mac App Store screenshots.

## App Privacy

Recommended answers, only if they are accurate for the shipping build:

- Data Not Collected
- No Tracking
- Files processed locally on device
- Model asset downloaded on first launch

Verify these answers against the final shipped behavior before submission.

## App Review Notes

Paste this into App Review Notes:

`SheetSnap: Table OCR extracts tables from user-selected images on macOS.`

`The app may download an Apple-hosted model asset on first launch before the first extraction. After the asset is available, users can import an image by choosing a file, dropping an image into the window, or pasting an image from the clipboard.`

`The app uses standard macOS open/save panels for user-selected file access.`

## Pre-Submission Validation

Run through these flows on a clean machine or clean macOS user account:

- Launch app
- First-launch model asset download
- Import with `Choose Image`
- Import via drag and drop
- Import via paste image
- Extract a table successfully
- Copy output into a spreadsheet app
- Export CSV
- Export Excel
- Relaunch app offline after the model asset is already present
- Verify History works

## Build / Upload

In Xcode:

1. Select the `SheetSnap` scheme.
2. Choose `Any Mac` or your Mac as the destination.
3. Build once cleanly.
4. Archive a Release build with `Product -> Archive`.
5. In Organizer, validate the archive.
6. Upload to App Store Connect.

## Before Clicking Submit

Confirm all of the following:

- Support URL is reachable
- Privacy URL is reachable
- App Privacy questionnaire is complete
- Review Notes are added
- Premium screenshots are uploaded
- Final icon is correct in the archive
- First-launch model flow works
- Release archive validates successfully

## Current External Blockers

These cannot be completed from the repo alone:

- GitHub Pages activation
- App Store Connect metadata entry
- App Privacy questionnaire submission
- Release archive upload/validation in your Apple account
- Final review submission
