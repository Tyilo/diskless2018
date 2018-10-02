Ubuntu USB-stick til DM i Programmering
=======================================

Som noget nyt til [DM i Programmering](https://fb.com/DmIProgrammering)
i Aarhus i 2018 skal hvert hold medbringe én bærbar pc og boote Ubuntu
fra en udleveret USB-stick. Ubuntu bliver ikke installeret permanent på
den bærbare, men er i stedet i en live-udgave hvor en række programmer
til DM i Programmering er installeret på forhånd:

* Standard editors: vim, emacs, nano, gedit
* Populære IDE'er: IntelliJ, PyCharm, VS Code, BlueJ
* Sædvanlige compilers: gcc, clang, OpenJDK, Python 3, pypy

Desuden er Firefox sat op med http://ncpc18.kattis.com som startside,
så man hurtigt kan logge ind og komme i gang med konkurrencen.

For at starte Ubuntu fra USB-sticken er der et par krav:

* 3 GB ledig plads på en ikke-krypteret partition
* "Fast startup" slået fra i Windows (se nedenfor)
* Secure Boot slået fra (se nedenfor)
* Virker kun på PC'er med Windows/Linux/FreeBSD/osv. - virker desværre ikke på Mac!
* Virker ikke hvis computeren bruger diskkryptering, f.eks. BitLocker i Windows

Når man starter USB-sticken op første gang, kopieres to filer (i alt 2,5 GB)
over på den bærbares harddisk i en mappe der hedder "Contest2018".
Efter konkurrencen kan man trygt slette mappen for at frigive pladsen.
Hvis der er flere partitioner på disken, bruges den partition der
har mest ledig plads.

Når Ubuntu er startet op, kan USB-sticken tages ud af computeren.
Hvis man skal genstarte computeren af en eller anden grund,
skal USB-sticken dog atter bruges.

-------

"Fast startup" skal slås fra for at sikre at Linux kan mounte den
NTFS-partition som Windows ligger på. Det gøres i Kontrolpanel:

* "Strømstyring" >
* "Vælg, hvad tænd/sluk-knapperne gør" >
* Tryk "Rediger indstillinger, der i øjeblikket er utilgængelige"
* Fjern markering ved "Aktivér hurtig start (anbefales)"

-------

Secure boot slås fra i BIOS. På nogle computere kræver det at man
genstarter på en helt særlig måde gennem Windows, før man kan slå
Secure boot fra:

* Tryk Windows-X
* Hold Shift inde mens du trykker Genstart. Nu dukker en blå menu op:
* Vælg "Fejlfinding" >
* "Avancerede indstillinger" >
* "Indstillinger for UEFI-firmware" >
* "Genstart"

Hvis "Indstillinger for UEFI-firmware" ikke er en mulighed, skal man
blot prøve at genstarte normalt og trykke Esc, F2, Delete, eller
lignende for at gå ind i BIOS som normalt.

Herefter varierer det meget fra computer til computer, men man skal
i BIOS finde Secure boot, slå det fra, og gemme og genstarte.
