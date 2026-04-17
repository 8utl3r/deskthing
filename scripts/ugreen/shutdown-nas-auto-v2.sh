#!/usr/bin/env expect
# Automated shutdown of Ugreen DXP2800 NAS (with pseudo-terminal)

set timeout 30
set NAS_IP "192.168.0.158"
set NAS_USER "pete"
set NAS_PASS "n0ypSGlWEflFZr"

spawn ssh -t "$NAS_USER@$NAS_IP" "sudo shutdown -h now"

expect {
    -re "(password|Password):" {
        send "$NAS_PASS\r"
        exp_continue
    }
    "sudo:" {
        send "$NAS_PASS\r"
        exp_continue
    }
    "(yes/no)" {
        send "yes\r"
        exp_continue
    }
    timeout {
        puts "Connection timed out"
        exit 1
    }
    eof {
        puts "Shutdown command executed"
        exit 0
    }
}

expect eof
