#!/usr/bin/env expect
# Automated shutdown of Ugreen DXP2800 NAS

set timeout 30
set NAS_IP "192.168.0.158"
set NAS_USER "pete"
set NAS_PASS "n0ypSGlWEflFZr"

spawn ssh -t "$NAS_USER@$NAS_IP" "sudo shutdown -h now"

expect {
    -re "password for $NAS_USER:" {
        send "$NAS_PASS\r"
        exp_continue
    }
    -re "\[sudo\] password" {
        send "$NAS_PASS\r"
        exp_continue
    }
    -re "(password|Password):" {
        send "$NAS_PASS\r"
        exp_continue
    }
    "(yes/no)" {
        send "yes\r"
        exp_continue
    }
    "Broadcast message" {
        puts "Shutdown initiated!"
        exp_continue
    }
    timeout {
        puts "Timeout waiting for prompt"
        exit 1
    }
    eof {
        puts "Shutdown command completed"
        exit 0
    }
}

expect eof
