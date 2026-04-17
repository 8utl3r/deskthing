#!/usr/bin/env python3
"""
Star Trek Redshirt Names
Famous red shirt characters who died in Star Trek episodes
"""

REDSHIRT_NAMES = [
    "Lee_Kelso",      # First redshirt (pilot episode)
    "Darnell",        # First crewman to die (The Man Trap)
    "Mathews",        # First to die in red shirt (What Are Little Girls Made Of?)
    "Rayburn",        # Suffocated by Ruk
    "Tomlinson",      # Exposed to phaser coolant
    "Tormolen",       # Self-inflicted during polywater intoxication
    "Green",          # Killed by salt vampire
    "Gaetano",        # Killed by Gorn
    "O'Herlihy",      # Killed by Gorn
    "Latimer",        # Killed by Horta
    "Schmitter",      # Killed by Horta
    "Johanson",       # Killed by Horta
    "Brenner",        # Killed by Horta
    "Vince",          # Killed by Horta
    "O'Neil",         # Killed by Horta
    "Fisher",         # Killed by Horta
    "Kaplan",         # Killed by Horta
    "Esteban",        # Killed by Horta
    "Rizzo",          # Killed by Horta
    "Appel",          # Killed by Horta
]

def get_redshirt_name(index: int) -> str:
    """Get a redshirt name by index (cycles through list)."""
    return REDSHIRT_NAMES[index % len(REDSHIRT_NAMES)]
