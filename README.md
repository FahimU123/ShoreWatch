# ShoreWatch

Real-time maritime safety for the Great Lakes, powered by IBM watsonx AI.

> Built at Hack Michigan 2026 · May 15–17, Detroit

---

## The Problem

Every year, people die on the Great Lakes not from recklessness, but from ignorance. NOAA publishes live buoy data (wave heights, wind speeds, water temperatures) but it lives in government text tables nobody reads. ShoreWatch fixes that.

## What It Does

ShoreWatch finds your location, pulls live NOAA buoy telemetry, runs it through IBM watsonx AI, and tells you in plain English whether it's safe to be on the water. Launch to verdict in under 10 seconds.

**Four alert levels:** Get out now / Monitor closely / All clear / Assessing

## Features

- **Live buoy map.** Every NOAA station on the Great Lakes, color-coded by alert level. Tap any buoy for full conditions.
- **AI safety assessment.** watsonx generates a plain-English narrative explaining conditions and recommended action. Reads aloud hands-free.
- **Survival time.** Estimates how long a person survives in water at current temperature, using USCG immersion tables.
- **Harbor navigation.** One tap opens Apple Maps with directions to the nearest safe port.
- **AR compass mode.** Camera view with a live compass pointing toward the nearest buoy, bearing in degrees, alert level overlay.
- **Safety dashboard.** Pre-departure checklist, VHF radio reference, emergency contacts, and one-tap GPS location share.

## Tech Stack

| | |
|---|---|
| AI | IBM watsonx.ai + Google Gemini |
| Data | NOAA National Data Buoy Center API |
| App | Swift, SwiftUI, iOS |
| Maps | Apple MapKit |
| AR | ARKit, AVFoundation |
| Location | CoreLocation |

## Michigan Impact

The Great Lakes define Michigan. Over 1 million registered watercraft, $7B+ in annual recreational boating, and 3,000 miles of shoreline. ShoreWatch is built for these waters specifically. The buoy network, harbor database, and vessel traffic are all calibrated to the Great Lakes.

## Team

Built at Hack Michigan 2026, May 15–17, Detroit.

IBM watsonx.ai integration: `WatsonxService.swift`
NOAA data pipeline: `NOAAService.swift`
