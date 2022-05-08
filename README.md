# logterv
Logikai tervezés tárgy (8. félév)

Ötlet a konvolúciós modul teszteléséhez:
 - A konvolúciós együtthatókat és a beadott összekonvolválandó értékeket össze kell hangolni, hogy értelmes eredmény jöjjön ki.<br/>
 - Nem kell a W képszélességgel és a valid rész szélességével foglalkozni, a DSP modul felől akár végtelen széles is lehetne a kép. Tegyünk így!<br/>
 - A konvolúciós mátrix egyes soraihoz érkező pixelértékek legyenek a sorok között különbözőek, de egy soron belül állandóak<br/>
 - Olyan együtthatókészlet - bemeneti jel kombinációt válasszunk, aminél a konvolúció eredménye szép (pl 0, 0.5, -0.5), ezeket a kombinációkat váltogassuk, mondjuk 50 órajelenként (hogy az egyes stabil bemeneti jel kombinációkra állandósulni tudjon a konvolúció értéke)<br/>
 - Csináljunk olyat is, hogy ugyanazokat a bemeneti jeleket adjuk a DSP blokk bemenetére, mint az előző pontban, csak órajelenként cserélgetve őket, 50 órajelenkénti csere helyett. Ekkor elvileg ugyanazokat a kimeneteket kéne kapni, mint a lassú váltogatásnál.<br/>
- Ki kellene próbálni olyan esetet is, amikor az egy sorba tartozó együtthatók egyformák és olyat is amikor nem.<br/>


Jegyzetek a DSP modul használatához:
 - Az M regisztert használni kéne<br/>
 - Az A, B, C, D portok közül amelyiket nem használjuk, azt csupa egyre kell kötni, a reset jelét 0-ba és a clock enable-jét is 0-ba<br/>
 - PCIN és PCOUT "Product Cascade In/Out" portok a kaszkádosításra valók.<br/>
 - CARRYCASCIN/CARRYCASCOUT is dedikált kaszkádosításra való portok, de nem vagyok benne biztos, hogy kéne használni őket.<br/>
 - Egy DSP blokk teljes pipeline késleltetése 3 kéne, hogy legyen: bemeneti regiszterek + szorzás és összeadás közötti regiszterek + kimeneti regiszter<br/>
 - Az együtthatók formátuma s.17 és s.17.0 között bármilyen lehet, a kettedespont helyét szabadon megválaszthatjuk. A 25 bites világosságértékek formátuma: (s.24.0, csak s fixen 0) az LSB 8 biten a világosságérték, balról kiegészítve 25 bitre 0-kkal.<br/>
 - A szorzás kimenete két 43 bites részszorzat (s.24.17, ha az együtthatónak nincs egészrésze), amiket az előjellel kiegészítve kapjuk a ténylegesen a végső összeadóra kerülő két, 48 bites részösszegeket. Ehhez adódik az előző kaszkád részből érkező 48 bites részösszeg a PCIN bemenetről, ezt nem kell már jobbra shiftelni 17 bittel, tehát az együtthatók tetszőleges törtrészt és egészrészt tatalmazhatnak a 17 szabad biten belül (+1 az előjelbit a 18-ból).<br/>
 - A dedikált Carry logikát nem kell használni.<br/>
