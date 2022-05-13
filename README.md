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
 - Az A, B, C, D portok közül amelyiket nem használjuk (vagyis a C és a D portokat) , azt csupa egyre kell kötni, a reset jelét 0-ba és a clock enable-jét is 0-ba<br/>
 - PCIN és PCOUT "Product Cascade In/Out" portok a kaszkádosításra valók.<br/>
 - Egy DSP blokk teljes pipeline késleltetése 3 kéne, hogy legyen: bemeneti regiszterek + szorzás és összeadás közötti regiszterek + kimeneti regiszter<br/>
 - Az együtthatók formátuma s.17 és s.17.0 között bármilyen lehet, a kettedespont helyét szabadon megválaszthatjuk. A 25 bites világosságértékek formátuma: (s.24.0, csak s fixen 0) az LSB 8 biten a világosságérték, balról kiegészítve 25 bitre 0-kkal.<br/>
 - A szorzás kimenete két 43 bites részszorzat (s.24.17, ha az együtthatónak nincs egészrésze), amiket az előjellel kiegészítve kapunk a ténylegesen a végső összeadóra kerülő két, 48 bites részösszegeket. Ehhez adódik az előző kaszkád részből érkező 48 bites részösszeg a PCIN bemenetről.<br/>
 - A dedikált Carry logikát nem kell használni, a CARRYIN bemenetet lehet használni minden DSP-nél, mert a 8 bites világosságértékek miatt az egyes szorzások eredményeinek érdemi része 18+8=26 bites, a konvolúció végeredménye +5 bitnyi lehet maximum, vagyis 18+8+5=31, így elvileg sem fordulhat elő sehol a nem 0 carry. Ennek megfelelően a CARRYIN bemenetre konstans 0 jut, a CARRYINSEL[2:0] bemenetet konstans 3'b000-ba kell kötni, hogy ez jusson érvényre.<br/>
 - Az INMODE 5 bites bemenetre csupa 0-t kötve a következőt választjuk ki: INMODE[0]=0 -- az A bemenethez az A2 pipeline regisztert használjuk; INMODE[4]=0 -- a B bemenethez a B2 pipeline regisztert használjuk; INMODE[2]=0 -- a pre-adder D bemenetére fix 0 kerül, vagyis a preadder kimenetén egyszerűen az A bemenet jelenik meg; INMODE[3]=0 -- a preadder nem -A-t, hanem +A-t ad ki a szorzó A bemenetére (az INMODE[3]=0 miatt +A, INMODE[3]=1 esetén -A lenne)<br/>
 - Az ALU-nak 4 bemenete van, amiket összead: X, Y és Z multiplexerek kimenetei és a kiválasztott CARRY (CARRYIN). A szorzás eredménye két részszorzat, ezeket az M regiszterben tároljuk, innen az X és Y multiplexerre kerülnek, ezeket az OPMODE[3:0]=4'b0101 választja ki. A 25 hosszú DSP sor elején nincs az előző DSP-ről kimeneti részösszeg, így itt a Z multiplexerrel csupa 0-t kell kiválasztani, ezt az OPMODE[6:4]=3'000 teszi. Az összes többi DSP-nél a sorban előző kimeneti PCOUT kimenete (a saját PCIN bemenete) kell, hogy a Z muxra kerüljön, ezt az OPMODE[6:4]=001 teszi. Összefoglalva a sorban első DSP-re: OPMODE[6:0]=7'b0000101, a többi DSP-re: OPMODE[6:0]=7'b0010101.<br/>
 - Az ALUMODE[3:0] egyszerűen midenhol 4'b0000 értékű, emiatt P=X+Y+Z+carry.
 - A CEALUMODE és CECTRL órajel engedélyező bemenetek 0-k, mert a nem használt kontroll input pipeline-osító regisztereihez mennek, ugyanígy az RSTALUMODE és RSTCTRL bemenetek is 0-k. (az OPMODE-hoz és a CARRYINSEL-hez együtt tartozik a CECTRL és a RSTCTRL)<br/>
 - Az INMODE pipeline-osításáról nem ír semmit az adatlapja, de ki lehet választani a DSP példányosításánál, hogy 0 vagy 1 pipeline-regisztere legyen ennek a bemenetnek, ezért gondolom, ugyanúgy működik, mint az ALUMODE, OPMODE és CARRYINSEL. Ha esetleg mégsem lehet nem pipeline-osítani, akkor ezzel a megoldással bukta van, de valszeg nem lesz baj.<br/>
