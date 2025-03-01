#!/bin/bash

command=$1

if [ -z "$command" ]; then
    echo "Invalid input -h for help"
else 
    if [ "$command" == "-s" ]; then
        network=$2
        
        if [ -z "$network" ]; then
            echo "Eroare! ex: 192.168.1.0/24)"
            exit 1
        fi
        
        # Prefixul retelei
        networkPrefix=$(echo "$network" | cut -d"/" -f1 | cut -d"." -f1-3)
        
        for i in $(seq 1 254); # Scaneaza toate adresele
        do
            (
                ping -c 1 -W 2 "$networkPrefix.$i" > /dev/null 2>&1  # Timeout de 2 secunde
                
                if [ $? -eq 0 ]; 
                then
                    echo "Dispozitiv gasit: $networkPrefix.$i"
                    
                    # Obtinere numele host-ului
                    hostname=$(nslookup "$networkPrefix.$i" 2>/dev/null | grep "name =" | awk '{print $4}' | sed 's/\.$//')
                    
                    if [ ! -z "$hostname" ]; 
                    then
                        echo "  Hostname: $hostname"
                    else
                        echo "  Hostname: N/A"
                    fi
                    
                    # Incearca sa obtii adresa MAC
                    mac=$(arp -n | grep "$networkPrefix.$i" | awk '{print $3}')
                    if [ ! -z "$mac" ]; then
                        echo "  MAC: $mac"
                    else
                        echo "  MAC: N/A"
                    fi
                fi
            ) &
            
            if [ $(jobs -p | wc -l) -ge 20 ]; 
            then
                wait -n
            fi
        done
        wait # Asteapta terminarea tuturor proceselor

    elif [ "$command" == "-l" ]; then
        # Obtine default gateway
        defaultGateway=$(ip route | grep default | awk '{print $3}')
        echo "Gateway implicit: $defaultGateway"
        
        # Obtine interfata de retea
        interface=$(ip route | grep default | awk '{print $5}')
        echo "Interfata: $interface"
        
        # Obtine adresa IP locala si masca de subretea
        localIPadd=$(ip addr show "$interface" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
        subnetMask=$(ip addr show "$interface" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f2)
        echo "Adresa IP locala: $localIPadd/$subnetMask"
        
        # Obtine reteaua
        network=$(ip route | grep "$interface" | grep -v default | awk '{print $1}' | head -n 1)
        echo "Scanez reteaua: $network"
                
        # Prefixul retelei
        networkPrefix=$(echo "$network" | cut -d"/" -f1 | cut -d"." -f1-3)
        
        # Scaneaza dispozitivele active
        for i in $(seq 1 254);
        do
            (
                ping -c 1 -W 2 "$networkPrefix.$i" > /dev/null 2>&1  # Timeout de 2 secunde
                if [ $? -eq 0 ]; then
                    echo "Dispozitiv gasit: $networkPrefix.$i"
                   
                    hostname=$(nslookup "$networkPrefix.$i" 2>/dev/null | grep "name =" | awk '{print $4}' | sed 's/\.$//')
                    if [ ! -z "$hostname" ]; then
                        echo "  Hostname: $hostname"
                    else
                        echo "  Hostname: N/A"
                    fi
                   
                    mac=$(arp -n | grep "$networkPrefix.$i" | awk '{print $3}')
                    if [ ! -z "$mac" ]; then
                        echo "  MAC: $mac"
                    else
                        echo "  MAC: N/A"
                    fi
                fi
            ) &
           
            if [ $(jobs -p | wc -l) -ge 20 ]; then
                wait -n
            fi
        done
        wait

    elif [ "$command" == "-p" ]; then
        ip=$2
        port=$3
        if [ -z "$ip" ] || [ -z "$port" ]; then
            echo "Trebuie sa specificati o adresa IP si un port (ex: 192.168.1.1 80)"
            exit 1
        fi
        
        # Scaneaza portul specificat
        (echo > /dev/tcp/$ip/$port) >/dev/null 2>&1 && echo "Port $port deschis pe $ip" || echo "Port $port Inchis pe $ip"

    elif [ "$command" == "-h" ]; then
        echo "Utilizare: $0 [optiune]"
        echo "Optiuni:"
        echo "  -l    Scaneaza reteaua locala pentru dispozitive active"
        echo "  -s    Scaneaza o retea specificata pentru dispozitive active"
        echo "  -p    Scaneaza un port specific pe o adresa IP (ex: -p 192.168.1.1 80)"
        echo "  -h    Afiseaza acest mesaj de ajutor"
    else
        echo "Optiune necunoscuta: $command"
        echo "Utilizare: $0 -h pentru ajutor"
    fi
fi
