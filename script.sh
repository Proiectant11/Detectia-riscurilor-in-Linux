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


main () {
    echo "Incepere verificari de securitate"
    check_executables_permissions
    check_running_processes
    check_package_versions
    check_firewall
}

main 