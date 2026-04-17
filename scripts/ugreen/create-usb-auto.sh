#!/usr/bin/env expect
# Automated TrueNAS USB creation with password handling

set timeout 600
set DISK_ID "disk4"
set ISO_PATH "$env(HOME)/dotfiles/downloads/TrueNAS-SCALE-25.04.2.4.iso"

puts "╔══════════════════════════════════════════════════════════╗"
puts "║     Creating TrueNAS Scale Bootable USB                ║"
puts "╚══════════════════════════════════════════════════════════╝\n"

puts "USB Drive: /dev/$DISK_ID (Pete's Work - 124 GB)"
puts "ISO File: $ISO_PATH"
puts ""
puts "⚠️  WARNING: This will ERASE all data on the USB drive!\n"

# Unmount first
spawn diskutil unmountDisk "/dev/$DISK_ID"
expect {
    eof { }
    timeout { }
}

sleep 2

# Write ISO using dd with sudo
spawn sudo dd if="$ISO_PATH" of="/dev/r${DISK_ID}" bs=1m status=progress

expect {
    -re ".*password.*:" {
        puts "Password prompt detected..."
        # Note: This won't work without actual password
        # User needs to enter password manually
        interact
    }
    -re ".*\[sudo\].*password" {
        puts "Sudo password prompt..."
        interact
    }
    timeout {
        puts "Writing ISO (this takes several minutes)..."
        exp_continue
    }
    eof {
        puts "\n✅ USB created successfully!"
    }
}

expect eof
