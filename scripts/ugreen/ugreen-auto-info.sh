#!/usr/bin/env expect
# Automated system information gathering for Ugreen DXP2800
# Uses expect to handle password entry automatically

set timeout 30
set NAS_IP "192.168.0.158"
set NAS_USER "Pete"
set NAS_PASS "n0ypSGlWEflFZr"

spawn ssh "$NAS_USER@$NAS_IP" "uname -a && echo '---' && cat /etc/os-release 2>/dev/null || echo 'No os-release' && echo '---' && lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE && echo '---' && ip addr show && echo '---' && (lspci 2>/dev/null | grep -iE 'nvme|network|ethernet|intel' || echo 'lspci not available') && echo '---' && df -h && echo '---' && (ls -la /dev/mmcblk* 2>/dev/null || echo 'No mmcblk') && echo '---' && (ls -la /dev/nvme* 2>/dev/null || echo 'No nvme') && echo '---' && (ls -la /dev/sd* 2>/dev/null || echo 'No sda') && echo '---' && hostname && uptime"

expect {
    -re "(password|Password):" {
        send "$NAS_PASS\r"
        exp_continue
    }
    "(yes/no)" {
        send "yes\r"
        exp_continue
    }
    "Permission denied" {
        puts "ERROR: Authentication failed. Check username/password."
        exit 1
    }
    timeout {
        puts "ERROR: Connection timed out"
        exit 1
    }
    eof {
        catch wait result
        exit [lindex $result 3]
    }
}

expect eof
