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
for cmd in arp-scan nmap awk ip tcpdump; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${C1}[!] Error: $cmd is not installed. Install it with: apt install $cmd${NC}"
    exit 1
  fi
done

# --- Print Custom Banner ---
clear
echo -e "${C1}ooooo                                      oooo              ooooo       ooo               .    .oooooo..o                                   ${NC}"
echo -e "${C2}\`888'                                      \`888              \`888b.      \`8'             .o8   d8P'    \`Y8                                   ${NC}"
echo -e "${C3} 888          .ooooo.   .ooooo.   .oooo.    888               8 \`88b.     8  .ooooo.  .o888oo Y88bo.        .ooooo.   .oooo.   ooo. .oo.    ${NC}"
echo -e "${C4} 888         d88' \`88b d88' \`\"Y8 \`P  )88b   888               8   \`88b.   8 d88' \`88b   888    \`\"Y8888o.   d88' \`\"Y8 \`P  )88b  \`888P\"Y88b   ${NC}"
echo -e "${C5} 888         888   888 888        .oP\"888   888               8      \`88b.8 888ooo888   888        \`\"Y88b  888        .oP\"888   888   888   ${NC}"
echo -e "${C6} 888       o 888   888 888   .o8 d8(  888   888               8        \`888 888    .o   888  . oo    .d8P  888   .o8 d8(  888   888   888   ${NC}"
echo -e "${C6}o888ooooood8 \`Y8bod8P' \`Y8bod8P' \`Y888\"\"8o o888o ooooooooooo o8o         \`8  \`Y8bod8P'   \"888\" 8\"\"88888P'  \`Y8bod8P' \`Y888\"\"8o o888o o888o ${NC}"
echo -e ""
echo -e "                                              LOCAL_NETSCAN v3.0 - ADVANCED RECON"
echo -e "                                 | by Lupan \"Tirasp0l\" Serafim | more info: serafimlupan.com |"
echo -e "-------------------------------------------------------------------------------------------------------------------------------------------\n"

# --- Interface Selection Phase ---

mapfile -t interfaces < <(ip -o link show | awk -F': ' '$3 ~ /UP/ {print $2}' | grep -v "lo")
echo -e "${C5}[*] Select Interface:${NC}"
select SELECTED_IFACE in "${interfaces[@]}" "Exit"; do
    [[ "$SELECTED_IFACE" == "Exit" ]] && exit 0
    if [[ -n "$SELECTED_IFACE" ]]; then
        TARGET=$(ip -o -f inet addr show "$SELECTED_IFACE" | awk '{print $4}' | head -n 1)
        break
    fi
done

LOGFILE="NetScan_${SELECTED_IFACE}_$(date +%H%M).log"

# --- Functions ---

passive_listen() {
    echo -e "${C4}[*] Entering Passive Stealth Mode (60s)...${NC}"
    echo -e "${C2}Listening for ARP and MDNS traffic to identify hosts silently...${NC}"
    # Ascultă trafic ARP și DNS/MDNS pentru a identifica dispozitivele care "vorbesc" singure
    timeout 60 tcpdump -i "$SELECTED_IFACE" -n arp or port 5353 2>/dev/null | awk '{print $3 " is active"}' | sort -u
}

deep_recon() {
    echo -e "${C5}[*] Running Full Aggressive Recon on $TARGET...${NC}"
    sudo nmap -A -T4 -p 22,80,443,445,3389,8080 "$TARGET" | tee -a "$LOGFILE"
}

vuln_audit() {
    echo -e "${C6}Enter Target IP for Vuln Scan:${NC}"
    read -r t_ip
    sudo nmap --script vuln -p- -T4 "$t_ip" | tee -a "$LOGFILE"
}

service_hunt() {
    echo -e "${C6}Enter port to hunt (e.g. 80, 22, 3389):${NC}"
    read -r port
    echo -e "${C4}[*] Searching for port $port in the whole network...${NC}"
    sudo nmap -p "$port" --open "$TARGET" | grep "Nmap scan report"
}

# --- Main Menu Loop ---
while true; do
    echo -e "\n${C3}==== MAIN MENU ====${NC}"
    echo -e "1) Quick Discovery (ARP)"
    echo -e "2) Ghost Discovery (No-Ping)"
    echo -e "3) Deep Recon (OS/Versions)"
    echo -e "4) Service Hunt (Find specific port)"
    echo -e "5) Passive Listening (Stealth)"
    echo -e "6) Vulnerability Audit"
    echo -e "7) Exit"
    read -p "Choose option: " opt

    case $opt in
        1) echo -e "\n[$(date)] ARP Scan" >> "$LOGFILE"; sudo arp-scan --interface="$SELECTED_IFACE" --localnet | tee -a "$LOGFILE" ;;
        2) sudo nmap -sn -Pn -PS80,443,445 "$TARGET" | tee -a "$LOGFILE" ;;
        3) deep_recon ;;
        4) service_hunt ;;
        5) passive_listen ;;
        6) vuln_audit ;;
        7) exit 0 ;;
        *) echo "Invalid option." ;;
    esac
done
                                                                                                                                                                                                                                             
