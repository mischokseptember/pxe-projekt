# PXE-Projekt

## Benötigte Zutaten

- Netzwerk
- Router
- DHCP-Server
- Bootserver, der das zu bootende Betriebssystem ausliefern soll
- Dateiserver, über den die Clients ihre Dateien beziehen können
- Client-System-Image, das alle Clients dann beziehen


## Ablauf

1. Laptop wird angemacht, die Kontrolle hat das UEFI.
2. UEFI kommt zum Schluss, etwa weil keine Festplatte vorhanden ist,
   oder weil es die Administratorin direkt so eingestellt hat,
   dass Netzwerkboot (= PXE-Boot) durchgeführt werden soll.
3. UEFI gibt die Kontrolle an die Netzwerkkartenfirmware ab.
4. Netzwerkkartenfirmware besorgt sich über DHCP eine IP-Adresse
   sowie die Information, welcher TFTP-Server verwendet werden soll,
   um einen Kernel+Minimalstsystem (initrd) zu laden.
5. Nachdem sich nun Kernel+initrd im RAM befinden, gibt die
   Netzwerkkartenfirmware die Kontrolle an den Kernel ab.
6. Wenn der Kernel seine eigene Initialisierung abgeschlossen hat,
   ruft er das Hauptprogramm der initrd auf.
7. Dieses Hauptprogramm hat die Aufgabe, per DHCP eine IP-Adresse
   zu beziehen, und dann den Dateiserver einzuhängen.
8. Wenn das erledigt ist, kann das Hauptprogramm der initrd
   das Hauptprogramm des eigentlichen Systems, eingebunden
   als Netzwerklaufwerk, abgeben.


## Verschiedene Varianten

- Netzwerk gänzlich unbeteiligt, alles läuft und liegt lokal.
- Der Laptop hat eine Festplatte, und auf der kann auch
  ein Betriebssystem liegen; per Netzwerkboot soll das
  Betriebssystem installiert oder neu installiert werden.
- Der Laptop hat keine Festplatte und holt on demand die Programme
  und Daten, die er benötigt, von einem Server und legt sie
  temporär im RAM ab. "Mitteldünner Thin Client"
- Der Laptop hat keine Festplatte und auch so gut wie keinen RAM
  und dient nur dazu, den Bildschirminhalt eines Servers
  anzuzeigen. "Sehr dünner Thin Client"
