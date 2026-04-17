#!/usr/bin/env bash
# Shutdown Ugreen DXP2800 NAS
# Run this interactively - it will prompt for sudo password

echo "Shutting down NAS at 192.168.0.158..."
echo "You'll be prompted for your sudo password"
echo ""

ssh pete@192.168.0.158 "sudo shutdown -h now"

echo ""
echo "NAS shutdown initiated. It should power off in a few seconds."
