#!/usr/bin/env expect
# Backup UGOS firmware from eMMC to SATA storage

set timeout 3600
set NAS_IP "192.168.0.158"
set NAS_USER "pete"
set NAS_PASS "n0ypSGlWEflFZr"

puts "=== UGOS Firmware Backup ==="
puts "Backing up eMMC (/dev/mmcblk0) to /volume1/ugos_backup.img"
puts "This will take several minutes..."
puts ""

spawn ssh -t "$NAS_USER@$NAS_IP" "sudo dd if=/dev/mmcblk0 of=/volume1/ugos_backup.img bs=4M status=progress"

expect {
    -re ".*password.*:" {
        send "$NAS_PASS\r"
        exp_continue
    }
    -re ".*\[sudo\].*password" {
        send "$NAS_PASS\r"
        exp_continue
    }
    -re ".*copied.*bytes" {
        puts "$expect_out(0,string)"
        exp_continue
    }
    timeout {
        puts "Backup in progress (this is normal, it takes time)..."
        exp_continue
    }
    eof {
        puts "Backup completed!"
        exit 0
    }
}

expect eof
