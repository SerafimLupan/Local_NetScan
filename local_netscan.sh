#!/bin/bash

# --- Color Codes (Matrix Green Palette) ---
C1="\e[38;5;22m"  # Darkest
C2="\e[38;5;28m"
C3="\e[38;5;34m"
C4="\e[38;5;40m"
C5="\e[38;5;46m"
C6="\e[38;5;82m"  # Lightest
NC="\e[0m"        # No Color

# --- Privilege Check ---
# Most scanning tools (arp-scan, nmap raw sockets) require root
if [[ $EUID -ne 0 ]]; then
   echo -e "${C1}[!] Error: This script must be run as ROOT (sudo).${NC}"
   exit 1
fi

# --- Dependency Check ---
for cmd in arp-scan nmap awk ip; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${C1}[!] Error: $cmd is not installed. Install it with: apt install $cmd${NC}"
    exit 1
  fi
done

# --- Print Custom Banner ---
clear
echo -e "${C1}ooooo                                     oooo              ooooo      ooo               .    .oooooo..o                                   ${NC}"
echo -e "${C2}\`888'                                     \`888              \`888b.     \`8'             .o8   d8P'    \`Y8                                   ${NC}"
echo -e "${C3} 888          .ooooo.   .ooooo.   .oooo.    888               8 \`88b.    8  .ooooo.  .o888oo Y88bo.        .ooooo.   .oooo.   ooo. .oo.    ${NC}"
echo -e "${C4} 888         d88' \`88b d88' \`\"Y8 \`P  )88b   888               8   \`88b.  8 d88' \`88b   888    \`\"Y8888o.  d88' \`\"Y8 \`P  )88b  \`888P\"Y88b   ${NC}"
echo -e "${C5} 888         888   888 888         .oP\"888   888               8      \`88b.8 888ooo888   888        \`\"Y88b 888         .oP\"888   888   888   ${NC}"
echo -e "${C6} 888       o 888   888 888   .o8 d8(  888   888               8        \`888 888    .o   888 . oo     .d8P 888   .o8 d8(  888   888   888   ${NC}"
echo -e "${C6}o888ooooood8 \`Y8bod8P' \`Y8bod8P' \`Y888\"\"8o o888o ooooooooooo o8o         \`8  \`Y8bod8P'   \"888\" 8\"\"88888P'  \`Y8bod8P' \`Y888\"\"8o o888o o888o ${NC}"
echo -e ""
echo -e "                   | by Lupan \"Tirasp0l\" Serafim | more info: serafimlupan.com |"
echo -e "--------------------------------------------------------------------------------------------------------\n"

# --- Interface Selection Phase ---
echo -e "${C5}[*] Detecting active network interfaces...${NC}"

# Filter interfaces that are UP and ignore loopback (lo)
mapfile -t interfaces < <(ip -o link show | awk -F': ' '$3 ~ /UP/ {print $2}' | grep -v "lo")

if [ ${#interfaces[@]} -eq 0 ]; then
    echo -e "${C1}[!] No active network interfaces found!${NC}"
    exit 1
fi

echo -e "${C6}Please select the interface to use:${NC}"
select SELECTED_IFACE in "${interfaces[@]}" "Exit"; do
    if [[ "$SELECTED_IFACE" == "Exit" ]]; then
        exit 0
    elif [[ -n "$SELECTED_IFACE" ]]; then
        # Capture the CIDR subnet for the chosen interface
        TARGET=$(ip -o -f inet addr show "$SELECTED_IFACE" | awk '{print $4}' | head -n 1)
        
        if [[ -z "$TARGET" ]]; then
            echo -e "${C1}[!] No IP address found on $SELECTED_IFACE. Select another.${NC}"
            continue
        fi
        break
    else
        echo -e "${C1}[!] Invalid choice. Select a number from the list.${NC}"
    fi
done

# --- Logging Configuration ---
LOGFILE="scan_${SELECTED_IFACE}_$(date +%Y%m%d_%H%M%S).log"
echo -e "\n${C4}[+] Selected Interface: $SELECTED_IFACE${NC}"
echo -e "${C4}[+] Network Subnet:    $TARGET${NC}"
echo -e "${C4}[+] Session Log:       $LOGFILE${NC}\n"

# Silently ensure vendor files are readable for arp-scan
chmod +r /usr/share/arp-scan/*.txt 2>/dev/null

# --- Phase 1: Host Discovery ---
echo -e "${C5}[*] Discovering active hosts on $SELECTED_IFACE...${NC}"
{
    echo "=========================================================="
    echo " DISCOVERY START: $(date)"
    echo " Target: $TARGET | Interface: $SELECTED_IFACE"
    echo "=========================================================="
    echo -e "\n[ARP-SCAN RESULTS]"
    arp-scan --interface="$SELECTED_IFACE" --localnet --ignoredups
    echo -e "\n[NMAP PING SWEEP RESULTS]"
    nmap -sn "$TARGET"
    echo -e "\n=========================================================="
    echo " DISCOVERY END: $(date)"
    echo "=========================================================="
} | tee "$LOGFILE"

# --- Phase 2: Interactive Port Scanning ---
echo -e "\n${C6}Would you like to perform a detailed port scan on a specific target? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${C6}Enter the Target IP address:${NC}"
    read -r scan_ip
    
    if [[ -z "$scan_ip" ]]; then
        echo -e "${C1}[!] Empty input. Skipping detailed scan.${NC}"
    else
        echo -e "\n${C4}[*] Starting Service Versioning & Default Scripts on $scan_ip...${NC}"
        # -sV: Probe open ports to determine service/version info
        # -sC: Run default nmap scripts (NSE)
        # -Pn: Skip host discovery (assume host is up)
        # -T4: Aggressive timing for faster results
        nmap -sV -sC -Pn -T4 "$scan_ip" | tee -a "$LOGFILE"
        echo -e "\n${C3}>>> Detailed scan complete. Results logged.${NC}"
    fi
else
    echo -e "\n${C3}>>> Skipping port scan.${NC}"
fi

# --- Wrap up ---
echo -e "\n${C1}>>> All tasks finished. Review your log at: $LOGFILE${NC}"
