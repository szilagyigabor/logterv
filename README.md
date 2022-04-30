# logterv
Logikai tervezés tárgy (8. félév)

Ötlet a konvolúciós modul teszteléséhez:
 - A konvolúciós együtthatókat és a beadott összekonvolválandó értékeket össze kell hangolni, hogy értelmes eredmény jöjjön ki.
 - Nem kell a W képszélességgel és a valid rész szélességével foglalkozni, a DSP modul felől akár végtelen széles is lehetne a kép. Tegyünk így!
 - A konvolúciós mátrix egyes soraihoz érkező pixelértékek legyenek a sorok között különbözőek, de egy soron belül állandóak
 - Olyan együtthatókészlet - bemeneti jel kombinációt válasszunk, aminél a konvolúció eredménye szép (pl 0, 0.5, -0.5), ezeket a kombinációkat váltogassuk, mondjuk 50 órajelenként (hogy az egyes stabil bemeneti jel kombinációkra állandósulni tudjon a konvolúció értéke)
 - Csináljunk olyat is, hogy ugyanazokat a bemeneti jeleket adjuk a DSP blokk bemenetére, mint az előző pontban, csak órajelenként cserélgetve őket, 50 órajelenkénti csere helyett. Ekkor elvileg ugyanazokat a kimeneteket kéne kapni, mint a lassú váltogatásnál.
 - Ki kellene próbálni olyan esetet is, amikor az egy sorba tartozó együtthatók egyformák és olyat is amikor nem.

