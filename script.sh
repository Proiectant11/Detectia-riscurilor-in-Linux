#!/bin/bash

check_executables_permissions() {
    echo "Verificare permisiuni executabile"
    > output_executables_permissions.txt
    for file in /bin/* /usr/bin/* /sbin/* /usr/sbin/*; do
        if [ -x "$file" ]; then
            perms=$(stat -c "%a %n" "$file")
            echo "Permisiuni:  $perms" >> output_executables_permissions.txt
        fi
    done
    echo "Permisiuni verificate complet!"
}

check_running_processes() {
    echo "Verificare procese active"
    ps aux --sort=%mem | awk 'NR<=10{print $1,42,$3,$4,$11}' > output_running_processes.txt
    echo "Procese verificate complet!"
}

check_package_versions() {
    echo "Verificare versiuni pachete instalate"
    > output_package_versions.txt
    if command -v dpkg &> /dev/null; then
        dpkg -l | grep -E '^ii' | awk '{print $2, $3}' >> output_package_versions.txt
    elif command -v rpm &> /dev/null; then
        rpm -qa --qf "%{NAME} %{VERSION}\n" >> output_package_versions.txt
    elif command -v pacman &> /dev/null; then 
        pacman -Q >> output_package_versions.txt
    else 
        echo "Manager de pachete necunoscut sau neinstalat." >> output_package_versions.txt
    fi
    sensitive_packages=("python3-yaml", "samba-commom", "rsync")
    for package in "${sensitive_packages[@]}"; do
        if grep -q "$package" output_package_versions.txt; then
            echo "Atentie! Pachet sensibil $package gasit in sistem!"
        fi
    done
    echo "Versiuni pachete verifiate complet!"
}

check_file_checksum() {
    echo "Verificare sume de control pentru executabile importante"
    > output_file_checksum.txt
    declare -A files_to_check
    files_to_check=(
        ["/bin/ls"]=""
        ["/bin/bash"]=""
        ["/usr/bin/ssh"]=""
        ["/sin/init"]=""
    )
    for file in "${!files_to_check[@]}"; do
        if [ -f "$file" ]; then
            checksum=$(sha256sum "$file" | awk '{print $1}]')
            files_to_check[$file]=$checksum
            echo "Suma de control pentru $file: $checksum" >> output_file_checksum.txt
        else
            echo "$file nu a fost gasit." >> output_file_checksum.txt
        fi 
    done
    echo "Sume de control verificate complet!" 

}

check_firewall() {
    if command -v ufw &> /dev/null; then
        ufw_status=$(sudo ufw status verbose)
        echo "Stare UFW: $ufw_status"
        if [[ $ufw_status == *"Stare: inactiv"* ]]; then
            echo "Atentie: UFW este dezactivat. Activare recomandata pentru securitatea sistemului."
            echo "Pentru a activa, rulati: sudo ufw enable"
        else
            echo "UFW este activ. Regulile curente:" > output_firewall.txt
            sudo ufw status numbered > output_firewall.txt
        fi
    fi

    if command -v iptables &> /dev/null; then
        iptables_status=$(sudo iptables -L -v -n)
        echo "Reguli iptables:" > output_firewall.txt
        echo "$iptables_status" > output_firewall.txt
        if [[ -z "$iptables_status" ]]; then
            echo "Atentie: Nu există reguli iptables definite."
        fi
    fi

    if ! command -v ufw &> /dev/null && ! command -v iptables &> /dev/null; then
        echo "Nici un firewall cunoscut nu este instalat sau activat."
        echo "Puteti instala UFW cu: sudo apt install ufw"
        echo "Puteti instala firewalld cu: sudo apt install firewalld"
    fi

    echo "Firewall verificat complet!"
}


check_running_services() {
    echo "Verificare servicii active"
    systemctl list-units --type=service --state=running > output_running_services.txt
    echo "Servicii active verificate complet!"
}

check_users_and_groups() {
    echo "Verificare utilizatori si grupuri"
    > output_users_and_groups.txt
    current_user=$(whoami)
    echo "Utiliatori:" >> output_users_and_groups.txt
    cut -d: -f1 /etc/passwd >> output_users_and_groups.txt
    if grep -q "^$current_user$" <(cut -d: -f1 /etc/passwd); then
        echo "Utilizator curent '$current_user' este in lista!"
    else 
        echo "Avertisment:Utilizatorul '$current_user' nu a fost gasit!"
    fi
    echo "Grupuri:" >> output_users_and_groups.txt
    cut -d: -f1 /etc/group >> output_users_and_groups.txt
    echo "Utilizatori si grupuri verificate complet!"
}

check_suid_sgid_files() {
    echo "Verificare fisiere SUID/SGID"
    > output_suid_sgid_files.txt
    find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -ld {} \; 2>/dev/null >> output_suid_sgid_files.txt
    echo "Fisiere SUID/SGID verificate complet!"
}

check_dns_config() {
    echo "Verificare configuratii DNS"
    cat /etc/resolv.conf | grep -v '^#'  > output_dns_config.txt
    resolvectl status >> output_dns_config.txt
    echo "Configuratii DNS verificate complet!"
}

check_backups() {
    echo "Verificare backup-uri"
    > output_backups.txt
    ls /var/backups >> output_backups.txt
    crontab -l | grep -i "backup" >> output_backups.txt
    echo "Backup verificat complet!"
}

check_tmp_files() {
    echo "Verificare fisiere temporare"
    > output_tmp_files.txt
    sudo ls /tmp >> output_tmp_files.txt
    sudo find /tmp -type f -atime +10 -delete >> output_tmp_files.txt
    echo "Fisiere temporare verificate complet!"
}

check_sensitive_file_permissions() {
    echo "Verificare permisiuni fisiere sensibile"
    ls -l /etc/passwd /etc/shadow /etc/sudoers > output_sensitive_file_permissions.txt
    echo "Permisiuni fisiere sensibile verificate complet!"
}

check_kernel_integrity() {
    echo "Verificare integritate kernel"
    REFERENCE_CHECKSUM="a9b1c1e7f69b6e8dd13f49c4d8c1d5f9c85a78d8b59451e50c2e7e04f06e8e6e"
    kernel_file=$(ls /boot/vmlinuz-* | head -n 1)
    if [ -f "$kernel_file" ]; then
        kernel_checksum=$(sudo sha256sum "$kernel_file" | awk '{print $1}')
        echo "Suma de control pentru $kernel_file: $kernel_checksum" > output_kernel_checksum.txt
        if [ "$kernel_checksum" = "$REFERENCE_CHECKSUM" ]; then
            echo "Integritatea kernelului este confirmata!"
        else 
            echo "Integritatea kernelului este compromisa!"
        fi
    else
        echo "Fisierul kernel nu a fost gasit." > output_kernel_checksum.txt
    fi
    echo "Integritate kernel verificata complet!"
}

check_kernel_messages() {
    echo "Verificare mesaje kernel"
    dmesg | grep -i "error\|warn\|fail" > output_dmesg_errors.txt
    echo "Mesaje kernel verificate complet!"
}

check_loaded_modules() {
    echo "Verificare module kernel incarcate"
    lsmod > output_loaded_modules.txt
    echo "Module kernel incarcate verificate complet!"
}

check_module_checksums() {
    echo "Verificare sume de control pentru modulele de kernel"
    module_dir="/lib/modules/$(uname -r)/kernel"
    find "$module_dir" -type f -exec sha256sum {} \; > output_module_checksums.txt
    echo "Sume de control pentru modulele de kernel verificate complet!"
}

check_module_info() {
    echo "Verificare informatii module kernel"
    for module in $(lsmod | awk '{print $1}' | tail -n +2); do
        modinfo "$module" > "output_modinfo_$module.txt"
    done
    echo "Informatii module kernel verificate complet!"
}

check_kernel () {
    echo "Incepere verificare integritate kernel si module kernel"
    check_kernel_integrity
    check_kernel_messages
    check_loaded_modules
    check_module_checksums
    check_module_info
    echo "Integritate kernel si module kernel verificate complet!"
}

monitor_open_ports() {
    echo "Verificare porturi deschise"
    sudo ss -tuln > output_open_ports.txt
    echo "Porturi deschise verificate complet!"
}

monitor_network_connections() {
    echo "Verificare conexiuni de retea"
    sudo ss -tuna   > output_network_connections.txt
    echo "Conexiuni de retea verificate complet!"
}

monitor_process_ports() {
    echo "Verificare procese si porturi utilizate"
    sudo ss -tulpn > output_process_ports.txt
    echo "Procese si porturi verificate complet!"
}

scan_ports() {
    echo "Scanare porturi deschise"
    for port in {1..1024}; do
        nc -zv localhost $port 2>&1 | grep -q "succeeded" && echo "Portul $port este deschis" >> output_scan_ports.txt
    done
    echo "Scanare porturi completa!"

}

check_active_ports() {
    local port=$1
    local protocol=$2
    if grep -qE "${protocol}.*:${port} " output_open_ports.txt; then
        return 0
    else 
        return 1
    fi
}

restrict_protocols() {
    echo "Aplicarea regulilor de restrictionare a protocoalelor"
    ports_protocols=(
        "80 tcp"
        "53 udp"
    )
    > output_restrictii.txt
    for aux in "${ports_protocols[@]}"; do
        port=$(echo $aux | cut -d' ' -f1)
        protocol=$(echo $aux | cut -d' ' -f2)
        if check_active_ports $port $protocol; then
            if [ "$protocol" == "tcp" ]; then
                echo "Restrictionare protocol TCP pe portul $port" >> output_restrictii.txt
                sudo iptables -A INPUT -p tcp --dport $port -j REJECT
            elif [ "$protocol" == "udp" ]; then
                echo "Restrictionare protocol UDP pe portul $port" >> output_restrictii.txt
                sudo iptables -A INPUT -p udp --dport $port -j REJECT
            fi
        fi
    done 
    sudo iptables -L INPUT -v -n | grep "dpt:80" >> output_restrictii.txt
    sudo iptables -L INPUT -v -n | grep "dpt:53" >> output_restrictii.txt
    echo "Reguli de restrictionare a protocoalelor aplicate complet!"
}               

check_ports() {
    echo "Incepere monitorizare de retea"
    monitor_open_ports
    monitor_network_connections
    monitor_process_ports
    scan_ports
    echo "Monitorizare de retea verifcata complet!"
    restrict_protocols
}

main () {
    echo "Incepere verificari de securitate"
    check_executables_permissions
    check_running_processes
    check_package_versions
    check_firewall
    check_running_services
    check_users_and_groups
    check_suid_sgid_files
    check_dns_config
    check_backups
    check_tmp_files
    check_sensitive_file_permissions
    check_kernel
    check_ports
    echo "Verificarea securitatii finalizata!"
}

main 