# Detectia-riscurilor-in-Linux

# 18.06.2024
O strategie de securitate eficienta pentru un sistem Linux include verificari si masuri care acopera toate aspectele potential vulnerabile. Implenentarea unei combinatii de verificari automate si monitorizarea constanta poate contribui semnificativ la protejarea sistemului impotriva amenintarilor. Integritatea acestor verificari suplimentare in practicile de securitate curente poate asigura o protectie cuprinzatoare si robusta pentru sistemul Linux.
Verificare securitatii va fi facuta urmarind urmatoarele aspecte:
-verificare executabile, permisiuni
-verificare procese
-verificare versiuni pachete
-verificare sume de control
-verificare configuratii firewall

# 21.06.2024
-verificarea servicii active
-verificarea utilizatori si grupuri
-verificarea fisierelor SUID/SGID
-monitorizarea cautarilor DNS si a configuratiilor DNS
-verificarea utilizarii si configurarii de backups
-verificarea fisierelor temporare

# 25.06.2024
-verificarea permisiunilor fisierelor sensibile
-verificarea integritatii kernelului si a modurilor de kernel
-monitorizarea porturilor deschise si conexiunilor de retea

# 26.06.2024
Am realizat pentru fiecare verificare in parte cate un fisier de output, pentru a stoca toate informatiile obtinute in urma executarii verificarilor de securitate mentionate mai sus. Pe baza acestora, am ales anuite exceptii pentru a anunta utilizatorul ca in sisitemul lui au loc anumite probleme de securitate.
    1.Verificarea sumei de control al fiisierului kernel, prin calcularea acesteia si compararea cu suma de referinta, obtinuta din documentatia oficiala a sistemului de operare (in cazul verificarilor mele, suma de referinta este una aleator aleasa)
    2.Implementarea unor pachete "sensibile" si verificarea existentei acestora prin lista de pachete instalate; in cazul in care sunt gasite, utilizatorul este anuntat prin anumite mesaje de eroare
    3.Este verificata starea firewall-ului prin UFW si iptables si sunt afisate mesaje corespunzatoare outputului primit

# 27.06.2024
    4.Am restrictionat anumite protocoale pentru porturile active