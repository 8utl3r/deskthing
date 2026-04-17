#!/usr/bin/env expect
# Working shutdown script for Ugreen DXP2800

set timeout 60
set NAS_IP "192.168.0.158"
set NAS_USER "pete"
set NAS_PASS "n0ypSGlWEflFZr"

puts "Connecting to NAS and shutting down..."
puts ""

spawn ssh -t "$NAS_USER@$NAS_IP" "sudo shutdown -h now"

expect {
    -re ".*password.*:" {
        puts "Password prompt detected, sending password..."
        send "$NAS_PASS\r"
        exp_continue
    }
    -re ".*\[sudo\].*password" {
        puts "Sudo password prompt detected, sending password..."
        send "$NAS_PASS\r"
        exp_continue
    }
    "Broadcast message" {
        puts "Shutdown initiated!"
        exp_continue
    }
    "The system is going down" {
        puts "System is shutting down..."
        exp_continue
    }
    timeout {
        puts "Timeout - checking if shutdown worked..."
        exit 0
    }
    eof {
        puts "Connection closed - shutdown may have completed"
        exit 0
    }
}

expect eof
