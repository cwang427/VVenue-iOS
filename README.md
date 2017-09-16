# VVenue

## Overview

**VVenue** is an event ticketing, check-in, and hosting service designed to streamline everyday routines. Gone are the days of forgetten tickets, and say goodbye to clumsily fumbling around with papers and cards. You are your own ticket – all you need to do is register ahead of time with a picture of your stunning visage and a single word that can be used to confirm your identity. Whether used for concerts, public transportation, or more, VVenue helps to eliminate long lines and allows all of us to experience more of what matters most.
VVenue uses Microsoft's Cognitive Services FaceAPI to detect and identify people based on facial features. We have also made use of the Speech framework released alongside iOS 10.

## How to Use VVenue

### Before Heading Out
For users, register for an event online (in theory, that is – we didn't make a website for the hackathon), upload a picture of your face, and tell us your favorite word. Congrats, you're all set!

For hosts, create an event and distribute event IDs to those interested in attending. The app will take care of checking in on site.

### On the Go
If you've registered for an event or purchased a spot on the bus ahead of time, it's as easy as strolling right in. Facial recognition will check you in, and if the algorithm's confidence level is less than satisfactory, you may be prompted to say your key word to confirm your place.

## Why is this Important?
Time is the most valuable resource. When you have to wait in line or take time to display a ticket or QR code, those seconds add up and the delay propagates to those around you. Especially in busy metropolitan areas, these delays cause people to be late to school or work; by expediting the day-to-day processes, we envision a fluid, more productive society.

## Future Directions
* Saved user profiles: implement disk persistence on mobile using Realm.
* Register for events on mobile: mobile app currently possesses capability but cannot make the respective changes in the database.
* VVenue would become an even more powerful tool by enabling users to pay for events or services in advance. We considered using Capital One's Nessie API for this purpose.
