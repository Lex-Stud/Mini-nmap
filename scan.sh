#!/bin/bash

command=$1

if [ -z "$command" ]; then
    echo "Invalid input -h for help"
else
    if [ "$command" == "-l" ]; then
        # Obține gateway-ul implicit (default gateway)
        defaultGateway=$(ip route | grep default | awk '{print $3}')
        echo "Gateway implicit: $defaultGateway"
        
        # Obține interfața de rețea
        interface=$(ip route | grep default | awk '{print $5}')
        echo "Interfață: $interface"
        
        # Obține adresa IP locală și masca de subrețea
        localIPadd=$(ip addr show "$interface" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
        subnetMask=$(ip addr show "$interface" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f2)
        echo "Adresa IP locală: $localIPadd/$subnetMask"
        
        # Obține rețeaua
        network=$(ip route | grep "$interface" | grep -v default | awk '{print $1}' | head -n 1)
        echo "Scanez rețeaua: $network"
                
        # Prefixul rețelei
        networkPrefix=$(echo "$network" | cut -d"/" -f1 | cut -d"." -f1-3)
        
        # Scanează dispozitivele active
        for i in $(seq 1 254); do  # Scanează toate adresele posibile în subnet
            (
                echo "Pinging $networkPrefix.$i"  # Debug
                ping -c 1 -W 2 "$networkPrefix.$i" > /dev/null 2>&1  # Timeout de 2 secunde
                if [ $? -eq 0 ]; then
                    echo "Dispozitiv găsit: $networkPrefix.$i"
                    # Încearcă să obții numele host-ului
                    hostname=$(nslookup "$networkPrefix.$i" 2>/dev/null | grep "name =" | awk '{print $4}' | sed 's/\.$//')
                    if [ ! -z "$hostname" ]; then
                        echo "  Hostname: $hostname"
                    else
                        echo "  Hostname: N/A"
                    fi
                    # Încearcă să obții adresa MAC
                    mac=$(arp -n | grep "$networkPrefix.$i" | awk '{print $3}')
                    if [ ! -z "$mac" ]; then
                        echo "  MAC: $mac"
                    else
                        echo "  MAC: N/A"
                    fi
                fi
            ) &
            # Limitează numărul de procese paralele
            if [ $(jobs -p | wc -l) -ge 20 ]; then
                wait -n
            fi
        done
        wait # Așteaptă terminarea tuturor proceselor
    elif [ "$command" == "-h" ]; then
        echo "Utilizare: $0 [opțiune]"
        echo "Opțiuni:"
        echo "  -l    Scanează rețeaua locală pentru dispozitive active"
        echo "  -h    Afișează acest mesaj de ajutor"
    else
        echo "Opțiune necunoscută: $command"
        echo "Utilizare: $0 -h pentru ajutor"
    fi
fi
