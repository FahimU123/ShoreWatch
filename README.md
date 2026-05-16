# ShoreWatch

**Real-time maritime safety for the Great Lakes — powered by IBM watsonx AI**

> Built at Hack Michigan 2026 · May 15–17, Detroit

---

## The Problem

The Great Lakes are the largest freshwater system on Earth, spanning 94,000 square miles across Michigan and four neighboring states. Every year, dozens of people die on these waters — not from recklessness, but from ignorance. Conditions that look calm at the dock can be deadly a mile offshore.

NOAA maintains a network of offshore buoy stations that measure real-time wave heights, wind speeds, water temperatures, and swell periods. This data is accurate, live, and free. It is also buried in dense government text tables that no recreational boater, kayaker, or swimmer reads before going out.

**Michigan loses lives because critical safety data exists but isn't accessible.**

---

## The Solution

ShoreWatch is a native iOS app that pulls live NOAA buoy telemetry, runs it through IBM watsonx AI, and delivers a plain-English safety verdict in seconds — before you ever leave the dock.

Open the app. It finds your location, identifies the nearest buoy station, fetches live conditions, and tells you: **Get out now. Monitor closely. All clear.**

No marine science degree required.

---

## How It Works

```
Your GPS location
      ↓
Nearest NOAA buoy station identified
      ↓
Live telemetry fetched (waves, wind, temperature, pressure)
      ↓
IBM watsonx AI analyzes conditions + generates safety narrative
      ↓
Alert level + actionable guidance delivered in plain English
```

### The Four Alert Levels

| Level | Meaning |
|---|---|
| 🔴 Get out now | Dangerous conditions. Exit the water immediately. |
| 🟠 Monitor closely | Deteriorating conditions. Exercise caution. |
| 🟢 All clear | Safe conditions. Standard precautions apply. |
| ⚪ Assessing | Data collection in progress. |

---

## Features

### Live Buoy Map
Interactive MapKit map showing every NOAA buoy station across the Great Lakes — color-coded by alert level. Tap any buoy to see its full conditions report. Also shows real AIS maritime vessel traffic so you know what's sharing the water with you.

### AI Safety Assessment
IBM watsonx analyzes raw buoy telemetry and generates a human-readable narrative explaining current conditions, what they mean for safety, and what action to take. The assessment reads aloud via on-device speech synthesis — useful when your hands are on the wheel.

### Survival Time Calculator
Based on live water temperature and USCG cold-water immersion survival tables, ShoreWatch estimates how long a person can survive in the water at current conditions. This number updates in real time as temperatures change. It's the number that matters most in a rescue situation.

### Navigate to Nearest Harbor
One tap on the Nearest Harbor card opens Apple Maps with turn-by-turn directions to the closest safe port. In an emergency, you shouldn't have to think about where to go.

### AR Compass Mode
Switch to augmented reality view and the camera becomes a heads-up display. A compass arrow points in real time toward the nearest buoy, compensating for device heading. Bearing in degrees. Water temperature. Survival time. Alert level. All visible while looking through the camera.

### Safety Dashboard
A full pre-departure safety hub:
- **Emergency location share** — one tap generates a message with your GPS coordinates and the Coast Guard number, ready to send to family or rescue services
- **Pre-departure checklist** — life jackets, VHF radio, fuel, weather, float plan
- **VHF radio channel reference** — CH 16, 09, 22A, 13
- **Emergency contacts** — Coast Guard (1-800-424-8802) and BoatUS Towing (1-800-391-4869), tap to call

### Forecast Trend
Each buoy shows whether conditions are improving, steady, or worsening — and a safe window label when conditions are expected to ease (e.g. *"May ease after 20:00 local"*).

---

## Technology Stack

| Layer | Technology |
|---|---|
| **AI / Assessment** | IBM watsonx.ai · Google Gemini |
| **Buoy Data** | NOAA National Data Buoy Center API |
| **Mobile** | Swift · SwiftUI · iOS |
| **Maps** | Apple MapKit |
| **AR** | ARKit · AVFoundation |
| **Location** | CoreLocation (GPS + heading) |
| **Accessibility** | AVSpeechSynthesizer · haptics · Dynamic Type |

### IBM watsonx Integration

IBM watsonx.ai is the core AI engine behind ShoreWatch's safety assessments. Raw NOAA telemetry — wave height, wind speed, dominant wave period, water temperature, barometric pressure — is sent to watsonx, which:

1. Interprets the combined data in context (individual readings can be misleading; watsonx evaluates them together)
2. Applies maritime safety reasoning to determine risk level
3. Generates a plain-English narrative explaining the conditions and recommended action
4. Returns a structured alert level alongside the narrative

This is not a rule-based threshold system. watsonx understands that 2-meter waves with a 6-second period are far more dangerous than 2-meter waves with a 12-second period, because it reasons about the data rather than just comparing numbers against cutoffs.

---

## Michigan Impact

The Great Lakes are Michigan's defining geographic feature and one of its greatest economic assets:

- **$7 billion+** in annual recreational boating activity in Michigan alone
- **\~1 million** registered watercraft in Michigan — third highest in the US
- **Over 3,000 miles** of Great Lakes shoreline within Michigan
- Fishing, tourism, shipping, and recreation industries all depend on safe water access

ShoreWatch is built specifically for the Great Lakes. The buoy network, the harbor database, the vessel traffic — all of it is calibrated to Michigan waters. This is not a generic maritime app ported to the Midwest. It is a Michigan solution to a Michigan problem.

**Jobs and economic opportunity:** ShoreWatch creates a foundation for Michigan-based development of maritime safety technology. The AI assessment pipeline, the real-time data infrastructure, and the mobile platform are all extensible to commercial shipping, search and rescue coordination, and insurance risk assessment — industries with significant Michigan presence.

**Open data, open source:** Built on NOAA's public buoy API, ShoreWatch demonstrates how Michigan technologists can build high-value products on top of existing public infrastructure without waiting for government to build the user-facing layer.

---

## Demo Buoy Network (Live at Hack Michigan)

| Station | Name | Location |
|---|---|---|
| 45005 | West Erie | Lake Erie, central-west |
| 45147 | Central Erie | Lake Erie, mid-lake |
| 45142 | East Erie | Lake Erie, eastern |
| 45008 | Lake Huron South | Southern Lake Huron |
| 45007 | Lake Michigan South | Southern Lake Michigan |

---

## Judging Criteria — Our Case

**Completeness and Feasibility (5/5)**
ShoreWatch is a working iOS application with a functioning AI assessment pipeline, live map, AR compass mode, and safety dashboard. Every feature shown in the video is real and running on device. The NOAA API integration is production-grade. IBM watsonx powers the core AI layer. This is not a prototype or mockup.

**Effectiveness and Efficiency (5/5)**
The app solves the problem in under 10 seconds from launch: location → buoy → assessment → verdict. The AI narrative replaces hours of manual interpretation of NOAA data tables. The survival time calculator and harbor navigation features provide the two most critical pieces of information in an emergency — *how long do I have* and *where do I go*.

**Design and Usability (5/5)**
ShoreWatch follows Apple Human Interface Guidelines throughout. No gray toolbars, no cluttered screens, no jargon. Alert levels are communicated with color, icon, and plain-English text simultaneously — accessible to users with color vision deficiency. The AI assessment reads aloud for hands-free use on the water. Emergency actions (call Coast Guard, share location, navigate to harbor) are one tap from the main screen.

**Creativity and Innovation (5/5)**
No existing public app combines live NOAA buoy telemetry, AI-generated safety assessments, cold-water survival time calculation, AR bearing compass, and one-tap harbor navigation in a single mobile experience. The IBM watsonx integration for maritime safety assessment is a novel application of large language model reasoning to structured environmental sensor data.

**Michigan Impact (5/5)**
The Great Lakes are Michigan. Recreational boating is a $7B+ industry in this state. ShoreWatch is designed for Michigan waters, built by Michigan hackers, and addresses a problem that kills Michigan residents every year. The open data foundation (NOAA API) means the core infrastructure is free and permanent. The extensible AI pipeline creates a platform for Michigan-based maritime technology companies to build on.

---

## Team

Built at Hack Michigan 2026, May 15–17, Detroit.

---

## Repository

All source code available in this repository. Built with Swift and SwiftUI for iOS. IBM watsonx.ai API integration in `WatsonxService.swift`. NOAA buoy data pipeline in `NOAAService.swift`.
