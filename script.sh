#!/bin/bash

check_executables_permissions() {
    echo "Verificare permisiuni executabile"
    for file in /bin/* /usr/bin/* /sbin/* /usr/sbin/*; do
        if [ -x "$file" ]; then
            perms=$(stat -c "%a %n" "$file")
            echo "Permisiuni:  $perms"
        fi
    done
    echo "Permisiuni verificate complet!"
}

check_running_processes() {
    echo "Verificare procese active"
    ps aux --sort=%mem | awk 'NR<=10{print $1,42,$3,$4,$11}'
    echo "Procese verificate complet!"
}

check_package_versions() {
    echo "Verificare versiuni pachete instalate"
    if command -v dpkg &> /dev/null; then
        dpkg -l | grep -E '^ii' | awk '{print $2, $3}'
    elif command -v rpm &> /dev/null; then
        rpm -qa --qf "%{NAME} %{VERSION}\n"
    elif command -v pacman &> /dev/null; then 
        pacman -Q
    else 
        echo "Manager de pachete necunoscut sau neinstalat."
    fi
    echo "Versiuni pachete verifiate complet!"
}

check_file_checksum() {
    echo "Verificare sume de control pentru executabile importante"
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
            echo "Suma de control pentru $file: $checksum"
        else
            echo "$file nu a fost gasit."
        fi 
    done
    echo "Sume de control verificate complet!" 

}

check_firewall() {
    echo "Verificare configuratii firewall"
    sudo iptables -L -v -n
    sudo ufw status verbose
    echo "Configuratii firewall verificate complet!"
}


check_running_services() {
    echo "Verificare servicii active"
    systemctl list-units --type=service --state=running
    echo "Servicii active verificate complet!"
}

check_users_and_groups() {
    echo "Verificare utilizatori si grupuri"
    echo "Utiliatori:"
    cut -d: -f1 /etc/passwd
    echo "Grupuri:"
    cut -d: -f1 /etc/group
    echo "Utilizatori si grupuri verificate complet!"
}

check_suid_sgid_files() {
    echo "Verificare fisiere SUID/SGID"
    find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -ld {} \;
    echo "Fisiere SUID/SGID verificate complet!"
}

check_dns_config() {
    echo "Verificare configuratii DNS"
    cat /etc/resolv.conf
    echo "Configuratii DNS verificate complet!"
}

check_backups() {
    echo "Verificare backup-uri"
    ls /var/backups
    crontab -l | grep -i "backup"
    echo "Backup verificat complet!"
}

check_tmp_files() {
    echo "Verificare fisiere temporare"
    sudo ls /tmp
    sudo find /tmp -type f -atime +10 -delete
    echo "Fisiere temporare verificate complet!"
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
}

main 