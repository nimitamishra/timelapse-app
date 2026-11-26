# Project: <Layover>

## What this app is (1–2 sentences, your words)
A flight and travel inspired timelapse study focus application. 
## How I want to work with Claude
- explain the plan before writing code, one milestone at a time, and I review every change
- Claude should stop and ask me anytime something gets confusing or requires clairification which does not exist in the current documentation. My answers should then be reflected in updated docs.

## Hard rules
- no third-party libraries without asking
- accounts and servers are fine later on. 
- camera footage doesn't leaves the device unless I share it (until we have cloud based hosting)

## Game rules (the flight logic — I decide these)
- Tailwind: finishing at ≥ 80% of estimate → arrive at the destination anyway (miles logged = actual time flown)
- Diverted: finishing below 80% → land at a closer city along the route; the journey continues as a connecting flight next session
- Layover: going over the estimate → land on time, then explore the city — one postcard every 15 min of overtime
- Real mode: 800 km/hour (~13.3 km per focus minute) · Compressed: 10× real (~133 km per focus minute)
- Pausing (holding pattern): no limit
- Destination suggestions: favor famous / large airports over obscure ones (to build in milestone 3)
- Airport data: OurAirports (public domain), filtered by `scripts/build_airports.py` into `Layover/Resources/airports.json`

## Style
- Realistic night-cockpit theme (see the mockups)
- Fonts: Apple's built-in SF Pro (text) and SF Mono (flight data, timers) — no downloaded fonts
- All colors, fonts and spacing come from `Layover/DesignSystem/Theme.swift` — never hard-code them in screens