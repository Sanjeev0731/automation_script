#!/bin/bash

# Advanced Automated Recon Script
# Usage: ./recon.sh <domain>
# Performs subdomain enum, liveness check, and aggressive Nmap scanning

# Check if domain is passed
if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

# Variables
TARGET=$1
OUTPUT_DIR="$TARGET"
SUBS_FILE="$OUTPUT_DIR/subdomains.txt"
ALIVE_FILE="$OUTPUT_DIR/alive.txt"
NMAP_RESULTS="$OUTPUT_DIR/nmap_results.txt"

# Create directory
mkdir -p "$OUTPUT_DIR"

echo "[+] Enumerating subdomains for $TARGET using Subfinder..."
subfinder -d "$TARGET" -silent >> "$SUBS_FILE"

echo "[+] Enumerating subdomains for $TARGET using Amass..."
amass enum -d "$TARGET" -silent >> "$SUBS_FILE"

# Sort and deduplicate
sort -u "$SUBS_FILE" -o "$SUBS_FILE"

echo "[+] Probing for alive subdomains..."
cat "$SUBS_FILE" | httprobe -c 50 -t 3000 | sed 's/^http[s]*:\/\///' | sort -u > "$ALIVE_FILE"

echo "[+] Starting aggressive Nmap scans..."
> "$NMAP_RESULTS"

while read domain; do
  echo "[*] Scanning $domain with Nmap -A -sS -sV -O..." | tee -a "$NMAP_RESULTS"
  nmap -T4 -A -sS -sV -O -Pn "$domain" | tee -a "$NMAP_RESULTS"
  echo "--------------------------------------------" >> "$NMAP_RESULTS"
done < "$ALIVE_FILE"

echo "[+] Recon for $TARGET completed. Results saved in '$OUTPUT_DIR'"
