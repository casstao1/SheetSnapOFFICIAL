# SheetSnap App Store Metadata

Use `SheetSnap: Table OCR` as the App Store Connect title.

Keep the shipped macOS bundle/product name as `SheetSnap` unless you intentionally want to rename the installed app in Finder, Launchpad, and the app menu. The App Store listing title does not require a binary rename.

## App Name
SheetSnap: Table OCR

## Subtitle
Photo to CSV, Excel, Sheets

## Promotional Text
Extract rows and columns from table images on your Mac, then copy, export, and clean up the data in seconds.

## Positioning
Core promise:
- Turn table photos into structured spreadsheet data fast

Primary buyers:
- people moving data from screenshots into spreadsheets
- office users digitizing printed tables
- students and researchers extracting tabular data from documents
- anyone cleaning up image-based tables without manual retyping

## Short Description
SheetSnap: Table OCR converts photos and screenshots of tables into editable spreadsheet data.

## Full Description
SheetSnap: Table OCR helps you turn table images into clean spreadsheet data on macOS.

Drop in a screenshot or choose a file. SheetSnap detects the table, extracts rows and columns, and lets you copy the result or export it as CSV or Excel.

Built for fast utility work:

- Extract tables from screenshots, scans, and photos
- Edit cells before exporting
- Copy into Excel, Google Sheets, and other spreadsheet apps
- Export as CSV or Excel
- Keep a local history of past extractions
- Runs on your Mac

SheetSnap: Table OCR is designed for quick one-off tasks like digitizing printed tables, moving data from PDFs and screenshots into spreadsheets, and cleaning up captured tabular data without manual retyping.

## Keywords
table,image,ocr,excel,csv,spreadsheet,scan,sheets,data,photo to excel

## Category
Productivity

## Pricing
Free download with a one-time non-consumable unlock after the 7-day trial.

## App Store Connect Fields
Use these values directly in App Store Connect:

- Name: `SheetSnap: Table OCR`
- Subtitle: `Photo to CSV, Excel, Sheets`
- Primary category: `Productivity`
- Price: `Free`
- In-App Purchase: one-time non-consumable unlock, recommended price `$14.99`
- Keywords: `table,image,ocr,excel,csv,spreadsheet,scan,sheets,data,photo to excel`

## Privacy Summary
Recommended if accurate for the shipping build:

- Data Not Collected
- No Tracking
- Files processed locally on device
- Model asset downloaded on demand after the user selects the first image

Verify this against the final shipping implementation before submission.

## Required URLs
Prepare these before submission:

- Support URL: `https://casstao1.github.io/SheetSnapOFFICIAL/support/`
- Privacy Policy URL: `https://casstao1.github.io/SheetSnapOFFICIAL/privacy/`

These pages are included in this repo under the GitHub Pages `docs/` directory. In GitHub repo settings, enable Pages from the `main` branch and `/docs` folder before using the URLs above.

## App Review Notes
SheetSnap: Table OCR extracts tables from user-selected images on macOS.

The app may download an Apple-hosted model asset after the user chooses or drops the first image. After the asset is available, the app continues processing the selected image automatically.

The app uses standard macOS open/save panels for user-selected file access.

## Screenshot Shot List
Capture these as clean native macOS window screenshots with no desktop clutter.
Do not upload an app preview for this resubmission. Use screenshots only.

### 1. Import Screen
Headline:
Turn Any Table Photo Into Spreadsheet Data

Caption:
Drop an image or choose a file.

Target UI:
- Idle import screen
- Clean empty-state window
- Native buttons visible

### 2. Processing Screen
Headline:
Extract Rows And Columns In Seconds

Caption:
Built for screenshots, scans, and photos of tables.

Target UI:
- Processing view with progress text
- Keep the window centered and uncluttered

### 3. Editable Results
Headline:
Review And Edit Before Exporting

Caption:
Fix cells quickly before sending data to your spreadsheet.

Target UI:
- Result table with several rows and columns
- Copy, CSV, and Excel actions visible

### 4. Spreadsheet Export
Headline:
Copy To Sheets Or Export To Excel

Caption:
Move extracted data into your existing workflow fast.

Target UI:
- Result screen focused on top action bar
- Consider showing a realistic table result

### 5. History
Headline:
Pick Up Where You Left Off

Caption:
Reopen previous extractions from the built-in history.

Target UI:
- History screen with several entries

## Screenshot Style Guidance
- Use the premium dark marketing set as the final App Store direction
- Keep the app window centered inside a clean framed card
- Use restrained green and teal accents with high-contrast typography
- Avoid showing debug text, Xcode, or desktop clutter
- Use realistic sample tables with recognizable structure
- Add short benefit-led marketing text outside the app window when composing final App Store images

Current premium assets:
- docs/app-store/marketing-screenshots-premium/01-import-marketing.png
- docs/app-store/marketing-screenshots-premium/02-processing-marketing.png
- docs/app-store/marketing-screenshots-premium/03-results-marketing.png
- docs/app-store/marketing-screenshots-premium/04-history-marketing.png
- docs/app-store/marketing-screenshots-premium/05-editing-marketing.png

Upload-ready screenshot folder:
- docs/app-store/app-store-upload-screenshots

## Recommended Screenshot Copy
Use one short headline plus one short supporting line per image. Keep it concrete and utility-focused.

Good:
- Turn Table Photos Into Spreadsheet Data
- Extract Rows And Columns Automatically
- Review Results Before Exporting
- Copy Into Sheets Or Save As Excel

Avoid:
- Technical model details
- Long paragraphs
- Claims you cannot verify

## Submission Checklist
- Confirm Release archive builds cleanly
- Confirm Apple-hosted model asset downloads after choosing or dropping the first image
- Confirm offline relaunch works after the model asset is downloaded
- Confirm drag and choose file workflows both work
- Confirm copy, CSV, and Excel export all work
- Fill App Privacy details accurately
- Add support URL and privacy policy URL
- Upload the premium polished screenshots
- Add App Review Notes about on-demand model download
- Validate the build in App Store Connect before submitting for review
