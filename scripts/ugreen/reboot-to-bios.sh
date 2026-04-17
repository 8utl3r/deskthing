#!/usr/bin/env expect
# Reboot Ugreen DXP2800 directly into BIOS

set timeout 30
set NAS_IP "192.168.0.158"
set NAS_USER "pete"
set NAS_PASS "n0ypSGlWEflFZr"

puts "Rebooting NAS into BIOS/UEFI setup..."
puts ""

spawn ssh -t "$NAS_USER@$NAS_IP" "sudo systemctl reboot --firmware-setup"

expect {
    -re ".*password.*:" {
        send "$NAS_PASS\r"
        exp_continue
    }
    -re ".*\[sudo\].*password" {
        send "$NAS_PASS\r"
        exp_continue
    }
    "(yes/no)" {
        send "yes\r"
        exp_continue
    }
    "Connection closed" {
        puts "NAS is rebooting into BIOS..."
        exit 0
    }
    timeout {
        puts "Reboot initiated (connection may close)"
        exit 0
    }
    eof {
        puts "NAS is rebooting into BIOS..."
        exit 0
    }
}

expect eof
