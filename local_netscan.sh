#!/bin/bash

# Define the green color codes
C1="\e[38;5;22m"  # Darkest
C2="\e[38;5;28m"
C3="\e[38;5;34m"
C4="\e[38;5;40m"
C5="\e[38;5;46m"
C6="\e[38;5;82m"  # Lightest
NC="\e[0m"        # No Color

# Print the Banner
echo -e "${C1}\" ██                                   ██   ████     ██           ██    ████████                           \"${NC}"
echo -e "${C2}\"░██                                  ░██  ░██░██   ░██          ░██   ██░░░░░░                            \"${NC}"
echo -e "${C3}\"░██        ██████   █████   ██████   ░██  ░██░░██  ░██  █████  ██████░██         █████   ██████   ███████ \"${NC}"
echo -e "${C4}\"░██       ██░░░░██ ██░░░██ ░░░░░░██  ░██  ░██ ░░██ ░██ ██░░░██░░░██░ ░█████████ ██░░░██ ░░░░░░██ ░░██░░░██\"${NC}"
echo -e "${C5}\"░██      ░██   ░██░██  ░░   ███████  ░██  ░██  ░░██░██░███████  ░██  ░░░░░░░░██░██  ░░   ███████  ░██  ░██\"${NC}"
echo -e "${C6}\"░██      ░██   ░██░██   ██ ██░░░░██  ░██  ░██   ░░████░██░░░░   ░██         ░██░██   ██ ██░░░░██  ░██  ░██\"${NC}"
echo -e "${C6}\"░████████░░██████ ░░█████ ░░████████ ███  ░██    ░░███░░██████  ░░██  ████████ ░░█████ ░░████████ ███  ░██\"${NC}"
echo -e "${C6}\"░░░░░░░░  ░░░░░░   ░░░░░   ░░░░░░░░ ░░░   ░░      ░░░  ░░░░░░    ░░  ░░░░░░░░   ░░░░░   ░░░░░░░░ ░░░   ░░ \"${NC}"
echo -e ""
echo -e "\"                                  |  by Lupan \"Tirasp0l \" Serafim         |                                  \""
echo -e "\"                                  |  more info on https://serafimlupan.com  |                                  \""
# Setup Logging
LOGFILE="scan_$(date +%Y%m%d_%H%M%S).log"

# Detect the local network range
SUBNET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -n 1)
TARGET=${SUBNET:-"192.168.1.0/24"}

echo -e "\n${C4}>>> Detected Subnet: $TARGET${NC}"
echo -e "${C4}>>> Results will be saved to: $LOGFILE${NC}\n"

# Fix arp-scan vendor file permissions
sudo chmod +r /usr/share/arp-scan/*.txt 2>/dev/null

# Initial Host Discovery
{
    echo "--- DISCOVERY START: $(date) ---"
    echo -e "\n[*] Running Host Discovery (arp-scan & nmap ping sweep)..."
    sudo arp-scan --localnet
    echo -e "\n------------------------------------------------------------\n"
    sudo nmap -sn $TARGET
    echo "--- DISCOVERY END: $(date) ---"
} | tee "$LOGFILE"

# Port Scanning Section
echo -e "\n${C5}Would you like to perform a port scan on a specific target? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${C6}Enter the IP address to scan:${NC}"
    read -r scan_ip
    
    echo -e "\n${C4}[*] Starting Service & Version Scan on $scan_ip...${NC}"
    # -sV: Version detection, -T4: Faster execution, -F: Top 100 ports
    sudo nmap -sV -T4 -F "$scan_ip" | tee -a "$LOGFILE"
    
    echo -e "\n${C3}>>> Port scan complete and logged.${NC}"
else
    echo -e "\n${C3}>>> Skipping port scan.${NC}"
fi

echo -e "\n${C1}>>> All tasks finished. Log: $LOGFILE${NC}"
