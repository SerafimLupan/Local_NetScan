# Local_NetScan 🛡️

A professional Bash script for automated local network discovery, host identification, and port scanning.

## 🚀 Features
- **Auto-Subnet Detection**: Automatically identifies your local network range.
- **Dual-Method Discovery**: Uses both `arp-scan` and `nmap` for maximum accuracy.
- **Automated Logging**: Saves results into timestamped log files (`scan_YYYYMMDD_HHMMSS.log`).
- **Interactive Port Scan**: Quick service/version detection for specific targets.
- **Clean UI**: Color-coded terminal output with a custom banner.

## 📋 Prerequisites
The tool requires the following packages:
- `nmap`
- `arp-scan`

Install them on Debian/Ubuntu using:
  `sudo apt update && sudo apt install nmap arp-scan -y`
  
##🛠️ Installation & Usage

1. Clone the repository:
   ```bahs 
    git clone [https://github.com/SerafimLupan/Local_NetScan.git](https://github.com/SerafimLupan/Local_NetScan.git)
    cd Local_NetScan
3. Give execution permissions:
   ```bash
    chmod +x local_netscan.sh
4. Run with sudo:
   ```bash
   sudo ./local_netscan.sh
##👤 Author

Lupan "Tirasp0l" Serafim  
   Website: https://serafimlupan.com
