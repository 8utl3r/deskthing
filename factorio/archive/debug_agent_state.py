#!/usr/bin/env python3
"""
Debug Agent State

Simple tool to continuously monitor agent state and identify stuck conditions.
Run this while the agent is running to see what's happening.
"""

import sys
import time
import json
from config import RCON_HOST, RCON_PORT, RCON_PASSWORD
from factorio_ollama_npc_controller import FactorioNPCController


def monitor_agent(agent_id: str, duration: int = 300, interval: float = 2.0):
    """
    Monitor agent state continuously to identify stuck conditions.
    
    Args:
        agent_id: Agent ID to monitor
        duration: How long to monitor (seconds)
        interval: How often to check (seconds)
    """
    print(f"\nMonitoring agent {agent_id} for {duration} seconds...")
    print("Press Ctrl+C to stop early\n")
    
    controller = FactorioNPCController(
        rcon_host=RCON_HOST,
        rcon_port=RCON_PORT,
        rcon_password=RCON_PASSWORD
    )
    
    start_time = time.time()
    last_position = None
    stuck_count = 0
    last_state_hash = None
    
    try:
        while time.time() - start_time < duration:
            # Get agent state
            agent_state = controller.get_agent_state(agent_id)
            is_busy = controller.is_agent_busy(agent_id)
            
            if not agent_state:
                print(f"[{int(time.time() - start_time)}s] ❌ Could not get agent state")
                time.sleep(interval)
                continue
            
            # Extract key info
            pos = agent_state.get('position', {})
            if isinstance(pos, dict):
                current_pos = (pos.get('x', 0), pos.get('y', 0))
            else:
                current_pos = None
            
            state = agent_state.get('state', {})
            walking = state.get('walking', {})
            mining = state.get('mining', {})
            crafting = state.get('crafting', {})
            
            # Check if stuck (same position for multiple checks)
            if current_pos and last_position:
                if current_pos == last_position:
                    stuck_count += 1
                else:
                    stuck_count = 0
            
            last_position = current_pos
            
            # Create state hash to detect if state is changing
            state_hash = hash(str({
                'pos': current_pos,
                'walking': walking,
                'mining': mining,
                'crafting': crafting
            }))
            
            # Format output
            timestamp = int(time.time() - start_time)
            status = "🟢" if is_busy else "🔴"
            
            print(f"[{timestamp:3d}s] {status} Pos: {current_pos} | Busy: {is_busy}")
            
            if walking:
                print(f"         Walking: {walking}")
            if mining:
                print(f"         Mining: {mining}")
            if crafting:
                print(f"         Crafting: {crafting}")
            
            # Detect stuck conditions
            if stuck_count > 5:
                print(f"         ⚠️  STUCK DETECTED: Same position for {stuck_count} checks!")
            
            if state_hash == last_state_hash and is_busy:
                print(f"         ⚠️  State not changing but agent reports busy!")
            
            last_state_hash = state_hash
            
            time.sleep(interval)
            
    except KeyboardInterrupt:
        print("\n\nMonitoring stopped by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        controller.close()


def main():
    """Main entry point."""
    if len(sys.argv) > 1:
        agent_id = sys.argv[1]
    else:
        # Try to find existing agent
        controller = FactorioNPCController(
            rcon_host=RCON_HOST,
            rcon_port=RCON_PORT,
            rcon_password=RCON_PASSWORD
        )
        agents = controller.list_agents()
        if agents:
            agent_id = agents[0]
            print(f"Using existing agent: {agent_id}")
        else:
            print("No agents found. Please provide agent ID as argument.")
            print("Usage: python debug_agent_state.py [agent_id]")
            return
        controller.close()
    
    duration = int(sys.argv[2]) if len(sys.argv) > 2 else 300
    monitor_agent(agent_id, duration)


if __name__ == "__main__":
    main()
