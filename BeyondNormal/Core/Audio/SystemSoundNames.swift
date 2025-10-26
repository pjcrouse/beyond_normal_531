//
//  SystemSoundNames.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/26/25.
//

import Foundation

/// Community-verified mapping of common iOS SystemSoundIDs → human-readable names.
/// Not all IDs exist on every device or iOS version.
let systemSoundNames: [Int: String] = [
    // --- New Mail / Sent Mail / SMS / Calendar / etc ---
    1000: "New Mail",
    1001: "Mail Sent",
    1002: "Voicemail",
    1003: "Received Message",
    1004: "Sent Message",
    1005: "Alarm",
    1006: "Low Power",
    1007: "SMS Received 1",
    1008: "SMS Received 2",
    1009: "SMS Received 3",
    1010: "SMS Received 4",
    1011: "SMS Received 5",
    1012: "SMS Received 6",
    1013: "Tweet Sent",

    // --- “Classic” tones (from early iOS versions) ---
    1014: "Anticipate",
    1015: "Bloom",
    1016: "Calypso",
    1017: "Choo Choo",
    1018: "Descent",
    1019: "Fanfare",
    1020: "Ladder",
    1021: "Minuet",
    1022: "News Flash",
    1023: "Noir",
    1024: "Sherwood Forest",
    1025: "Spell",
    1026: "Suspense",
    1027: "Telegraph",
    1028: "Tiptoes",
    1029: "Typewriters",
    1030: "Update",

    // --- System alert sounds (UI feedback / misc) ---
    1050: "Tink",
    1051: "Glass",
    1052: "Horn",
    1053: "Bell",
    1054: "Electronic",
    1057: "Mail Sent (Classic)",

    // --- Keyboard, lock, camera shutter, etc. ---
    1100: "Beep-Beep",
    1101: "Clang",
    1102: "Tock",
    1103: "Buzz",
    1104: "Bloom Pop",
    1105: "Drip",
    1106: "Click",
    1107: "Typing Click",
    1108: "Lock",
    1109: "Unlock",
    1110: "Camera Shutter",
    1111: "Camera Timer",
    1112: "Photo Confirmation",
    1113: "Begin Video Recording",
    1114: "End Video Recording",
    1115: "VC Invite",
    1116: "VC Ringing",
    1117: "VC End Call",
    1118: "VC Connection Failed",
    1119: "Screen Capture",

    // --- Other tones ---
    1200: "Shake",
    1201: "Slide-to-Unlock",
    1202: "Vibrate",
    1203: "Silent",
    1204: "Success",
    1205: "Failure",
    1206: "Received",
    1207: "Sent",
    1208: "KeyPress",
    1209: "Delete",
    1210: "Alert Tone",

    // --- “Anticipation / Note / etc.” from later iOS ---
    1300: "Note",
    1301: "Chord",
    1302: "Pulse",
    1303: "Piano",
    1304: "Glass Ping",
    1305: "Bright",
    1306: "Pop",
    1307: "PowerUp",
    1308: "PowerDown",
    1309: "Connect",
    1310: "Disconnect",
    1311: "Navigation Tap",
    1312: "Navigation Error",
    1313: "Navigation Complete",
    1314: "Multi-Tap",
    1315: "Tone",
    1316: "Ripple",
    1317: "Tone Short",
    1318: "Alert Short",
    1319: "Chime Short",
    1320: "Tinkling Bells",
    1321: "Buzz (Alt)",
    1322: "Anticipation",
    1323: "Drum",
    1324: "Glass Chime",
    1325: "Ping",
    1326: "Swish",
    1327: "Whistle",
    1330: "Popcorn",
    1331: "Boing",
    1332: "Drop",
    1333: "Flick",
    1334: "Sparkle",
    1335: "Note (Alt)"
]
