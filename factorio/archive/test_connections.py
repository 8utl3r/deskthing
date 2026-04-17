#!/usr/bin/env python3
"""
Test script to verify RCON and Ollama connections before running NPC controller.
"""

import sys
import json

def test_rcon():
    """Test RCON connection to Factorio server."""
    print("=" * 60)
    print("Testing RCON Connection")
    print("=" * 60)
    
    try:
        from config import RCON_HOST, RCON_PORT, RCON_PASSWORD
        import factorio_rcon
        
        print(f"Connecting to {RCON_HOST}:{RCON_PORT}...")
        factorio = factorio_rcon.RCONClient(RCON_HOST, RCON_PORT, RCON_PASSWORD)
        factorio.connect()
        
        # Test with a simple command
        print("Sending test command: /sc game.print('RCON test successful')")
        response = factorio.send_command("/sc game.print('RCON test successful')")
        print(f"✅ RCON Connection: SUCCESS")
        print(f"   Response: {response[:100]}..." if len(response) > 100 else f"   Response: {response}")
        return True
        
    except ImportError as e:
        print(f"❌ RCON Connection: FAILED - Missing dependency")
        print(f"   Error: {e}")
        print(f"   Install with: pip install factorio-rcon-py")
        return False
    except Exception as e:
        print(f"❌ RCON Connection: FAILED")
        print(f"   Error: {e}")
        print(f"   Check:")
        print(f"   - Factorio server is running")
        print(f"   - RCON is enabled (check server logs)")
        print(f"   - RCON password is correct in config.py")
        print(f"   - Network connectivity to {RCON_HOST}:{RCON_PORT}")
        return False


def test_ollama():
    """Test Ollama connection and model availability."""
    print("\n" + "=" * 60)
    print("Testing Ollama Connection")
    print("=" * 60)
    
    try:
        from config import OLLAMA_MODEL, OLLAMA_HOST, OLLAMA_PORT
        import ollama
        import os
        
        # Set Ollama host if not default
        if OLLAMA_HOST != "localhost" or OLLAMA_PORT != 11434:
            os.environ['OLLAMA_HOST'] = f"{OLLAMA_HOST}:{OLLAMA_PORT}"
            print(f"Using Ollama at {OLLAMA_HOST}:{OLLAMA_PORT}")
        else:
            print(f"Using Ollama at localhost:11434 (default)")
        
        print(f"Testing model: {OLLAMA_MODEL}")
        
        # Test with a simple query
        response = ollama.chat(
            model=OLLAMA_MODEL,
            messages=[
                {"role": "user", "content": "Say 'Ollama test successful' if you can read this."}
            ]
        )
        
        content = response['message']['content']
        print(f"✅ Ollama Connection: SUCCESS")
        print(f"   Model: {OLLAMA_MODEL}")
        print(f"   Response: {content[:100]}..." if len(content) > 100 else f"   Response: {content}")
        return True
        
    except ImportError as e:
        print(f"❌ Ollama Connection: FAILED - Missing dependency")
        print(f"   Error: {e}")
        print(f"   Install with: pip install ollama")
        return False
    except Exception as e:
        print(f"❌ Ollama Connection: FAILED")
        print(f"   Error: {e}")
        print(f"   Check:")
        print(f"   - Ollama is running: ollama serve")
        print(f"   - Model is available: ollama list")
        print(f"   - Model name is correct in config.py: {OLLAMA_MODEL}")
        if OLLAMA_HOST != "localhost":
            print(f"   - Network connectivity to {OLLAMA_HOST}:{OLLAMA_PORT}")
        return False


def test_config():
    """Test that config.py is properly set up."""
    print("\n" + "=" * 60)
    print("Testing Configuration")
    print("=" * 60)
    
    try:
        from config import (
            RCON_HOST, RCON_PORT, RCON_PASSWORD,
            OLLAMA_MODEL, OLLAMA_HOST, OLLAMA_PORT
        )
        
        print("✅ Configuration loaded successfully")
        print(f"   RCON: {RCON_HOST}:{RCON_PORT}")
        print(f"   RCON Password: {'*' * len(RCON_PASSWORD) if RCON_PASSWORD else 'NOT SET'}")
        print(f"   Ollama: {OLLAMA_HOST}:{OLLAMA_PORT}")
        print(f"   Model: {OLLAMA_MODEL}")
        
        if not RCON_PASSWORD:
            print("⚠️  WARNING: RCON_PASSWORD is not set!")
            return False
        
        return True
        
    except ImportError as e:
        print(f"❌ Configuration: FAILED")
        print(f"   Error: {e}")
        print(f"   Make sure config.py exists in the same directory")
        return False
    except Exception as e:
        print(f"❌ Configuration: FAILED")
        print(f"   Error: {e}")
        return False


def main():
    """Run all tests."""
    print("\n" + "=" * 60)
    print("Factorio NPC Controller - Connection Tests")
    print("=" * 60)
    print()
    
    results = []
    
    # Test config first
    results.append(("Configuration", test_config()))
    
    # Test RCON
    results.append(("RCON", test_rcon()))
    
    # Test Ollama
    results.append(("Ollama", test_ollama()))
    
    # Summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    
    all_passed = True
    for name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}: {name}")
        if not passed:
            all_passed = False
    
    print()
    if all_passed:
        print("🎉 All tests passed! You're ready to run the NPC controller.")
        print("\nNext steps:")
        print("1. Make sure FV Embodied Agent mod is installed on Factorio server")
        print("2. Run: python factorio_ollama_npc_controller.py")
    else:
        print("⚠️  Some tests failed. Please fix the issues above before running the controller.")
        sys.exit(1)


if __name__ == "__main__":
    main()
