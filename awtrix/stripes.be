# @name Stripes
# @desc Warming stripes by Ed Hawkins (showyourstripes.info, CC BY 4.0) for all 1,069 places: a new place each time the app comes round, built in and out in the screensaver's ten styles.
# @author georgios
# @version 0.5
# @display 52x16
# @config places text "Places" default="Global; Sweden; Uppsala, Sweden; Stockholm, Sweden; Greece; Athens, Greece" maxlen=8000 help="Separated by semicolons, played in this order: a name as on showyourstripes.info (Uppsala, Sweden), a place alone (Uppsala), a country, a region (Europe) or all. Every name: https://github.com/gkaramanis/stripes-saver/blob/main/awtrix/locations.txt" group="Places"
# @config order select "Order" default=list options=list,shuffled group="Places"
# @config styleIn select "Build in" default=sweep options=sweep,rise,scatter,fade,drop,open,blinds,iris,dissolve,warming,random group="Drawing"
# @config styleOut select "Build out" default=fade options=none,sweep,rise,scatter,fade,drop,open,blinds,iris,dissolve,warming,random group="Drawing"
# @config buildMs number "Build time" default=8000 min=2000 max=30000 step=1000 unit=ms group="Drawing"
# @config title bool "Show name and years" default=true group="Drawing"
# @config durationMs number "Duration" default=30000 min=8000 max=120000 step=1000 unit=ms group="Drawing"

import math
import string

class Stripes
  static SCALE = [0x001944, 0x08306B, 0x08519C, 0x2171B5, 0x4292C6, 0x6BAED6, 0x9ECAE1, 0xC6DBEF, 0xDEEBF7, 0xFEE0D2, 0xFCBBA1, 0xFC9272, 0xFB6A4A, 0xEF3B2C, 0xCB181D, 0xA50F15, 0x67000D, 0x440007]
  static GREY = 0x7F7F7F
  static STYLES = ["sweep", "rise", "scatter", "fade", "drop", "open", "blinds", "iris", "dissolve", "warming"]

  # The saver's names for the two styles renamed here, so saved settings keep working
  static OLD_NAMES = {"flip": "open", "mosaic": "dissolve"}
  static SWEEP = 0
  static RISE = 1
  static SCATTER = 2
  static FADE = 3
  static DROP = 4
  static OPEN = 5
  static BLINDS = 6
  static IRIS = 7
  static DISSOLVE = 8
  static WARMING = 9
  static TITLE_MS = 2500

  # Ends the build out this long before the turn ends, so the switch to the next app does not cut it
  static MARGIN_MS = 400
  static DEFAULT_PLACES = "Global; Sweden; Uppsala, Sweden; Stockholm, Sweden; Greece; Athens, Greece"

  # From stripes.py: name, region, first year, last year, one letter per column (a coldest, - no data)
  # BEGIN DATA
  static PLACES = [
    ["Global", "Global", 1850, 2025, "dedcddddgecdcddddccecefefghhhfhfggfgggiiikiklmmnnppq"],
    ["Aba, Nigeria", "Africa", 1886, 2025, "ccbedeacbbhfdededegggfggfddgfeggieiiiijijlklnoomqoor"],
    ["Abeokuta, Nigeria", "Africa", 1886, 2025, "cbdgdebbbbfgegggeffggfggfdeffefhieiijjjiklklnnmlponq"],
    ["Aberdeen, United Kingdom", "Europe", 1850, 2025, "fcfdefefcecdefhefegfeggfiijhijhhjggfijfielillonlmmnq"],
    ["Abidjan, Cote d'Ivoire", "Africa", 1889, 2025, "ccecgacabgeeffhfdffghgeggegfeehgifhhikjilmkmnmpmpomq"],
    ["Abobo, Cote d'Ivoire", "Africa", 1889, 2025, "ccecgacabgeeffhfdffghgeggegfeehgifhhikjilmkmnmpmpomq"],
    ["Abu Dhabi, United Arab Emirates", "Middle East", 1893, 2025, "geehedgdheegigggffgighegiififchegkkdghhgjoopnlqmqrrr"],
    ["Abū Ghurayb, Iraq", "Middle East", 1878, 2025, "lgggffcekfeffihgggiehgifhfhigkhhkfekhfiifkmmkknkopqp"],
    ["Abuja, Nigeria", "Africa", 1886, 2025, "ecdfdgccccggchehgiggfhggfeegfffhiehiikiijlkknmolonnq"],
    ["Acapulco de Juárez, Mexico", "North America", 1878, 2025, "ecbcbbgffdcedceefhfggeigjfhdjihfigfjjhlkklijkljlonnq"],
    ["Accra, Ghana", "Africa", 1886, 2025, "cccgdfabbafhfgghgeeghfggfeegfefgieiijkjiklklmmnmnnnq"],
    ["Adana, Turkiye", "Middle East", 1857, 2025, "efhiggkgggfgejfdfekeiihgihgiehiikihggjhggfjlkkmnnpqq"],
    ["Addis Ababa, Ethiopia", "Africa", 1901, 2025, "eddcedgdgdeeggegggghcigeiegfefgfgihekjikmkonnooqooqp"],
    ["Adelaide, Australia", "Australasia", 1856, 2025, "fhhgifeffgjfggfeeffghdfdggfddffgigggjhkhijihlkmmnnlm"],
    ["Aden, Yemen", "Middle East", 1886, 2025, "dedefeeecedeebehhgecijihfgeihdggjdiihgikkonmmkmloqpq"],
    ["Afghanistan", "Asia", 1876, 2025, "ejifihggihggejgggggfeglhjeiighghhheijhjifilomlmlnnnq"],
    ["Agadir, Morocco", "Africa", 1850, 2025, "jceffgegfdcdeehedcdeeefgdfgfhjhhhiggcgiijjimkmkpmmmq"],
    ["Agra, India", "Asia", 1875, 2025, "ghhdfgejkjghfhfhjehicehlgjhifghkihihlgliijgilklinmlm"],
    ["Aguascalientes, Mexico", "North America", 1871, 2025, "eebdcaacfdhfffbffigihgjjhlkjiikieijfijfhglkmlljninnr"],
    ["Ahmedabad, India", "Asia", 1875, 2025, "figcfgfjljhefghiihfhffhiekhihhikjghihemijiiklimknonm"],
    ["Ahvaz, Iran", "Middle East", 1893, 2025, "feekedhegighggigfgghggdiiegjhehefikfiiifkmnmlmnmqqrr"],
    ["Ajmer, India", "Asia", 1875, 2025, "ghgdgheilkigfiggjggiefijfkijfgikjhhhkfljhigkmjmhlnll"],
    ["Al Aḩmadī, Kuwait", "Middle East", 1893, 2025, "eeekedgehigggghgfgghghdikegkieiefijeiijgkmmmllnmpqqr"],
    ["Al Ḩudaydah, Yemen", "Middle East", 1886, 2025, "dddeefeeccdefcghgffehiihfgehhcffiehkggikkoommlnmprpq"],
    ["Alaska, United States of America", "North America", 1893, 2025, "egihghfhkefgikjggjkkigiheigkeigffmlhikijijknkiimpqkm"],
    ["Albania", "Europe", 1850, 2025, "cgdjiigehgefeghifgfiijijfjehjikgijhhggfhjilhmmknppqr"],
    ["Albuquerque, United States of America", "North America", 1850, 2025, "akeljjhhhdfjggfihhggehfgfkihgihihghggfkghiilmmllnpno"],
    ["Aleppo, Syria", "Middle East", 1857, 2025, "eehifhmhggffejhefejfiiigjihiehjilihhgjghhgjklkmmnpqq"],
    ["Alexandria, Egypt", "Middle East", 1861, 2025, "cihhehfdeffgiedccgggiiihiigighhhjgghgifihhjkmlooqqqq"],
    ["Algeria", "Africa", 1896, 2025, "gihecffgeeeeifjfifkgkfiiejighhccehhikkejklpnmonoqprr"],
    ["Algiers, Algeria", "Africa", 1850, 2025, "ddgdfhfghgcdfgkgfeffdfgihgggikhgiiggdeghjkilmmmnnopr"],
    ["Alīgarh, India", "Asia", 1875, 2025, "hghdfgejjjehfhfhiehicdgkfjhjghhjihiilgliijgjlklimnlm"],
    ["All oceans", "Ocean", 1850, 2025, "feddefeegfdecdeccbbdddeefghhhfhfggfgggiiikjllmmmmopq"],
    ["Allahābād, India", "Asia", 1875, 2025, "egebceejhicgefefieghcdgjeihihhgmifihkfjjjkjjllmhlnkn"],
    ["Almaty, Kazakhstan", "Asia", 1877, 2025, "ehdegfgcffdghjgdhjdgcfmggefffgiifhfijhiiihlmknlkllnp"],
    ["Amman, Jordan", "Middle East", 1861, 2025, "ekjgfmgggiffkhfgdhfghijijjfihiihkhifgkfhigkllkmnnqqq"],
    ["Amrāvati, India", "Asia", 1875, 2025, "efcacddkkheeehfhhhhhcdehegihhggkighijhlhjhjilkojmoll"],
    ["Amritsar, India", "Asia", 1875, 2025, "ggkffffkkjggffhgjeiiggililhkghhhijhhjejjhjhnmkmkklmn"],
    ["Amsterdam, Netherlands", "Europe", 1850, 2025, "gcgefiegffgcefhfgeihfggggjgfijhgjehgijfjellimmnjmooq"],
    ["Anaheim, United States of America", "North America", 1850, 2025, "bfcefgeggeggggggifeeeehhfiigfefglghifhkjijlmiklioqnm"],
    ["Anchorage, United States of America", "North America", 1893, 2025, "cgigehfgjdfgikigfiikigehehhifihehmkjkkijijlnjghmnojl"],
    ["Andorra", "Europe", 1850, 2025, "eagfhifhfhcaefjefefefggifhghimigiihgfggiikjllmllloor"],
    ["Ankara, Turkiye", "Middle East", 1850, 2025, "ekggijhjmdgggggjgffkihiifjifidhihjjjggkghhgiljlmnnop"],
    ["Ansan si, South Korea", "Asia", 1870, 2025, "feffdegchheeddedfeefgffhgejhghkhhfhihhgkkklklllinmnq"],
    ["Anshan, China", "Asia", 1868, 2025, "geihgeggffigeeceegfggefiheefgekghfhhihhhlkkmklmhmnop"],
    ["Antalya, Turkiye", "Middle East", 1857, 2025, "cgiiggkfdfgffjfcfekejjigjhhifiiilihhejhhhfjklklnmoqq"],
    ["Antigua and Barbuda", "Caribbean", 1864, 2025, "bdcbecbcddccfdccdcedffdfegedheihgegfgjhjijkmnmmnnnoq"],
    ["Anyang si, South Korea", "Asia", 1870, 2025, "feffdegchheeddedfeefgffhgejhghkhhfhihhgkkklklllinmnq"],
    ["Anyang, China", "Asia", 1891, 2025, "gddhgdeceidhihigfehkhhieeeikgifghhgieiiikoklmmjoqqrr"],
    ["Aparecida de Goiânia, Brazil", "South America", 1901, 2025, "idfcfjiccdegeggggeegeehcgfggegighhihkiilmkmlmnmooomr"],
    ["Arāk, Iran", "Middle East", 1882, 2025, "igjhhfgiffegkigghgffhliiehifhikfgghjfgjifkmnlknmooqq"],
    ["Arctic Ocean", "Ocean", 1902, 2025, "eggfgfcfihhijjimillkhkjhkgeeeghgehhgglhmkmmoqqqqrrrr"],
    ["Arequipa, Peru", "South America", 1898, 2025, "egdebcgeefgjgggeglgfefieiggggiggfijgjijkllmmmmlnmnmp"],
    ["Argentina", "South America", 1856, 2025, "accebbdbcbcafefcdfffbefffffjghcfigjhgikhkhjkillmomop"],
    ["Arlington, United States of America", "North America", 1850, 2025, "ffelffeehgceggfffjggfkhhjijhihklfiigiihhjihimimllnlp"],
    ["Armenia", "Asia", 1850, 2025, "fggeghjjmfghhfhiffgjihjgehjiifiihiiiegkgijeknjklmopq"],
    ["As Sulaymānīyah, Iraq", "Middle East", 1881, 2025, "ihigjegifeheiieighfghhhegiigijifgfgkeiijfjonklmmopqq"],
    ["Āsansol, India", "Asia", 1875, 2025, "egdbdfehghcfededgfggdehieghjkihkhfggjhkjjkjjklnjommp"],
    ["Ashgabat, Turkmenistan", "Asia", 1881, 2025, "gfgehfghfeheihehicdegkhfgeiggihegghiigjjglmmllmmnnnp"],
    ["Asmara, Eritrea", "Africa", 1892, 2025, "ceegdecddeehfghhgghiggdggggfcehgfgjhikjhkmmomoopqppr"],
    ["Asunción, Paraguay", "South America", 1877, 2025, "meeceegehffceheeciigggeihhhegigihhflkhkgijjlkkjlmnmp"],
    ["Athens, Greece", "Europe", 1850, 2025, "dhcjhijfhefhgfhhfeeigijigkhgkgjijjiiggggiijhnllnpopq"],
    ["Atlanta, United States of America", "North America", 1850, 2025, "fgcheefegideeggeeiggflhiliiiikkkgggfjhgilkihmkmkkpoo"],
    ["Auckland, New Zealand", "Australasia", 1863, 2025, "efdeddecegfeedefefffdfefgffggihifgjjgjgjmfimkjklloop"],
    ["Aurangabad, India", "Asia", 1875, 2025, "dhdbcedjjgeeeheifgffcddgegggfhgkjfgijhmgigkilknjnoll"],
    ["Aurora, United States of America", "North America", 1850, 2025, "biejggedffeiggeiggggfhgfjjjhghhkhihhgjjfiiiimlljlnln"],
    ["Austin, United States of America", "North America", 1850, 2025, "hdfkfggggfedggggfkgfgkghjhihijjkfiifiggiijijnklmlnmq"],
    ["Australia", "Australasia", 1880, 2025, "efficcgfdfbgidggefffghffefgfhhgeghejihkkjklinlmkopmq"],
    ["Austria", "Europe", 1850, 2025, "eceggiefegfbeehggeggghhheiefikieifhghjfigkmimmmloqpr"],
    ["Āzādshahr, Iran", "Middle East", 1882, 2025, "ihkhhfgifeegkiggggfghkhhehigiikggfgjfhjigkmmllnmoopq"],
    ["Azerbaijan", "Asia", 1850, 2025, "gffcfgjilefigegggfgighheehjggfhhgiigggjghjelnklmnnpq"],
    ["Bağcılar, Turkiye", "Middle East", 1850, 2025, "ejdgfeggicffffhieeeighhhfkhdifighjjighihghigmkmnooqq"],
    ["Baghdad, Iraq", "Middle East", 1881, 2025, "hggficekfehehhehfhgghhgefhighjiggggkfgiigjomklmlopqp"],
    ["Bahāwalpur, Pakistan", "Asia", 1875, 2025, "kglfjiglllihfiiijgiiggjmikhliijiijghkejiihhmmllklmno"],
    ["Bahçelievler, Turkiye", "Middle East", 1850, 2025, "ejdgfeggicffffhieeeighhhfkhdifighjjighihghigmkmnooqq"],
    ["Bahrain", "Middle East", 1893, 2025, "geejeegdhggghggeffghgidhigejhehefikeijhgknmmmmooprrr"],
    ["Bakersfield, United States of America", "North America", 1850, 2025, "bjfeghhggfgiegghjfeeeeihhjjhfggflfgiggjhjklmimlioqoo"],
    ["Baku, Azerbaijan", "Asia", 1850, 2025, "efeccfhgjddgfdgefeehfggeegjfgehhfiigggiggjfkmkmmnnpq"],
    ["Baltimore, United States of America", "North America", 1850, 2025, "egdgfcgchheffhhgefifekehkghiiikiggghjigikkhhmkmmknpo"],
    ["Bamako, Mali", "Africa", 1902, 2025, "ebcgeebdegheggefkffgfeeggeeehggfiikikkilmknolokknmop"],
    ["Bandar Lampung, Indonesia", "Asia", 1866, 2025, "aaaacbbbaadccccdcbbedfdfggifgegfgggghiiiijklnnmoopqq"],
    ["Bandung, Indonesia", "Asia", 1866, 2025, "bbaacbbcbadccdcdcbcedfefggifgfifgggghiiiihllmomnpqqq"],
    ["Bangkok, Thailand", "Asia", 1876, 2025, "eedbdccfeeeeefcecedeffhfhegfgifhigehkijjkjlkllllnnmp"],
    ["Bangladesh", "Asia", 1870, 2025, "deeecdfcgfgceccfdfeefeehggeihjhhhfhhkhiliiikkmnjppqr"],
    ["Banqiao, Taiwan", "Asia", 1871, 2025, "gddcabfbdddbeeeecdccffgfhghihiihhghihifhijllnnmkpqqr"],
    ["Baoding, China", "Asia", 1891, 2025, "gddifeeedgdigfggeeghhfiedeijhgegiggkeijikokmmnjnpppr"],
    ["Baotou, China", "Asia", 1891, 2025, "gffhiegefgeihhgfdcgkhfieedhiifehigghdikhjpmlnnkppopr"],
    ["Barbados", "Caribbean", 1855, 2025, "cbbccdcddcdebefddcebcfegdeiefffghgggfgkhjikmkmlnmnpp"],
    ["Barcelona, Spain", "Europe", 1850, 2025, "dafeghegfgcbdfjefdffegfifiggilhgihhgefgiiljlmmllmoor"],
    ["Bareilly, India", "Asia", 1875, 2025, "jggdegejiidhfffgiehjecfkgjijghhkjhjhkgkjikgjkkminnln"],
    ["Barquisimeto, Venezuela", "South America", 1910, 2025, "degbccdgehgeegkgdgeiehiiihigieiigkggijjnimmmlmmpmqkp"],
    ["Barranquilla, Colombia", "South America", 1908, 2025, "ccegaeddgegeeeigegdigdheghgigeijkkhkijjiimmnllnpoqmq"],
    ["Basrah, Iraq", "Middle East", 1893, 2025, "eeekedgehigiggigfgghggdijfgkheiefikfiiigkmmllmnlpqqq"],
    ["Bata, Equatorial Guinea", "Africa", 1901, 2025, "eaccdgedddcedeggggigfgdefeefgghehiigljilmklmnpknqpoq"],
    ["Battagram, Pakistan", "Asia", 1875, 2025, "gfjegfefhgefefiehehigfhkiifjhhhggjhhjgijggiomlmkmlmo"],
    ["Beijing, China", "Asia", 1891, 2025, "gechfeeddfdhggggefgghfieddikhgegigfkfijjknkmmmimooor"],
    ["Beira, Mozambique", "Africa", 1897, 2025, "effddeeeefidedfedegfggfehggeigffihdikjmjjlmnmnnlonmp"],
    ["Beirut, Lebanon", "Middle East", 1861, 2025, "dihedkeeffdejhefbheggiiiijgjhhhhjhifgifhhgklmkmooqrq"],
    ["Bekasi, Indonesia", "Asia", 1866, 2025, "baabdbbcbaeccdcebbcedfefhgiggehefhgghhhijiklnomoprqq"],
    ["Belarus", "Europe", 1850, 2025, "gfhefhefgggfggihheiighigfkhdhjhgihhfjigkeljilkmllnpp"],
    ["Belém, Brazil", "South America", 1912, 2025, "cgbdcdegegdgeigggdggfifggfiefdgjkfjijikokmoompnrpqpr"],
    ["Belfast, United Kingdom", "Europe", 1850, 2025, "ebfdfgffddcceehefegfeggfihihikghjffgijfjekhlmnokmmnr"],
    ["Belgium", "Europe", 1850, 2025, "fcgfgifgefgbeehffdigfgggfjggikifjfhghjfjelljmmnkloor"],
    ["Belgrade, Serbia", "Europe", 1850, 2025, "fgeigjgghhhefghhhfhhhihjflggkjkfjgigiigigjlhmllmoopq"],
    ["Belize", "Central America", 1890, 2025, "ccegddcecdceedffgfdfghjiigiggfhiieijhijiloilkkkloopq"],
    ["Belize City, Belize", "Central America", 1890, 2025, "cbfgcecececeecfegfdfghjhjgihgfhiigjkhjjikojkkkklonpq"],
    ["Belo Horizonte, Brazil", "South America", 1851, 2025, "hheccicbfcdgdehfeeefdeehefgffegdhfggjhgkjijlklllnopq"],
    ["Bengaluru, India", "Asia", 1868, 2025, "cbbfcbbechggfeehchfgedfeheghefgfhhhfijjlihkkojkmnppo"],
    ["Bengbu, China", "Asia", 1871, 2025, "gfffedfeeegdecgeffghgffkhihhegkhiefhihehiklmmomlnqrr"],
    ["Benghazi, Libya", "Africa", 1864, 2025, "ghhdghdeffffffdegiggjgjhfgkeiihjghhfgighkhklnkmooppq"],
    ["Benin", "Africa", 1886, 2025, "eccgdgcbbbgfdhggggfhhgghfdegfeehjehiikjgjlklomnlonmp"],
    ["Benin City, Nigeria", "Africa", 1886, 2025, "cbbeceaccbfgegegcegggfgffdegfefgieiiiijijmkknoompoor"],
    ["Benoni, South Africa", "Africa", 1881, 2025, "cedecfdeeadffcdfffhffhgihgdhgihgigfhikjilimjnkkkooko"],
    ["Benxi, China", "Asia", 1868, 2025, "geiggeggffigeecfdhfggffihefgfejggfhhihhhlkkmllmimmop"],
    ["Berkshire, United Kingdom", "Europe", 1863, 2025, "ffdggeddbceheeeggegegghihhikffjgdghgifjemikmmomkmoor"],
    ["Berlin, Germany", "Europe", 1850, 2025, "gchggieggggdfghghfihgfhgfjgeikieigigijgjfllhmkmjlnop"],
    ["Bexley, United Kingdom", "Europe", 1850, 2025, "fcgeghfgeeebdfifgeigehgggihgikhgjegghifjekkkmnnlmoor"],
    ["Bhavnagar, India", "Asia", 1875, 2025, "fgfbegfikihefgfhghfgeefidjghgghkifhjhelhjijlmjljnomn"],
    ["Bhayandar, India", "Asia", 1875, 2025, "efdadedgiheddfegfgegccdgegfgfhfkifejifjiiilkmlokoomp"],
    ["Bhilai, India", "Asia", 1875, 2025, "cebadeekjhdeegfehfghdfgifhgjhgfkifjijhkijikjljnjmnjl"],
    ["Bhiwandi, India", "Asia", 1875, 2025, "efdbdedhiheddfegfgefccdgegfffhgkiffjifkhiimjmlokoomp"],
    ["Bhopal, India", "Asia", 1875, 2025, "gfdadeejkifffiggigfhcdfhehiihggkighjkfkjjhijnjnhmnlk"],
    ["Bhubaneshwar, India", "Asia", 1875, 2025, "bgabddciihcedceeefggdffhfhgikhfghghhlkkiihkjkkmkponq"],
    ["Bhutan", "Asia", 1870, 2025, "fdfhddhdgffceebgfgefgfgghhgigjheegihigikhjjmkoplpqqr"],
    ["Bīkaner, India", "Asia", 1875, 2025, "igjfjhgklkigghggigghggikhkhkggiijiihjdkjiigmmklikmll"],
    ["Bilimora, India", "Asia", 1875, 2025, "egeadfehjifeeffhghegcdehdhhgghhkhfgihfkiijkkllokoonp"],
    ["Birmingham, United Kingdom", "Europe", 1850, 2025, "fchdghfgeeecefiffehgeggggihgikggjeghhjfjekjlmnollnor"],
    ["Bishkek, Kyrgyzstan", "Asia", 1877, 2025, "fhdegffcfedghjgcgiefcflggdffeghighgjjhhihhlmlmmkllnp"],
    ["Bissau, Guinea Bissau", "Africa", 1890, 2025, "cdeffbcaceccegfcgeefdgedeeeffdggfghjikjkknkmolnmmmoo"],
    ["Blackpool, United Kingdom", "Europe", 1850, 2025, "fbgdfhegdedbeehefehgefgfhiigijhgjfggijfjdlilmnokmnor"],
    ["Blantyre, Malawi", "Africa", 1897, 2025, "ghgdegegeiigeegdedhefgggiigdihgfhheikkkkklmlmlmnpnlp"],
    ["Bogor, Indonesia", "Asia", 1866, 2025, "baabcbbcbaeccdcebbcedgefggifgfhfgggghhiiihklmnmooqqq"],
    ["Bogotá, Colombia", "South America", 1908, 2025, "ccggbeccgegdefjfghgggdigghgiggiiijijikkjjmklklmqpqkp"],
    ["Bolivia", "South America", 1898, 2025, "didebaghdcdgfgeggichefgdefgfhjgeghhikiimkjmllmooonlp"],
    ["Bolton, United Kingdom", "Europe", 1850, 2025, "fcgdfhggeeecefiffehgeggghiigikhgjeggijfjelikmnoklnnr"],
    ["Borivli, India", "Asia", 1875, 2025, "efdadedghheddfegfgefccdgegfgfhfkifejigjihilkmlokoonp"],
    ["Borough of Queens, United States of America", "North America", 1850, 2025, "ffcfhdfchhefgghgefheejeikgghijkiggghiigijlhimjmmlnoo"],
    ["Bosnia and Herzegovina", "Europe", 1850, 2025, "dfeigigfghfdefhggfhhhhhjfkegkjkfjhhghhfihjmhmmmnpopr"],
    ["Boston, United States of America", "North America", 1850, 2025, "egcfgdfchhdefghgdfieeheijgfhijlihgggiihjhkhimjlmmnop"],
    ["Botswana", "Africa", 1897, 2025, "egfedcfgdegehggffeigiigeiiiggjgfeggklikkiklnikjmnoio"],
    ["Bouaké, Cote d'Ivoire", "Africa", 1889, 2025, "cbecgbcacfedffhedfgigggfgefgfeggifiijkiiknjmnnmlpmmq"],
    ["Boumerdas, Algeria", "Africa", 1850, 2025, "ddgdghfghgcdfgkgfeffdfhihgggikhfiiggdefhkkilmnmnnopr"],
    ["Bournemouth, United Kingdom", "Europe", 1850, 2025, "gcgeghfgeeebdeiffeigehgggihghkggjegghifjelkkmnnkmoor"],
    ["Bradford, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggfhiihikhgjeggijfjelikmnnllnnr"],
    ["Bratislava, Slovakia", "Europe", 1850, 2025, "gdgggifffggcefhghfhhghhhfkgfjkjfifigijgifkmgmlmkoppq"],
    ["Brazil", "South America", 1901, 2025, "gcdccgfcbbefeeefgfefeggehgfggggehhigkijkoknomonpqqnr"],
    ["Bremen, Germany", "Europe", 1850, 2025, "gcgffifgfggcefhfheihgfhggjgfikififhgijfjflkimlmjlnoq"],
    ["Bridgetown, Barbados", "Caribbean", 1855, 2025, "cbbccdcddcdebefddceccfegdeiefffghgggfgkhjikmkmlmmnpp"],
    ["Brighton, United Kingdom", "Europe", 1850, 2025, "gbgeghfgefebdfiffeigehgggihghkhgjegghifjelkkmnnlmoor"],
    ["Brikama, Gambia", "Africa", 1890, 2025, "cdeffcdacfcdffgcffgfegfeeeeffehgghhjhkjikoklmkmlmkop"],
    ["Brisbane, Australia", "Australasia", 1858, 2025, "adehcegdeeddfgdeeidggefefgggefgfdfghfiihkkklkmklnpoo"],
    ["Bristol, United Kingdom", "Europe", 1850, 2025, "fcgehhfgeeeceeiffeigehgggihgikggjegghjfkeljkmnnklnnr"],
    ["Brooklyn, United States of America", "North America", 1850, 2025, "ffcfhdfchhefgghgefheejeikgghijkiggghiigijlhimjmmlnoo"],
    ["Brussels, Belgium", "Europe", 1850, 2025, "fcgegifgefgbeehggdihfgggfiggikhfjehghjfjelljmmnkloor"],
    ["Bucaramanga, Colombia", "South America", 1914, 2025, "icececfegceeiggggcieighghhfieiijjgiglikkinmllmornqkq"],
    ["Bucharest, Romania", "Europe", 1850, 2025, "hiehghgghefefghggfgihiihdjgdijjeihihhigifjkglkmlnopq"],
    ["Bucheon si, South Korea", "Asia", 1870, 2025, "feffdegchheeddedfeefgffhgejhghkhhfhihhgkkklklllinmnq"],
    ["Budapest, Hungary", "Europe", 1850, 2025, "gffhhjfgfggdefhhhfhghhhifkgfjkkfjgihijgjfjmhllmlpppr"],
    ["Buenos Aires, Argentina", "South America", 1856, 2025, "bddgccfcdbdcgfffbeefdfhgfghigidghgjhhhlijijlkkklnnnn"],
    ["Buffalo, United States of America", "North America", 1850, 2025, "fheggdfdjiceghiheghgfjdhkghhijkjhgghiigikkhhnklllmno"],
    ["Bujumbura, Burundi", "Africa", 1901, 2025, "ieececcceddifeefehgfggfcgeeefefeikjimgjkmiloopmoqoor"],
    ["Bulawayo, Zimbabwe", "Africa", 1897, 2025, "ehhgdcgiefifhggffdjgikgfiiighjgfgggjkkmkijkmjllmmokp"],
    ["Bulgaria", "Europe", 1850, 2025, "eiehgghgidfeeghhfegihiihekgeiijfiiihghghgikgmkmmooqr"],
    ["Burkina Faso", "Africa", 1902, 2025, "dacedgcdfggeggeiigghgeefgfefigifiimikjilljmnlnlmmmmp"],
    ["Bursa, Turkiye", "Middle East", 1850, 2025, "dkehhghhldgggfhifffjhhiigkhfiejihijiggighghimjlmoopp"],
    ["Burundi", "Africa", 1901, 2025, "ieecfccceddigeeeghffggfdheeegeeeikjimgkkmglpnplnqpor"],
    ["Busan, South Korea", "Asia", 1870, 2025, "fefecdgdhgdecdeeffdgfffhgeihgijghfhiihgjljlkmkljmmnq"],
    ["Cabo Verde", "Africa", 1894, 2025, "cegecbecfdfdfgeefkgehgfgffehghgeejjigkjhmklklkomplpq"],
    ["Cairo, Egypt", "Middle East", 1861, 2025, "chhgeifdfggfjfeechgghiiiijfihiihihhhgjehhgklllnoqqqq"],
    ["Calgary, Canada", "North America", 1866, 2025, "gjffgfihhffgghfhfghjgkihliidjfikfgfgjjhojjgkkmkklljn"],
    ["Cali, Colombia", "South America", 1901, 2025, "edebegfdeefegceejigiegfghghggggfiijhkkmjogllkmmppqkq"],
    ["Camayenne, Guinea", "Africa", 1890, 2025, "bbeefacaddbcfdfeddfgegeefeeefehgffhigijjknknonplnnpp"],
    ["Cambodia", "Asia", 1891, 2025, "ccgefcdeegadcdcedhfjfggfhfjgggigfhjihljijlkmljnmponp"],
    ["Cambridge, United Kingdom", "Europe", 1850, 2025, "gcgegifgeeebdfiffeigehgggihgikggjegghjfjekkkmnnlloor"],
    ["Cameroon", "Africa", 1888, 2025, "facdfebbaefcdeedgfhgjghffcgfgfgghgighkiijlkmooomqqor"],
    ["Campinas, Brazil", "South America", 1851, 2025, "ihfdeiccgeehdfhfdcdgeegiefheeggciehgiihjiikkklllnopp"],
    ["Campo Grande, Brazil", "South America", 1893, 2025, "cgeicfcdjddedgfefhgdiggfieihgggjekhikhiikkjnnlklnmno"],
    ["Canada", "North America", 1873, 2025, "efifdfeeehgfgfheggfhgeijihfkgihfhehihihkhjlnjnmmmlmr"],
    ["Cancún, Mexico", "North America", 1870, 2025, "dddefcecdfdddddcefegegfgfjijgjiheghijigjkkljkkkkoopr"],
    ["Cangzhou, China", "Asia", 1891, 2025, "gdeigeeedgdhgfggefhihgifeeikhgegihgjeijiknllmnjopqqr"],
    ["Çankaya, Turkiye", "Middle East", 1850, 2025, "ekggijhjmdgggggjgffkihiifjifidhihjjjggkghhgiljlmnnop"],
    ["Cape Town, South Africa", "Africa", 1850, 2025, "cbbdedbdbagdbccccdedgdeghhgeggecgifehgiilikillmlmnmn"],
    ["Caracas, Venezuela", "South America", 1886, 2025, "cebcfhedcddcccdgehedggdffegjhgghidjikhgijlinmmnlqnlq"],
    ["Cardiff, United Kingdom", "Europe", 1850, 2025, "gcgegifgeeeceeiefeigeggggihgikggjehghjfkeljlmnnklnor"],
    ["Cartagena, Colombia", "South America", 1908, 2025, "ccegaeedgfgeeeigegdhgeheggfifeiikkhkikjkjmmnllnooqmq"],
    ["Casablanca, Morocco", "Africa", 1850, 2025, "hcefggfgfebceeifeceeefghefghijhhijghdehhjjhnlmlpmnnr"],
    ["Central African Republic", "Africa", 1906, 2025, "cbahdadcffegghgifgifgcfgdeegghgiiigkigiklkoqmolnqqor"],
    ["Chad", "Africa", 1902, 2025, "edcdegefdgiejigjigfhfggggfdehhigiiiiikglljkonqnooomr"],
    ["Chandigarh, India", "Asia", 1875, 2025, "ggiefgfijiegffffiehiefikhkhkhihhiihhjfkjhkglllmimmmo"],
    ["Chandler, United States of America", "North America", 1850, 2025, "ajdghgfiiffiggeghfefefhgfjjhghfijgggggjgikimkmmlnpno"],
    ["Changchun, China", "Asia", 1871, 2025, "egihfggegigffdecgefeggfhidifeghghehhgjgjklmjnmkinonq"],
    ["Changde, China", "Asia", 1882, 2025, "ecefecffcdcheffgigffhkhkghfgkijgfigjhfhihilmlplmnpqr"],
    ["Changsha, China", "Asia", 1871, 2025, "efdfccfdeehbechdfffifhgjhjgffhjjieggjhfhihkkmonloqrr"],
    ["Changshu City, China", "Asia", 1871, 2025, "gddecbeceeededfeffegfhgjgiiiegkihefghgfgjjlmnpmlnrrr"],
    ["Changwon, South Korea", "Asia", 1870, 2025, "fefecdgdggdecdeeffdffffggeihgijghfhiihgjkjklmkkjmmnr"],
    ["Changzhi, China", "Asia", 1891, 2025, "geehhcfcfidgihigfehmhjifgfikghfhgiiheihgkollnmkqqqrr"],
    ["Changzhou, China", "Asia", 1871, 2025, "gedeccfceeededfefefgfhgjhihifgkhhefghgegijlmnpmmnqrr"],
    ["Charlotte, United States of America", "North America", 1850, 2025, "fhdgfdedgidfgghfehhffkhhlhjiikjkfgggjhgikkihmkmlkppn"],
    ["Chengdu, China", "Asia", 1902, 2025, "ecdeefcefggedgfikkjigiggjkihhiigkfffgjigmlnkomloqprr"],
    ["Chennai, India", "Asia", 1865, 2025, "ecccfdbbecfhdgegfefghddfheffichdihghhjkkiijmnjlmoqpq"],
    ["Cheongju si, South Korea", "Asia", 1870, 2025, "geffdegdhheeddeeffefgffhgdihgikhhfgiihgklkkklkkjomnq"],
    ["Chiba, Japan", "Asia", 1873, 2025, "gfgdcdhfeeebcfiegfdfgdhgdhihijihihggjgejljklkkllnoor"],
    ["Chicago, United States of America", "North America", 1850, 2025, "fieffcgeihcefhhgeghgfkdgkgjiihijghghihfijkihnklkkmmn"],
    ["Chihuahua, Mexico", "North America", 1867, 2025, "jfhggefgegdhfhhchehjigiifihlkkikhihfhkhfijlmllknkoqq"],
    ["Chile", "South America", 1888, 2025, "bbbededccgdcecedgefffjfehcigifiefgkjikihkmjknlmnqopr"],
    ["China", "Asia", 1875, 2025, "gdecdfdcfebddddeeeeeecgiggefeiggdfhfgggkhklmnpomqrrr"],
    ["Chisinau, Moldova", "Europe", 1850, 2025, "hgfehiffgfhfggihhegigiigdjhdhiigjijhiigjekjglkmlnooq"],
    ["Chittagong, Bangladesh", "Asia", 1870, 2025, "ecedbcecefhceccfeffefeegfgfigiihifhgkhhkiijkllmjqpqr"],
    ["Chongqing, China", "Asia", 1899, 2025, "gicfdehddfgggeiiikikjgjhikkifjkgjheehigkjjmkqmkpqprr"],
    ["Chula Vista, United States of America", "North America", 1850, 2025, "cfcffgdfhegfgfggifefffhgfhjhfefglghifgkkijlnikkinqml"],
    ["Cincinnati, United States of America", "North America", 1850, 2025, "ghdgfegeijdfghhgeghgflfglhiiiijkghhhihfikkihmklkknno"],
    ["City of London, United Kingdom", "Europe", 1850, 2025, "fcgegifgeeebdfiffeigehgggihgikggjegghjfjekjkmnnlmoor"],
    ["Ciudad Guayana, Venezuela", "South America", 1850, 2025, "ddacbcccfccfcefgdcddccefgefheeheihgiffkggijllmlnmono"],
    ["Ciudad Juárez, Mexico", "North America", 1850, 2025, "ahehhjehicfhfechggfgegggfkhhgiijhhhhhfjggijlmmlmmooq"],
    ["Ciudad López Mateos, Mexico", "North America", 1878, 2025, "dbaaabedfdddceefghhifgiikiieijhekjfijhiijlkjlkkllnpq"],
    ["Ciudad Nezahualcoyotl, Mexico", "North America", 1878, 2025, "dcaaabeefddeceeffhhjffiilihejjhekjfijijijlkjlkkllnpq"],
    ["Cleveland, United States of America", "North America", 1850, 2025, "ggegfdfeiidfghigeghgfkdhlgiiijkjhhghjhfjkkhhmkkkkmno"],
    ["Cochabamba, Bolivia", "South America", 1898, 2025, "egegccggdefihiggijggfdifigefgjgdfijijijlklmmmmmnpnmp"],
    ["Cochin, India", "Asia", 1865, 2025, "eeaadbabcbhhffbefdefffefgeeegeifihefgjjljilkmkkmoppq"],
    ["Coimbatore, India", "Asia", 1865, 2025, "beaadaabdbggefceedefgeeffeefgeifihfggijliikknjknnpop"],
    ["Colombia", "South America", 1908, 2025, "abefaeccfegceejgggffgdigghgiefhhiigkikkkkmmmlmnqpqmq"],
    ["Colombo, Sri Lanka", "Asia", 1865, 2025, "egabcbabbbggdebehdffgecghegffcgehgfegjijkjlmmmlmmopp"],
    ["Colorado Springs, United States of America", "North America", 1850, 2025, "bjdlggfcfeejgheiggggeigfikiihhhkihhggjkfiiijmllkmomo"],
    ["Columbus, United States of America", "North America", 1850, 2025, "ghdgfdfeijdgghigeghgfkehlhihiikjgghhihfilkihmklkknnn"],
    ["Comoros", "Africa", 1922, 2025, "deeeeddfgieeggeigehiedhfegeghhkfkikjklnlnnnmomnoomoq"],
    ["Conakry, Guinea", "Africa", 1890, 2025, "bbeefacaddbcfdfeddfgegeefeeefehgffhigijjknknonplnnpp"],
    ["Contagem, Brazil", "South America", 1851, 2025, "hhecdicbgcdgdehfeeefddehffgeffgdhfggjhgkjijlkmklnopq"],
    ["Copenhagen, Denmark", "Europe", 1850, 2025, "gdhfggfgefgefhighfihgfhggkheikifighgjjfjdmkiklmjmnop"],
    ["Córdoba, Argentina", "South America", 1856, 2025, "bffgcbedfeebhggddgggdghffhekgidfhhkjghjhkhjjikjlmkmo"],
    ["Corpus Christi, United States of America", "North America", 1850, 2025, "hcejfhfegfedfffgfkfgfjfiihihikjkfihfiggiikjjnkmllmnp"],
    ["Costa Rica", "Central America", 1908, 2025, "bcefcgedgfifeehgfhehgejgfgegggiiijililllklmlkjlonplr"],
    ["Cote d'Ivoire", "Africa", 1889, 2025, "cbdcgbbacfeceegeeefhggffgdggfegghfhhikjjkmjmnmolpnnq"],
    ["Cotonou, Benin", "Africa", 1886, 2025, "dbcfcfabbafhegggffffgfggfddfgefgidiijjjijlklnnnloonp"],
    ["Coventry, United Kingdom", "Europe", 1850, 2025, "fchdgiggeeecefiffehgeggggihgikhgjeghhifjekjkmnollnor"],
    ["Coyoacán, Mexico", "North America", 1878, 2025, "dcaaabeefddeceeffhhjffiilihejjhekjfijijijlkjlkkllnpq"],
    ["Croatia", "Europe", 1850, 2025, "eeeghigggggdefiggfghghhiekfgjkkejgighhfigjmhmmmmpppr"],
    ["Croydon, United Kingdom", "Europe", 1850, 2025, "fcgegifgeeebdfifgeigehgggihgikggjegghifjekkkmnnlmoor"],
    ["Cuauhtémoc, Mexico", "North America", 1878, 2025, "dcaaabeefddeceeffhhjffiilihejjhekjfijijijlkjlkkllnpq"],
    ["Cuba", "Caribbean", 1851, 2025, "ccacbedefebedefccbecdegfefeghggfhgffhhhiillmimljmoqq"],
    ["Cúcuta, Colombia", "South America", 1914, 2025, "ibeceegeidfejgfggcjekihhihgieiiijgkgkikkinkmklnqlqio"],
    ["Cuiabá, Brazil", "South America", 1901, 2025, "jcfddiieaceeeeffgehggghdegiifgifhhijjihjmkmmmmmmmonq"],
    ["Culiacán, Mexico", "North America", 1871, 2025, "cefecdbcfdggggdgeehjjiikhgllkligihhgkigiinjjlkllqonr"],
    ["Curitiba, Brazil", "South America", 1851, 2025, "igfdgibcheegdgffeceffdghgfgefgfejfighihjjhkkkllknnno"],
    ["Cuttack, India", "Asia", 1875, 2025, "bgabddciihcedceeefggdffhfhgikhfghghhlkkiihkjkkmkponq"],
    ["Cyprus", "Europe", 1857, 2025, "cehhffkgffgfejfcfdjeiihgjhhiehiikhghgjgghfjllkmoopqq"],
    ["Czechia", "Europe", 1850, 2025, "fdfggjegfggdefhghfhhggghfjgfikjeigigijgjfklhmlmknpoq"],
    ["Da Nang, Vietnam", "Asia", 1890, 2025, "ebffhdegggaedceeefgifhggifhggihghgjjgkkijojkljjnppop"],
    ["Daegu, South Korea", "Asia", 1870, 2025, "fefedegdggdecdeeffdfgffghdhhfijghfhiihgjkjklmkkjnmnr"],
    ["Daejeon, South Korea", "Asia", 1870, 2025, "geffdegdhheeddeefedfgffhgdihgikghfgiihgkkkkklkkjomnq"],
    ["Dakar, Senegal", "Africa", 1890, 2025, "cdeffcccbfceefgcefiffgfeeefggeifgiijgjiiknkkmlnlmjpp"],
    ["Dalian, China", "Asia", 1887, 2025, "fffejfefdcfdhefgfggigidhgheiihgdghhhifkkllmlmniloppr"],
    ["Dallas, United States of America", "North America", 1850, 2025, "ffekfeeeggcffgffejhgekhhjijhihklfiigihhhjihimimllnlp"],
    ["Damascus, Syria", "Middle East", 1861, 2025, "fljghmghghgekiehdifgiijiijgihiihjhhfgjfiifllmkmnnqpq"],
    ["Dammam, Saudi Arabia", "Middle East", 1893, 2025, "feejdehchggghghffgghgichigfjhehefikeijigknmmmmonqrrr"],
    ["Dandong, China", "Asia", 1869, 2025, "hehffeegfhggfccfdgefgfgiheffhejhffghigghlkkmllmimmpp"],
    ["Dar es Salaam, Tanzania", "Africa", 1892, 2025, "ccefgcbadcccefeeggfhegfggfggcfhffihkhmhijlmopnqnponq"],
    ["Datong, China", "Asia", 1891, 2025, "geehhegeegejgggfdegihfieeehiheehihgheikgjpmlmnjopopr"],
    ["Dehra Dūn, India", "Asia", 1875, 2025, "ifhdfhfhihcgfdfeifhiedfkgjhjiiihhhjhjfkjhkhlklmjmnnp"],
    ["Democratic Republic of the Congo", "Africa", 1912, 2025, "deacedeeefdfeigfgegecheeddgegdikihkiiijnkmqooomqqrrr"],
    ["Denmark", "Europe", 1850, 2025, "hdhefgfgeggeehighfihgghghjheikigigggjjfjemkilmnjlnoo"],
    ["Denver, United States of America", "North America", 1850, 2025, "biejggedffeiggeiggggfhgfjjjhghhkhihhgjjfiiiimlljlnln"],
    ["Depok, Indonesia", "Asia", 1866, 2025, "baabdbbcbbedcdcebbcedgefhgjfgehfghgghhhiihklnomnprqq"],
    ["Derby, United Kingdom", "Europe", 1850, 2025, "gcgdgifgeeecdeiffehgeggggiigikggjegghjfjeljkmnollnor"],
    ["Detroit, United States of America", "North America", 1850, 2025, "fheffcfdiicfgghgefgffkdgkgihiijihhgiihfikkhhnjlkkmno"],
    ["Dhaka, Bangladesh", "Asia", 1870, 2025, "eeeeccfcffgdedcfdgeefefhgffigjhhhgggjhjliiikkmojopqr"],
    ["Diyarbakır, Turkiye", "Middle East", 1850, 2025, "eihfhiijmfghgfgiegejhhhifiighehiijhiggkgjifjmjlmnopq"],
    ["Djibouti", "Africa", 1886, 2025, "cedfffffcedfgdefffeeiihhffdiheegkfijhhjkjnlmmklmqqpp"],
    ["Djibouti, Djibouti", "Africa", 1886, 2025, "ceeeeeefcfcffdefffeeiihigfeiicegjfijghkkjnmmlllmqqqq"],
    ["Dnipro, Ukraine", "Europe", 1850, 2025, "hhgefhffifgggehijeghgihfejidghhgiijhihiiekhhlkmmnnop"],
    ["Doha, Qatar", "Middle East", 1893, 2025, "geeieegdhffgighgffghhidhigeihchffikdiiggjooommpoqrrr"],
    ["Dombivli, India", "Asia", 1875, 2025, "efdacedhigeddfegfgefccdhegfgfhfkiffjjfkhhilkmlokoonp"],
    ["Dominica", "Caribbean", 1855, 2025, "cbbccdcddcdfbdfddcecdfdhceidffgghgfgfgjhjikmkmmmmnop"],
    ["Dominican Republic", "Caribbean", 1875, 2025, "dfbcccbeeedcbddecfffdeegdheeghgfheehjiijikmknnllomor"],
    ["Donetsk, Ukraine", "Europe", 1850, 2025, "hhgdfgffifgggegijefhghheejjdghhghijhihiiekgilkmmmnop"],
    ["Dongguan, China", "Asia", 1865, 2025, "fhedfbacebddfdddhcedeefghhgjhhhikggigifjiigmnmmjnorq"],
    ["Dortmund, Germany", "Europe", 1850, 2025, "fcgfgifgfggbeehfgeihfgggfjgfikifjfhghjgjellimmmklooq"],
    ["Douala, Cameroon", "Africa", 1886, 2025, "cdbcdfbcbcheeeceeegggghhfeeggegfieihiijikmklnnomqooq"],
    ["Dubai, United Arab Emirates", "Middle East", 1893, 2025, "geeheegdheegihggfffighefiigiechegkkdhhhhioopomqmrrrr"],
    ["Dublin, Ireland", "Europe", 1850, 2025, "fbgdgggfdecceeiefegfehgfhhigikghjfgghjgjekilmnoklnnq"],
    ["Dudley, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggggihgikggjeghhjfjeljlmnnklnor"],
    ["Duisburg, Germany", "Europe", 1850, 2025, "fchfgifgeggbeehfgeihfgggfjgfikifjehghkgjellimmmklooq"],
    ["Dundee, United Kingdom", "Europe", 1850, 2025, "ecgdfgfgcecdefhefehgeggfiijhjjihigffijgjelillookmmnq"],
    ["Duque de Caxias, Brazil", "South America", 1851, 2025, "jhfddkabgdehdefffeeedeehefgffgfejdifjihijikkkmklnoop"],
    ["Durban, South Africa", "Africa", 1881, 2025, "ccdgcdceccbeeddegegefhgggfdfgiggggghijjilhnllllknmmp"],
    ["Durgapur, India", "Asia", 1870, 2025, "defebdgcgfhefedeegfggeeihffjhlhiifghjhilijjjklnjonmq"],
    ["Durham, United Kingdom", "Europe", 1795, 2025, "eddhdgijiebgedgggffcddegeegffffiihkhfifhhghijjmolmoq"],
    ["Durham, United States of America", "North America", 1850, 2025, "fhdffdfdghdeggggefhgekghlgiiijkjggfgjigikkjhmlmlkopo"],
    ["Dushanbe, Tajikistan", "Asia", 1875, 2025, "ghhfhgfgfeeffhidggeedeiihgfhghgifhgikgjjfijmmmlklnmq"],
    ["Düsseldorf, Germany", "Europe", 1850, 2025, "fcgfgiegefgbeehfgeihfgggfjgfijifjehghkgjellimmmklooq"],
    ["East Timor", "Asia", 1913, 2025, "agcdccgfgdgidieegeigfieeefigkgijhijjjiklimnkmmlooopp"],
    ["Ebute Ikorodu, Nigeria", "Africa", 1886, 2025, "dbdgcfabbafgeghgefffgfggfdeffefhjdiijjjiklkknnnloooq"],
    ["Ecatepec, Mexico", "North America", 1878, 2025, "ccaaabeefdddceefghhiffiikiieijiejjfijiiijkkilkklknpq"],
    ["Ecuador", "South America", 1901, 2025, "ececdgededeegedeihggegfggegghggeiikgkjkjoglmlnmpqqmq"],
    ["Edinburgh, United Kingdom", "Europe", 1850, 2025, "ecgdfgfgdecceehefehgeggfhiihijhhjfffijfjelillookmmnq"],
    ["Edmonton, Canada", "North America", 1871, 2025, "hejeffifffhgheifghhhjghjkgfhgiiigfgjhijmkiikjljknjkn"],
    ["Egypt", "Africa", 1869, 2025, "ggfifdggefjdefcigehihgjhifeiijgjghggihgiihjkmlnopqqq"],
    ["El Paso, United States of America", "North America", 1850, 2025, "ahehhjehicfhgechggfgehhgfkhhgiijhhhhggihgijlmmlmnpoq"],
    ["El Salvador", "Central America", 1911, 2025, "fcfdfccgfhgecegekggieigfiggfigjjiikikmkoillkiikpnqmr"],
    ["England, United Kingdom", "Europe", 1884, 2025, "ebdeeifefeigehegfgkhhgjijgejgdgghihfjejkjknnnnlmnopr"],
    ["Enugu, Nigeria", "Africa", 1886, 2025, "cbbedebccbhfegdfefggfgggfddgfffhhdhhiijijmkknoompoor"],
    ["Equatorial Guinea", "Africa", 1901, 2025, "eaccdgecddcedegggghgfgeegeefggheiiigljhlmklnopknqqoq"],
    ["Erbil, Iraq", "Middle East", 1850, 2025, "dggeghgikggihefiegeihhgheihhheihiihiggkeiifioklmnqpq"],
    ["Eritrea", "Africa", 1892, 2025, "efegeedccffgghihgggjggcggghgcfihfgjgikigklmnmnnoqonr"],
    ["Esenler, Turkiye", "Middle East", 1850, 2025, "ejdgfeggicffffhieeeighhhfkhdifighjjighihghigmkmnooqq"],
    ["Eskişehir, Turkiye", "Middle East", 1850, 2025, "djfghhgildgggghifffjhhiifkificiihjjjggjghhgimjlmnopp"],
    ["Essen, Germany", "Europe", 1850, 2025, "fchfgifgeggbeehfgeihfgggfjgfikifjfhghjgjellimlmklooq"],
    ["Estonia", "Europe", 1850, 2025, "gfgdggeegfgefhhgheiggghhhkiehkhghigfjhgkemjjlkmklmoo"],
    ["Eswatini", "Africa", 1881, 2025, "cddeeedfecefgceffegedhggggdhgifghgghiikilimjnllkonlp"],
    ["Ethiopia", "Africa", 1901, 2025, "ecdcecgdgeedgeeeghigegfehefeeghfhiigliikmjoompopqpqq"],
    ["Exeter, United Kingdom", "Europe", 1850, 2025, "gcgehifgeedbeeiefeigehggfhhghjggjegghjgkelkkmnmjlnor"],
    ["Faisalābād, Pakistan", "Asia", 1875, 2025, "gglghgfkkkhhfghhjeiighjlhkhkhiihikhhiejjiignnkkkkllm"],
    ["Farīdābād, India", "Asia", 1875, 2025, "igidggfjkjghggfhiehicdhkfjhjghhiihjilfliikgjmklimnlm"],
    ["Fès, Morocco", "Africa", 1850, 2025, "hehgggfghfcceejefddeefhgeghhjlihhihhdeihjjgllmlnlooq"],
    ["Fiji", "Pacific", 1910, 2025, "fdefdedegcggiefeehfggfhggcegijgiijhligkkmolnkonnoqqq"],
    ["Finland", "Europe", 1850, 2025, "ghgegfeegfhgfigfhhighhiiilkgiljgiiggkhgjelkjkkmkmnmo"],
    ["Fort Wayne, United States of America", "North America", 1850, 2025, "fhdggcfeiicfghhgeghgfldglhiihhjjhghhihfikkihmkllkmmo"],
    ["Fort Worth, United States of America", "North America", 1850, 2025, "ffflfffehgceggegejggfkhhjijhihklfiigiiihjihimimllnlp"],
    ["Fortaleza, Brazil", "South America", 1896, 2025, "ceedefcfcgccfggdgfjggggggiffhhfgfiiihiikmnkmmmlopopq"],
    ["Foshan, China", "Asia", 1865, 2025, "fgedfbacfbdegeedhcfdedfghigjhhhijfgigifjiigmnmmjnorq"],
    ["France", "Europe", 1850, 2025, "dbgfgiegefeadeiffdgffhghfifgjkigjghggifjflkkmnmlmopr"],
    ["Frankfurt am Main, Germany", "Europe", 1850, 2025, "ebgffiegefgbeegfhdihfgghfjffijiejfhfhkgjeklimmmkmooq"],
    ["Freetown, Sierra Leone", "Africa", 1890, 2025, "bbeeebcadebcfdfeddfhfgeefdefeehggfhigijjkoknonokooop"],
    ["French Guiana", "South America", 1887, 2025, "ccaedfccddfbdcefeeffhffehfggfgehfeijiihijmkmnmpoqonq"],
    ["Fresno, United States of America", "North America", 1852, 2025, "ghefffeieehhdggggeedefhhhilgfiggkehghgkhijkkkmmjpqpp"],
    ["Fukuoka, Japan", "Asia", 1870, 2025, "ededccfdgfcecdefefdffefgfehghijghgghihgjljllmmlkmmor"],
    ["Fushun, China", "Asia", 1868, 2025, "geihgeggffigeecedhfggfeihefffdjggehhihhhlkklllmhmmop"],
    ["Fuxin, China", "Asia", 1868, 2025, "feiggdfgeeigedceegegfffhggfefekhgehghihhlkklllnhmnop"],
    ["Fuzhou, China", "Asia", 1850, 2025, "fgedbdgcecaddedddfdfcfdeeghihihgjihggghfhiiinomllpqq"],
    ["Gaborone, Botswana", "Africa", 1881, 2025, "cgdedheffcdffdehhgghghigiieiihjgigegikjhliminjjmonin"],
    ["Gambia", "Africa", 1890, 2025, "cdeggcdbcebdfggcgeegfgfedeffgdhgfgijhkkkkokmmlmmmmoo"],
    ["Gaza, Palestine", "Middle East", 1861, 2025, "diifdjfefhefjgeedgfggiiijjeighigihhfgiehigkmmlmopqqq"],
    ["Gaziantep, Turkiye", "Middle East", 1850, 2025, "dhgfijgimfgggffiefejgghigiigiehijjijggjfiigimklmnoqq"],
    ["Geelong, Australia", "Australasia", 1856, 2025, "hfeefgefffhegheeffghhdedfgeddfefieggjilhiighmkmmoplo"],
    ["Genoa, Italy", "Europe", 1850, 2025, "eceffhdedfeacdjffefeehghehefjkieiggghgfhhkljmnmlnqpr"],
    ["Georgetown, Guyana", "South America", 1886, 2025, "bdbcegedccddcccfefeghgeegfehhgefgfikgiiilmklnlomoooq"],
    ["Georgia", "Asia", 1850, 2025, "fhfefgiildfhgeghgefighigeiiggfhigijiggjghiekmjlmnopq"],
    ["Germany", "Europe", 1881, 2025, "ghddffhfhgfihfkehhgijdhjkiggkfghgijfjfhllimmlnkkoppq"],
    ["Ghana", "Africa", 1886, 2025, "cccecfbccbgfegffgeeihgghfeegfefgieiijjjikmjlnmnlonnq"],
    ["Ghāziābād, India", "Asia", 1875, 2025, "igieggfjkjfhggfhieiicdhlfjhjghhiihjikfkiikgjmllimnlm"],
    ["Giza, Egypt", "Middle East", 1861, 2025, "chhgeifdfggfjfeechgghiiiijfihiihihhhgjehhgklllnoqqqq"],
    ["Glasgow, United Kingdom", "Europe", 1850, 2025, "ecgdfgffdeddffhefehgeggfiiihikhhjffgijfkekillnokmmnq"],
    ["Gloucester, United Kingdom", "Europe", 1850, 2025, "fcgeghfgeeebefiffehgeggggihgikggjeghhjfjekjlmnnklnnq"],
    ["Goiânia, Brazil", "South America", 1901, 2025, "idfdejiccdegeggggfegeehcgggfegighhihkiilnkmlmnmooomr"],
    ["Gold Coast, Australia", "Australasia", 1858, 2025, "adegcefdeeedffddehdggeeeegggffgfdfghgiihjkkllmllnpoo"],
    ["Gorakhpur, India", "Asia", 1875, 2025, "ghecdfeihhcgddeegfehddgjehiiijglhfigjgkjimjjjmmimmkp"],
    ["Goyang si, South Korea", "Asia", 1870, 2025, "fegfeegdhhfeedeefeefhffhhdigghjhhfhiihgkkklklkkiomnq"],
    ["Graz, Austria", "Europe", 1837, 2025, "cefdceeghedcefccdgedeefgfgfgdghiehfghghfhgkmkoknopqr"],
    ["Greece", "Europe", 1850, 2025, "dhcjhhifieegffhifefihijifkggjhkhijiiggggiijhnllnqoqq"],
    ["Greenland", "North America", 1873, 2025, "ehhfddfgdhffghgddgjmmkklhkgjikkjhggjjehhfhmknmmkmmno"],
    ["Greensboro, United States of America", "North America", 1850, 2025, "ehdgfdfdhiefggggeghfelghlgijijkkggggiifikkihmlmlkooo"],
    ["Grenada", "Caribbean", 1850, 2025, "cdbcbccbfccfdcdfdeddcbdfgdggeegeihfhffjihijlmlmmlnop"],
    ["Guadalajara, Mexico", "North America", 1878, 2025, "cbaaadgegdeeceehgigifjkhlihhiihfkjgikfilhmjmlljnkopr"],
    ["Guadalupe, Mexico", "North America", 1850, 2025, "hbehgihffeeaegfghjeffifihgihjljkgjhhjfhhgiklnjkkjjmo"],
    ["Guangzhou, China", "Asia", 1865, 2025, "fgedfbacebdefedehcedeefghhgjhhhijfgigifjiigmmmmjnorq"],
    ["Guankou, China", "Asia", 1871, 2025, "eecfccfcedgbecgdfffhehgjhjhgfgjkidggjhfhiikknnnloqrr"],
    ["Guarulhos, Brazil", "South America", 1851, 2025, "ihfdfjbcgdehdfhfedegeefheegffggdiehfijgijhkkkllknoop"],
    ["Guatemala", "Central America", 1890, 2025, "cdefdccecdcfdcfgffdfhhjgigiggghihgjjgjjkkoillkkloopr"],
    ["Guatemala City, Guatemala", "Central America", 1890, 2025, "cdffdccddecfcceiffcfhhigifjggfgighjjgjjkknimkkjlpoor"],
    ["Guayaquil, Ecuador", "South America", 1901, 2025, "gefdegeeeegfgeeeihhheifigefhihgfiimhkjliqgkkkmmopnkq"],
    ["Guilin, China", "Asia", 1865, 2025, "geddecbdgcdegdddhdffedegjiiihghjjggihifiihhlmmnjoqqr"],
    ["Guinea", "Africa", 1890, 2025, "cceffabcedbbffffeeeheffeeegegehfffiiijjjkmjnonolnonp"],
    ["Guinea Bissau", "Africa", 1890, 2025, "ccefgbcbdeccfgfcgeefegfdeeefgdggfgiihjkkkmknomnmmmpo"],
    ["Guiyang, China", "Asia", 1897, 2025, "gghefeejdggefceegilflikghiijigiiejigkiiiglmlnlhoqoqr"],
    ["Gujrānwāla, Pakistan", "Asia", 1875, 2025, "ggkfgeejkiggffhgjeiiggjlikhkhhhgikhhieijhignmkmlklln"],
    ["Gulf of Mexico", "Ocean", 1878, 2025, "ejhdedegdbfecfdhgheijhgkkjhhiggffjghkhhmjklllmklprqr"],
    ["Guli, China", "Asia", 1871, 2025, "gdbebbfbddebeefededfegihhiihfhjiifgghfegijlkppnlorrr"],
    ["Guntur, India", "Asia", 1875, 2025, "cgdabddihgggfgdhgggecfdhfhgfeheihfihkjlhhimklkkknolo"],
    ["Guwahati, India", "Asia", 1870, 2025, "dedfcdecfffcdecffgedffghggehgiighhigjhikgjjljmnlpqrr"],
    ["Guyana", "South America", 1887, 2025, "ddaeegcdceeacceffeeeieeegfggggeggeiihhhiknkmnlonqooq"],
    ["Gwalior, India", "Asia", 1875, 2025, "hhhdfgfjkjghfifhjehjdegkfjhjfghkihhilfljjigjlklhmmll"],
    ["Gwangju, South Korea", "Asia", 1870, 2025, "fdeedegdhgeeddeegfdffffggeihghjhhfhhihgjkjkklkljnlnq"],
    ["Hachiōji, Japan", "Asia", 1873, 2025, "ffgdbcgededbcfieffdgfdhgdhhgijjhhhggjgeiljkllklkmnpr"],
    ["Haikou, China", "Asia", 1865, 2025, "fggegdacebffgfeegdedefeghhgiihhhjffhhkgiikilmlkknnrp"],
    ["Haiphong, Vietnam", "Asia", 1882, 2025, "cafedffhffgfdefeeeedgghhhiihihkffigiigjmihlklkkkoopq"],
    ["Haiti", "Caribbean", 1864, 2025, "bedcgcbcdbefeccdecdegfdffgefgdihggfehijijjklnmmlompq"],
    ["Hamadān, Iran", "Middle East", 1882, 2025, "ihkhhfgifeegkiggggfghkhhehigiikggfgjfhjigkmmllnmoopq"],
    ["Hamamatsu, Japan", "Asia", 1863, 2025, "fefeegdcedfedecegeegdgefghefhiikghghhigikijmkllklnqq"],
    ["Hamburg, Germany", "Europe", 1850, 2025, "gchffhfgfggdeghfheihgfhggjgfikifighgijfjelkimlnjmnop"],
    ["Hamhŭng, North Korea", "Asia", 1872, 2025, "cfffdggeeifedcedgefgffigffhfghjfgegiihfjkkllmlljonnr"],
    ["Hamilton, Canada", "North America", 1850, 2025, "fheggcfdjiceghiheghgfjdgkghhiikihhghiigikkghnklllmno"],
    ["Handan, China", "Asia", 1891, 2025, "hddhgdfddidhhhigeehjhhieeeikgieghhgjeiiikolmmnjopqrr"],
    ["Hangzhou, China", "Asia", 1871, 2025, "gccecbecedecdefeeedgehhigiiiegjihffghffgijllopnmorrr"],
    ["Hannover, Germany", "Europe", 1850, 2025, "fchgfifgfggcefhgheihgghggjgfikifjfhgijgjelkhmlmklnoq"],
    ["Hanoi, Vietnam", "Asia", 1890, 2025, "hcffiegeffbfgceeedgfghhgighhgigfigjiejjihmkmmlikpqoq"],
    ["Hāora, India", "Asia", 1870, 2025, "ddedbdfcgfhdeededfefgeehgffjhlgiifhhjhikiijjllnjpnor"],
    ["Harare, Zimbabwe", "Africa", 1897, 2025, "fghgeegidgjghfgefdhghhfghiifijgfgggjjjnmijmkkmmmmolp"],
    ["Harbin, China", "Asia", 1872, 2025, "dhhgefheehgffddegdgfgghgifiefhhfhffigjgiklmjmmkjmnop"],
    ["Havana, Cuba", "Caribbean", 1850, 2025, "ebcebfdcdgeeedfdcddddggfffefihhghhgejhhjjkkkklkjloqq"],
    ["Hawaii", "Pacific", 1883, 2025, "dcedcdfcecbeeeeefgdeeigfcedfgggiefgjgkjjimimolklqpop"],
    ["Hawaii, United States of America", "North America", 1883, 2025, "dcedcdfcecbeeeeefgdeeigfcedfgggiefgjgkjjimimolklqpop"],
    ["Hefei, China", "Asia", 1871, 2025, "gfffdcfdeefcedgeffghfggjgihhdgjhiefgigegiklmnommnqrr"],
    ["Hegang, China", "Asia", 1871, 2025, "cfggffedegfgfdedfegeghffgfjffhgfhffhgjhjmlljmlkkmnop"],
    ["Helsinki, Finland", "Europe", 1829, 2025, "eighghighighfhjhiiihijhhihjkliikjgiigglfifljjlkmkmoo"],
    ["Henderson, United States of America", "North America", 1850, 2025, "ajefihhiieghgffggfeeeghggjiggfghjgghggjfjkjmkmmjnpno"],
    ["Hengyang, China", "Asia", 1865, 2025, "geeefdbefecffcddgeffgeghihjgffhkjgfhhighhhhllmojpqqr"],
    ["Hermosillo, Mexico", "North America", 1865, 2025, "gdfeidfheffghfgdgfefihijjiikjjkjgihfijeiihmlmllloqno"],
    ["Hiroshima, Japan", "Asia", 1863, 2025, "efedfeccfdffdecdfdffdgeeffffghikghhhhhhhkijmklmkkmoq"],
    ["Ho Chi Minh City, Vietnam", "Asia", 1896, 2025, "gfececgfaddbfdeehfiehgggfiggiighgiijklkiikmkmklnopnq"],
    ["Hobart, Australia", "Australasia", 1856, 2025, "dedcefdgeefdeeeceeeggfedfgccdeffiefijhlhkiihmlklmoln"],
    ["Hohenpiessenberg, Germany", "Europe", 1781, 2025, "edhggflbgfefcbdegggeeefdfhfgggfhfggkigghgighljlmlopq"],
    ["Hohhot, China", "Asia", 1891, 2025, "gfehhegdfgfjhhgfdcgihfideehihgehihgheikhjpmlmnkooopq"],
    ["Homs, Syria", "Middle East", 1859, 2025, "ffkhhikgfggffkfgefifhiihijhjgiiikgkfgifhhgkllklnnpqq"],
    ["Honchō, Japan", "Asia", 1873, 2025, "gfgdbcgfdeebcfieffdffdhgdhhgijihihggjgeiljklkkllnopr"],
    ["Honduras", "Central America", 1890, 2025, "ccefdeccddcfdegggfcfgghfigifghghhhjkhjikloikmjjlooor"],
    ["Hong Kong, China", "Asia", 1885, 2025, "accbcdgbdecgbeebeedfe--edfehhijghgiighhiikmmkkjkooqr"],
    ["Honolulu, United States of America", "North America", 1883, 2025, "cceecdfbeccedfefegdefhhfcfdfgggiefgjgkjjimjnomkmqppq"],
    ["Houston, United States of America", "North America", 1850, 2025, "gdekeffgggcegffffjggfkghkiigikjkfhigigghjjijnkmlkonq"],
    ["Huai'an, China", "Asia", 1871, 2025, "gffeddfdfffdecfegefgggfkhhihegkhiefhhhehiklmmomlnqrr"],
    ["Huaibei, China", "Asia", 1871, 2025, "gggfeefeefgdecgegfghgffkhihhegkhjefhiheihklmmolloqrr"],
    ["Huainan, China", "Asia", 1871, 2025, "gfgfddfeeegdecgeffghfgfkhihhdgkhiefhhhehiklmmomlnprr"],
    ["Huangshi, China", "Asia", 1871, 2025, "gfefccedddgbedgcffgieggjhjigegjiieggihfgijkmnpmmnrrr"],
    ["Hubli, India", "Asia", 1875, 2025, "cfbabecghfcececgegfecedgdffeegfijgghjiliiiljnkljoplq"],
    ["Huddersfield, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggghiihikhgjeggijfjelikmnnllnnr"],
    ["Hull, United Kingdom", "Europe", 1850, 2025, "gcgeghggefebefifgdhgeggghiigjjhgjegghjfieljkmnnllnor"],
    ["Hungary", "Europe", 1850, 2025, "gffhgjfggggdffhhhfhhhhhiekgfjkjfjgihiigjfjmhllmlpopq"],
    ["Hyderabad, India", "Asia", 1875, 2025, "cgcabeciigeffhdhghhgcgehegggfhekihghkjmhjhljljkkmokm"],
    ["Hyderabad, Pakistan", "Asia", 1875, 2025, "gfhehhgklkigehffggfhffgkfigjggighhghjfijiijmmlnknoop"],
    ["Ibadan, Nigeria", "Africa", 1886, 2025, "cbdgdfbcbbfgegggeffggfggfddffefhidiijjjijlklnnnlpooq"],
    ["Iceland", "Europe", 1850, 2025, "jhhhfcigeffefhfgfhhgegikmklllijklkffjifhjiijjommnnmm"],
    ["Ilorin, Nigeria", "Africa", 1886, 2025, "ecdgdgbbccfgehfgehfgggggfeegfefhieiijkihjlklommlonnq"],
    ["Incheon, South Korea", "Asia", 1871, 2025, "fefedfgchhfeddedfeefgffhhejhghjhhfhjhhgjkkkklllinmnq"],
    ["India", "Asia", 1875, 2025, "dfdacediihcedeefgefgcdfiehghggfiifhhjgliiijkmlnjopnp"],
    ["Indian Ocean", "Ocean", 1850, 2025, "eedeeeedfecdcedcbbcecddcefhgfegfffegghjijkjkllknnonq"],
    ["Indianapolis, United States of America", "North America", 1850, 2025, "fhdgfdgehidfghhgeghgflfglgihihjjghhgjifikkigmklkknmo"],
    ["Indonesia", "Asia", 1907, 2025, "aaccabcdeeeedffhefeggcggeefhggghiigkiijlmlnnloooqqor"],
    ["Indore, India", "Asia", 1875, 2025, "ggeadfejlifefighihehddfhehiigggkighijflijijkminimnml"],
    ["Innsbruck, Austria", "Europe", 1777, 2025, "gedjghfedghddecdcffdgddacfedfeggggfhhdgffifijlmmmoqq"],
    ["Ipoh, Malaysia", "Asia", 1869, 2025, "bcbccccbadcadbcebccefeffhgfffgggfihejiijjijlmnknoopp"],
    ["Ipswich, United Kingdom", "Europe", 1850, 2025, "gcgegifgeffbdfifgeigehgghihgikhgjegghjfjekkkmnnlloor"],
    ["Iran", "Middle East", 1882, 2025, "gfiggfghefdhigggggeegkghdhifhgifgfhjhgjigjnommompppr"],
    ["Iraq", "Middle East", 1878, 2025, "lgggfgeekfeffihgggiehgifhfiifkhhkffkhfijfkmmklnkpprq"],
    ["Ireland", "Europe", 1850, 2025, "ecgdggffddcdeehefeggegfeggigijgijffghjgjekilmnojlmnq"],
    ["Ironville, United States of America", "North America", 1850, 2025, "ghdfedfehjdghhhffghgfkfhlhihijkkfghgjhfikkihmkmkkono"],
    ["Irvine, United States of America", "North America", 1850, 2025, "cfcffgefhegggfggiefefehgfhihfefglfhifgklijlmijkinqmm"],
    ["Isfahan, Iran", "Middle East", 1888, 2025, "jgggfkdfeeigghihfdghkfidgffhihfiehkhhgjfklnnlkompqqr"],
    ["Islamabad, Pakistan", "Asia", 1875, 2025, "gfkegfehihfgefhfieiiggiljkhkhhighjhhifjkghhpmlmllmmn"],
    ["Islington, United Kingdom", "Europe", 1850, 2025, "fcgegifgeeebdfiffeigehgggihgikggjegghjfjekjkmnnlmoor"],
    ["Israel", "Middle East", 1861, 2025, "djifelgffiefjgefdhfghijijjfihihgjhhfgjehigklllmnpqqq"],
    ["İstanbul, Turkiye", "Middle East", 1850, 2025, "ejdgfeggicffffhieeeighhhfkhdifighjjighihghigmkmnooqq"],
    ["Italy", "Europe", 1850, 2025, "bbdfghfffgdbdeifedfffhgifiehikigihggggehijljmommoqpr"],
    ["İzmir, Turkiye", "Middle East", 1850, 2025, "djeiigigkcfggggifdfjhiiifkhgjfkiijiigfigihihmklmnnpq"],
    ["Iztapalapa, Mexico", "North America", 1878, 2025, "dcaaabeefddeceeffhhjffiilihejjhekjfijijijlkjlkkllnpq"],
    ["Jabalpur, India", "Asia", 1875, 2025, "efcbcdekjhdeegffhfgicdgifhghgggkifihkfjijijjmknilnlm"],
    ["Jaboatão dos Guararapes, Brazil", "South America", 1896, 2025, "cdeccececeebeeeegfgeffgeegeefghigggjijikkmlmmnknppor"],
    ["Jaboatão, Brazil", "South America", 1896, 2025, "cdeccececeebeeeegfgeffgeegeefghigggjijikkmlmmnknppor"],
    ["Jacksonville, United States of America", "North America", 1850, 2025, "hedgeffefieeffhdehgggjghkhghkliifggekhgijkjjlkkjkppo"],
    ["Jaipur, India", "Asia", 1875, 2025, "hhhdfgejlkihgiggjfgiefijfjijfghkjhhhlfkjiiglmklhmnll"],
    ["Jakarta, Indonesia", "Asia", 1866, 2025, "baabdbbcbaeccdcebbcedfefhgiggehefhgghhhijiklnomoprqq"],
    ["Jalandhar, India", "Asia", 1875, 2025, "hgkfgffjkiggffgfjeiiggikhlhkhhhghjhhjejjhkgmmlmklmmo"],
    ["Jamaica", "Caribbean", 1864, 2025, "afdbidbbeadfedcdecefgfdeegfdhdhggfggijjijkkkmmljnopq"],
    ["Jamshedpur, India", "Asia", 1875, 2025, "dgcbeeeihicffefegfhgdegiehijkhhjhfhhkijijjkkkknionmp"],
    ["Japan", "Asia", 1863, 2025, "feedgfdcecfddebdffffdgefgfeghhjjghgighghljjmkllllmpq"],
    ["Jeddah, Saudi Arabia", "Middle East", 1901, 2025, "icdhbeigfihkigjhjiigcijgjhgfgfgeiieilhelkmnmoqoqqqrr"],
    ["Jeonju, South Korea", "Asia", 1870, 2025, "fdfedegdhgeeddeeffdfgffggdihgikghfgihhgjkjlkllljnlnq"],
    ["Jersey City, United States of America", "North America", 1850, 2025, "ffcfgdfchheegghgefheejeikgghiikiggghiigjjlhimjmmlnoo"],
    ["Jersey, United Kingdom", "Europe", 1894, 2025, "egideeeigeegggffgifghijhfkkdghghkggjekjkkmmnnklmnopq"],
    ["Jerusalem, Israel", "Middle East", 1861, 2025, "djifflggfiefjhefdhfghijijjfigiigjhhfgjehigkmmlmnoqqq"],
    ["Jiamusi, China", "Asia", 1872, 2025, "cgggdffeegfffcdfgdgfgggehhiffhhfhffihjhjllmjllkklnop"],
    ["Jiangmen, China", "Asia", 1865, 2025, "fhedfcacfbdegedehdfdeefghhgihhhikffhgifiijhmnmmjnorq"],
    ["Jiaozuo, China", "Asia", 1891, 2025, "gedhgcfdeidgihigfehkiiiffejlgifgiigheihgkoklmnkppqrr"],
    ["Jieyang, China", "Asia", 1865, 2025, "dfedebabeddcededfbddffghghgijhiijggighfhiihnnlmknprq"],
    ["Jilin, China", "Asia", 1872, 2025, "dihgefheeigeeceegefffghggfhfegifheghgjgjklmjnlkimnoq"],
    ["Jinan, China", "Asia", 1889, 2025, "efffghdfcgeehfgggefjjgghgehkgiffghhifikhknmlmnjmqqqr"],
    ["Jinzhou, China", "Asia", 1889, 2025, "gdfgggedcecfgegfgffiieegeehkhheghhgkghmjlnkmlnikooor"],
    ["João Pessoa, Brazil", "South America", 1896, 2025, "cdeccececedbeddegfgeefgfegfffggifggiijikjnlnmolnpppr"],
    ["Jodhpur, India", "Asia", 1875, 2025, "ghhdhgfjlkiffhgfigghefijfjhjfgiikihhkfljiigkmjlhknll"],
    ["Johannesburg, South Africa", "Africa", 1881, 2025, "cececfdeeadffcdfffhffhgiigdhgihghgfhikjilimjnkkloojo"],
    ["Johor Bahru, Malaysia", "Asia", 1869, 2025, "bdbddccaaedbfbdfcdcefcefigfffggfghgfijhjiikmlmlnoopq"],
    ["Jordan", "Middle East", 1861, 2025, "eljfflggghffjhegdhghhiiiiifhhihgjhiggkfhifkllklnnqqq"],
    ["Jos, Nigeria", "Africa", 1888, 2025, "gceehgbceeifehehjihejggefdgegfhghggihliiilkmnnomonmp"],
    ["Juba, South Sudan", "Africa", 1901, 2025, "gceeeeccdeeghffegigdfffchdefegggikiglhikmjnolqooqnor"],
    ["Kabul, Afghanistan", "Asia", 1875, 2025, "igkfhhhgihegfhieighgheikjigjiiggfigjjikjfiiomklkmnnn"],
    ["Kaduna, Nigeria", "Africa", 1886, 2025, "efegehdcddhgcigigkhffiegeeegggfhifhihkhgjlkknmolnmmo"],
    ["Kagoshima, Japan", "Asia", 1870, 2025, "fcedbbfdffdecdffefcegfffeehhhiighggghhgilillmmlkmmor"],
    ["Kahrīz, Iran", "Middle East", 1882, 2025, "ihjggeghfeegjigggieghkhhehigiikgffgjfhijgknnlmmmooqq"],
    ["Kaifeng, China", "Asia", 1891, 2025, "gedhgcfeejdghiigeehliiifgeikgifggigieihgknkmmmkoprrr"],
    ["Kalyān, India", "Asia", 1875, 2025, "efdacedhigeddfegfgefccdhegfgfhfkiffjjfkhhilkmlokoonp"],
    ["Kampala, Uganda", "Africa", 1901, 2025, "kdfedabccecggeeefgffgfgeieefeegghkjilhkingmqnqnpqopr"],
    ["Kampung Baru Subang, Malaysia", "Asia", 1869, 2025, "acbccccbaedbebddbccefdeghgfffgggghgeiiijjikmmnlmpopq"],
    ["Kano, Nigeria", "Africa", 1896, 2025, "eiibcfdjgbghiikjeeiggfeeegehfhhihiiiliijkkilmommmmmo"],
    ["Kanpur, India", "Asia", 1875, 2025, "ggfcefejiiegegehjegicdgkfihjfhgmigiikfkjijhjllmhnnkm"],
    ["Kansas City, United States of America", "North America", 1850, 2025, "eheifcecihcfehfgfhhgfkfgkikhigikgihhijhhkkhhmkkjknln"],
    ["Kaohsiung, Taiwan", "Asia", 1865, 2025, "dffdebacececcdddebdceffgfgfhiiiijfgihighhjimmlmknpqq"],
    ["Karachi, Pakistan", "Asia", 1876, 2025, "gfdfghekkkhedfcfegehffihffhjghgghgfhifhkiiknnoomnopq"],
    ["Karaj, Iran", "Middle East", 1882, 2025, "hgighgfifeegjifgheeehlhhegifhijfhfgjghjifknoklmmpppr"],
    ["Kathmandu, Nepal", "Asia", 1875, 2025, "fgdbdfeggfcfdcedffegeegjfhhiiigigeigjhjjhkjklnpinnmr"],
    ["Kawasaki, Japan", "Asia", 1873, 2025, "gfgdbchfdeebceieffdgfdhgdhhgijjgihggjgeiljkllklkmopr"],
    ["Kayseri, Turkiye", "Middle East", 1850, 2025, "eigfijjjnfhhhggjffejihjifiigiehijjijgekhihgjljkmnnop"],
    ["Kazakhstan", "Asia", 1850, 2025, "eedadeefhecgedeffegieiiefeifgfgfejieghijgkfkklmjklnp"],
    ["Kerman, Iran", "Middle East", 1891, 2025, "ihigkeheglfggihgefgkhiggkfjfgghediiifkifimoommnmpppr"],
    ["Kermanshah, Iran", "Middle East", 1882, 2025, "ihjggeghfeegjigggieghkhhehigiikgffgjfhijgknnlmmmooqq"],
    ["Kharkiv, Ukraine", "Europe", 1850, 2025, "ghhefgffhfgfgehiieghfihfejidghhhiijhihhiekhilkmmmnop"],
    ["Khulna, Bangladesh", "Asia", 1870, 2025, "edeecdfcgfhdedcedfffgeehgffihkhihfhgjhjliiikllnjpopr"],
    ["Kiev, Ukraine", "Europe", 1850, 2025, "hfiegifggfgfggiiifgigiigekidhjhgihigiigjdkiilkmmmopq"],
    ["Kigali, Rwanda", "Africa", 1901, 2025, "ieecfcbcddeggefggiggghfdheeegefejkjjmgkjmglpnpmoqoor"],
    ["Kingston, Jamaica", "Caribbean", 1864, 2025, "bfdbidbceadfedcdecefffdefgfdgeggggggijiijkklmnljnnpq"],
    ["Kirkuk, Iraq", "Middle East", 1877, 2025, "kihggieejgeiehighghfihihgeiigjihiffkggihfkmmkkoloprq"],
    ["Kisangani, Democratic Republic of the Congo", "Africa", 1904, 2025, "cdaeebbedefeecgeifgfgecgeffdfiehkiikhikilknpmploqqqr"],
    ["Kitakyushu, Japan", "Asia", 1870, 2025, "edeebcfdffcdcdefefdffeegfehghijghgghihgikjllmmlkmmor"],
    ["Klang, Malaysia", "Asia", 1869, 2025, "acbccccbaecbdccecccefcefhfeffgggghgejiijjijllmkmoopp"],
    ["Kobe, Japan", "Asia", 1863, 2025, "eeeddedcedfedecdfeefcfeegfefhhijghghhhgijijmkmmklnoq"],
    ["Kolhāpur, India", "Asia", 1875, 2025, "cfcabecghgcedfcgegefcdchcfefehfijgfhjiliihljmkmjnpoq"],
    ["Kolkata, India", "Asia", 1870, 2025, "ddedbdfcgfhdeededfefgeehgffjhlgiifhhjhikiijjllnjpnor"],
    ["Köln, Germany", "Europe", 1850, 2025, "fcgfgiegeggbeehfgdihfgghfiffikhfjfhghkfjellimmmklooq"],
    ["Konya, Turkiye", "Middle East", 1857, 2025, "fgikihlhghhhgkhegglgjjigkigieijjljhhfkiigfjljklmnoop"],
    ["Kosovo", "Europe", 1850, 2025, "dheigigfhfedfghigfgiiiijfkfgjjlgihihghghhimhmllnpopr"],
    ["Kota Bharu, Malaysia", "Asia", 1869, 2025, "bcbcbccbbedbdbdebcbefdffhffgfggffigejjhkjiklmmknnopo"],
    ["Kota, India", "Asia", 1875, 2025, "hhgcfgfjkkhggiggjggidehjejijghgkihghlfljiihkmjmhlmkk"],
    ["Kotli, Pakistan", "Asia", 1875, 2025, "hfjfgfegigegefiejeijhghkjkgkhhhfhjhiifikhiiomkmkllmn"],
    ["Kraków, Poland", "Europe", 1850, 2025, "hefggieffggdfgiggehiggigfkgeikigigigiigjfklgmlmkmooq"],
    ["Kremsmunster, Austria", "Europe", 1768, 2025, "efgdhiighdgifgdededhffdfbdgfffgfggfgjggfhhhhjlklmoqp"],
    ["Kryvyi Rih, Ukraine", "Europe", 1850, 2025, "ihgefhfgifgfgfiijegigihfejidghigiijhihhidkihlkmmnnpp"],
    ["Kuala Lumpur, Malaysia", "Asia", 1869, 2025, "acbccccbaedbebddbccefdeghgfffgggghgeiiijjikmmnlmpopq"],
    ["Kumamoto, Japan", "Asia", 1870, 2025, "fdedbcfdffcecdefeedffefgfehghiighgghihgililkmmlkmmoq"],
    ["Kumasi, Ghana", "Africa", 1886, 2025, "cccedfacbafgegggeeeihfggffegfdfgieiijijiklklmmnmoooq"],
    ["Kunming, China", "Asia", 1890, 2025, "gceghdeededfgefcggkgikliliijihifieihgjifikklolnqnoqr"],
    ["Kuwait", "Middle East", 1893, 2025, "eeekedgehigihgigfgghghdjkfgkieiefikfijifkmmllmnmpqqq"],
    ["Kyoto, Japan", "Asia", 1863, 2025, "ffedefdcedfedecefeffdgefgfefhhikhhghhhgikiimkllklnpq"],
    ["Kyrgyzstan", "Asia", 1877, 2025, "ehedgefcfdcfgjgcfhdfbfkggdfgfghhghfjjhhihhlmmnmlmmoq"],
    ["La Paz, Bolivia", "South America", 1898, 2025, "dfdeccfeeffihiggijgeffieggeghjhefikhjiikilllmonoqomp"],
    ["La Plata, Argentina", "South America", 1856, 2025, "bccgcdfcdbdcgfgebeefdfggfggighdghgjhhhlijijlkkklmnnn"],
    ["Laayoune, Western Sahara", "Africa", 1884, 2025, "aebgegfccddedeefgecghfihgfifigggdefijiligmkmmlolompq"],
    ["Lagos, Nigeria", "Africa", 1886, 2025, "dbdfcfabbafgefggefffgfggfdefgefgieiijjjikkklnonlonoq"],
    ["Lahore, Pakistan", "Asia", 1875, 2025, "ggkfgfekkjhgffhgjeiiggjlilhkghhhijhhjeijiignnkmkklln"],
    ["Langfang, China", "Asia", 1891, 2025, "fdchfdeddfdhfggfefghifieedikhgegihfkfijjknlmmnimpoor"],
    ["Lanzhou, China", "Asia", 1916, 2025, "eeggggggidhjlfkjfhgeiiiiefhheggidgjkejipnomookqroprr"],
    ["Laos", "Asia", 1890, 2025, "ebgfgceeffaeececeegggihfhgihgihehgjjikkijnjkmjlnpppq"],
    ["Laredo, United States of America", "North America", 1850, 2025, "idfkhihfgefdfhgggkffgjhiihjikkkkfkigifgihjjjnjlmklmp"],
    ["Las Vegas, United States of America", "North America", 1850, 2025, "ajefiihiieghgffggfeeefhggjiggfghkgghggjfjkjmkmljopno"],
    ["Latvia", "Europe", 1850, 2025, "gfheggeegfgffhigheihgghggkhdhkhgihhfkigkemjilklkkmoo"],
    ["Laventille, Trinidad and Tobago", "Caribbean", 1850, 2025, "ddbcadcbfccfcdegddcdcbefgeghefgeihfhffihhijlmllmmnop"],
    ["Lebanon", "Middle East", 1861, 2025, "ekiggmggggfekhegdifghijiijgihihhjhhfgjfiiflllkmnoqqq"],
    ["Leeds, United Kingdom", "Europe", 1850, 2025, "fcgeghggeeecefiffehgeggfhiigikhgjegghjfjelikmnnllnnr"],
    ["Leicester, United Kingdom", "Europe", 1850, 2025, "gcgdgiggeeebdfiffdhgeggggiigikhgjeghhifjeljkmnollnnr"],
    ["Leipzig, Germany", "Europe", 1850, 2025, "fcgggjegfggdffhgheihgfhgfjffhkjeigigijgjellhmlmjlnop"],
    ["León de los Aldama, Mexico", "North America", 1871, 2025, "fdbbbaacfdgddebefhgihgiihkiiggkhejifikhjhmljklimhlmq"],
    ["Lesotho", "Africa", 1881, 2025, "bddfcfdedbdefdcegfgfghfiigdggighigfhijjikimjnklkonlp"],
    ["Lexington Fayette, United States of America", "North America", 1850, 2025, "ghdgfefeijdgghhffhghflfhkhiiiijkghggjhfjkkihmkmkknno"],
    ["Liaoyang, China", "Asia", 1868, 2025, "heihgefgffigeedeehfggefiheeffekggfhhihhhlklmllnhmnop"],
    ["Liberia", "Africa", 1890, 2025, "bbeeeacbdecceeggdegidgfefegefehghfiigkjjkokmnnoloonq"],
    ["Libreville, Gabon", "Africa", 1926, 2025, "eeddeggghfgggggceefgegggifdgjgkhmiijlmkkmmmomkmqoqoq"],
    ["Libya", "Africa", 1891, 2025, "gfghiddheiieghiihggificgeijegehfegighkjilmkmmnnqnqpr"],
    ["Liechtenstein", "Europe", 1850, 2025, "dcfhhiffefeacdhffdggfhgheiehikieiggfhigiglmjlmllnpor"],
    ["Lijiang, China", "Asia", 1875, 2025, "cgccdiefgebeecffgfffggegjikkhiighhifjghifkikkoooqprr"],
    ["Lilongwe, Malawi", "Africa", 1897, 2025, "fhgeeeegdijhfggdddgefgghhigdigffihfijklkkkmnmlonqokq"],
    ["Lincoln, United States of America", "North America", 1850, 2025, "fgegfcfcigceehggfghfgkfgjikiifhjgighijghkkhhmklikmkn"],
    ["Lisbon, Portugal", "Europe", 1850, 2025, "gbefffffeeccefjeeedeefggeeggilhghiggefhhikhokmknklmp"],
    ["Lithuania", "Europe", 1850, 2025, "gfhefgefgggeghigheihgghggkhehkhgihhfjigkemjilklklmoo"],
    ["Liverpool, United Kingdom", "Europe", 1850, 2025, "fcgdfhggeeecefiffehgeggghihgikhgjeggijfjdlikmnoklnnr"],
    ["Ljubljana, Slovenia", "Europe", 1850, 2025, "ddeghjfgfhgdefjggeghgihiejfgikjejfhghjfifkmimmmmpppr"],
    ["Logan City, Australia", "Australasia", 1858, 2025, "adehcegdeeedfgdeeidggefefgggefggdfghfiihkkkllmllnpoo"],
    ["Lomé, Togo", "Africa", 1886, 2025, "cccgcfacbafhfgghgeeggfghfdegfefgieiijkjijlklmmnlnonp"],
    ["London, United Kingdom", "Europe", 1850, 2025, "fcgegifgeeebdfiffeigehgggihgikggjegghjfjekjkmnnlmoor"],
    ["Long Beach, United States of America", "North America", 1850, 2025, "bfbefgefgeggggggjeeeeehgfiihfefglghifhkkijlmijlinqml"],
    ["Los Angeles, United States of America", "North America", 1850, 2025, "ahcehgfghegggfggieeeeehhgijgfefglghighjjijkmikmjoqnm"],
    ["Luancheng, China", "Asia", 1891, 2025, "gdchgdeedgdhghhgeehiggiddeikggegigfjeiiikollmnjnpqqr"],
    ["Lucknow, India", "Asia", 1875, 2025, "hgfdefejiicgefegifgicdgjfihjfhhmifiijfkiikhjllmhnnkn"],
    ["Ludhiāna, India", "Asia", 1875, 2025, "ifkfggekkifgffgfieiifgikhlhkhhhgiihhkekjhkglmlmjlmmn"],
    ["Luoyang, China", "Asia", 1891, 2025, "gedhhcedfidgihigffhlijifgejmhifhhiihfihgknklmmkppqrr"],
    ["Lusaka, Zambia", "Africa", 1897, 2025, "egheeegjehjihggeedihhihghiheiigfgfgkkkmljjllmkmnmplq"],
    ["Luton, United Kingdom", "Europe", 1850, 2025, "fcgegifgeeebdfiffeigehgggihgikggjegghjfjekjkmnnlloor"],
    ["Luxembourg", "Europe", 1850, 2025, "ebgfgiegefgbeehfgdhgfhghfiffikiejfhghjfjelljmmmlmoor"],
    ["Luxembourg, Luxembourg", "Europe", 1850, 2025, "ebgfgiegefgbeehfgdhgfhghfiffijiejfhghjfjelljmmmlmoor"],
    ["Lviv, Ukraine", "Europe", 1850, 2025, "hggggieggggfghihhfiihhigfkhehjigjgigijgjelkhlklkmooq"],
    ["Maceió, Brazil", "South America", 1911, 2025, "cddbeccfeedehfeeggffeegeeeghheggfjiiikmokmomnmmnoqqq"],
    ["Madagascar", "Africa", 1896, 2025, "gfedddeeadbfgfedgggeggggffichgdeiihhijkkmlomonmmoomr"],
    ["Madrid, Spain", "Europe", 1850, 2025, "fcggegghgfcbeejdffefegghghggilggijhgefihjlimklkmloor"],
    ["Madurai, India", "Asia", 1865, 2025, "dcaacbabcchgffcffcefgeegfehghdhehggggjklkikmmjlnnppo"],
    ["Maiduguri, Nigeria", "Africa", 1902, 2025, "eddcdjffggifkihgihhhfgefffefhgkgihkkikijljkmmpmoommn"],
    ["Málaga, Spain", "Europe", 1850, 2025, "fcggefeffdcceejeedeeeeggfffghkighihgdfhhjkinlllmlopr"],
    ["Malang, Indonesia", "Asia", 1900, 2025, "eccccccaedegeieiggfigfgfjgegifgggiigkhjimknnmolpqpor"],
    ["Malawi", "Africa", 1897, 2025, "fggeeeegdhihefgeddgefggggigdihffhhgijkmkkkmnmmooqolq"],
    ["Malaysia", "Asia", 1882, 2025, "cbdbaedccbceccdceffdfi-gegeggfgggggijhjkjkmmmlnmppoq"],
    ["Maldives", "Asia", 1875, 2025, "acaabbbeffcbbeecdeefcfgfffefffffgeffhikkimljnonoqqpr"],
    ["Male, Maldives", "Asia", 1875, 2025, "acaabbbeffccbeecdeefcfgfffffffffgfffhikkimmjmonoqqpr"],
    ["Mali", "Africa", 1903, 2025, "cccegebeeieeieggifgheegfggegifeejgkjikilmjmnkolkonpq"],
    ["Malta", "Europe", 1850, 2025, "ddcffggefidfegfgedffgfigiiegjihfihgfefegikkknonnooor"],
    ["Managua, Nicaragua", "Central America", 1911, 2025, "fdecfcehfigecfhdigfiejgfgggeigjiijlikljoiklkigkpmolq"],
    ["Manama, Bahrain", "Middle East", 1893, 2025, "geeieegdhggghhgeffgggidhigekhehefikeijhgknmmmmnoprrr"],
    ["Manaus, Brazil", "South America", 1910, 2025, "begcdadgegeegfheefdgehfggggegdgkhiigijjoimoomonqopmq"],
    ["Manchester, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggghiihikhgjeggijfjelikmnoklnnr"],
    ["Mandalay, Myanmar", "Asia", 1870, 2025, "ddgdccgdfggbfddffgfdhdffgidghhkhjhifkhgjhjkjklnlpnrq"],
    ["Manhattan, United States of America", "North America", 1850, 2025, "ffcfgdfchhefgghgdfheejeikgghiikiggghiigijlhimjmmlnoo"],
    ["Manzini, Eswatini", "Africa", 1881, 2025, "cddeeedfecefgceffegddhggghdhgifghgghiikilimknmlkomlp"],
    ["Maputo, Mozambique", "Africa", 1885, 2025, "cefcgdeedfggceefdgedeighghfihffkefighkjkjilmmmlkqnlo"],
    ["Mar del Plata, Argentina", "South America", 1856, 2025, "adcfcdebdbdcgdfddeefdeggfegiggdghfighhliijjlkkjlmono"],
    ["Maracaibo, Venezuela", "South America", 1913, 2025, "ffbdcdgeggeegkfeidicfighhfigfiiikggikijniolmmknqmqkq"],
    ["Maracay, Venezuela", "South America", 1886, 2025, "ceccfgecdddddcdgfgedghefffejihghiejijhghjminmknmqnmp"],
    ["Marrakesh, Morocco", "Africa", 1850, 2025, "idggfgghifcceeifeddeeegheghhjkihhjhhdfihjjhkmmlonnor"],
    ["Marseille, France", "Europe", 1850, 2025, "dbffghefegeadejffegeeggifiehilifihhgggfihkkllmmlnqpr"],
    ["Maseru, Lesotho", "Africa", 1881, 2025, "cfeecgeeebdffdcfgfighhgiihehgihhifehikjhkimjnklkonko"],
    ["Mashhad, Iran", "Middle East", 1878, 2025, "kgfhfggfhefehiiffgdeegkfhegifhhhggejiijigkmnlmmlnnoq"],
    ["Matola, Mozambique", "Africa", 1885, 2025, "deecgdeecfggdeffdgedeiggghfihffkffigikjljikmmmljqnlo"],
    ["Mauritania", "Africa", 1895, 2025, "ehefcdcecdghgehfggiiigeegghgfgfeeiiljkjillmmlmnmpkqq"],
    ["Mauritius", "Africa", 1887, 2025, "cbdeffcdddfbecededfggcfehgedfdehfgkigjjijkknmmqnormr"],
    ["Meads, United States of America", "North America", 1850, 2025, "ghdfedfehjdghhhffghgfkfhlhihijkkfghgjhfikkihmkmkkono"],
    ["Mecca, Saudi Arabia", "Middle East", 1901, 2025, "icehceigfjgkjgihiijgcijejigfgfieikeimheljmnmmqnqrqqr"],
    ["Medan, Indonesia", "Asia", 1869, 2025, "acbcbbcbbddbdbcdbddffdfghfghfgfffhgfiihkjijlmmknoopp"],
    ["Medellín, Colombia", "South America", 1908, 2025, "acggaeddgegdffjfghfggeigghgiefiiiihkikjjjmmmllmpoqkq"],
    ["Medina, Saudi Arabia", "Middle East", 1901, 2025, "kceideigfigiigihiiigckjeiighifjgjkegkhekjmmmlompqnrq"],
    ["Mediterranean Sea", "Ocean", 1871, 2025, "igihegdfeffcbccfdghhhhkfilhigfjhjgefehghhjjonnoqrrrr"],
    ["Meerut, India", "Asia", 1875, 2025, "igieggejjiehfgfgieiiddgkfjhjghhiihjhkfkiikgjllmimmln"],
    ["Meknès, Morocco", "Africa", 1850, 2025, "hdggghfhgfcceejefdeeefhgefhhjlihijhideihjjglmmlolonq"],
    ["Melbourne, Australia", "Australasia", 1856, 2025, "hfeefgefffhefheefeghhdfcfgeddfefiehgjilhiighmkmmopmo"],
    ["Memphis, United States of America", "North America", 1850, 2025, "fgdiddddghcffhhfeighflhhliiiihjkfghfjhghkjihmjmkjomo"],
    ["Mendoza, Argentina", "South America", 1855, 2025, "aebdcbegccdchfifdfgfefhfeeeigieejgiifhifikklhklmmlop"],
    ["Mercin, Turkiye", "Middle East", 1857, 2025, "dfhhfglgffffejfdfekeiiigjhgiehiikihhfjhhgfjlkkmnopqq"],
    ["Mérida, Mexico", "North America", 1875, 2025, "edefccceedeedcdffegdeffgjljiijigfiigiiiijmlklkkkmnnr"],
    ["Mesa, United States of America", "North America", 1850, 2025, "ajdghgfiiffiggeghfefefhgfjjhghfijgggggjgikimkmmlnpno"],
    ["Mexicali, Mexico", "North America", 1852, 2025, "ggdhkgcjgehgegggggdefeigihigegiijggfgglgijklkkmkoqno"],
    ["Mexico", "North America", 1870, 2025, "cdccaaabecfdeebedffhfhhggjjjijiifhheijgiimlllmjmnppr"],
    ["Mexico City, Mexico", "North America", 1878, 2025, "dcaaabeefddeceeffhhjffiilihejjhekjfijijijlkjlkkllnpq"],
    ["Miami, United States of America", "North America", 1850, 2025, "eccfcfeddgedfegceffdehhghgffijiggggdihhjjllkklkjlopq"],
    ["Middlesbrough, United Kingdom", "Europe", 1850, 2025, "gcgdghfgdeeceehefehgeggfhiigjkhgjfgghifieliklonlmnor"],
    ["Milan, Italy", "Europe", 1850, 2025, "dceffgeffeeaddiegeeeehghehfgilifihgfhhfhhkkkmommnqpr"],
    ["Milton Keynes, United Kingdom", "Europe", 1850, 2025, "fchegiggeeebdfiffehgehgggihgikggjegghifjekjkmnnllonq"],
    ["Milwaukee, United States of America", "North America", 1850, 2025, "gieffcgdjiceehggegggfkdglgjiihiigighihgikkignklkjmmn"],
    ["Minneapolis, United States of America", "North America", 1850, 2025, "gedfgcgcjhdeehfhfghgfjegkgiiihhiiifhhihikkhgmklkjmln"],
    ["Minsk, Belarus", "Europe", 1850, 2025, "gfheghefgggfghihheiighiggkhdhkhgihifjigkeljilkmllnpp"],
    ["Mississauga, Canada", "North America", 1850, 2025, "fgegfcfdjiceghiheghgfjdgkghhiilihhghiigikkghnjlllmno"],
    ["Moldova", "Europe", 1850, 2025, "hgffhiffgfhfggihhegigiigdjhdhiigjiihiigjekjglkmlnooq"],
    ["Monaco", "Europe", 1850, 2025, "cbdfggdedfdacdieeeedeggifhegjkifhhggggehiklkmnmmnqpr"],
    ["Mongolia", "Asia", 1882, 2025, "ggfgiegheffgeihgfcecfhfegfeegiidfhgiieikjlmmkojknooq"],
    ["Monrovia, Liberia", "Africa", 1890, 2025, "bbeeebcbddcceegfddgiegeefefffdgghfihgjjjkokmooolooop"],
    ["Montenegro", "Europe", 1850, 2025, "cgejhigfggeeeghhffghihhkfkehjjkgiiggggfijimhmmlnqpqr"],
    ["Monterrey, Mexico", "North America", 1850, 2025, "hbehgihffeeaegfghjeffifihgihjljkgjhhjfhhgiklnjkkjjmo"],
    ["Montevideo, Uruguay", "South America", 1856, 2025, "bddgddfdeaecgffebeefdfgggghifhdhhfihhhkijijklkkkmomn"],
    ["Montréal, Canada", "North America", 1850, 2025, "hgeffehdjhceegigefhgehdhjgghijlihhhhgiijijginjmnmmno"],
    ["Morādābād, India", "Asia", 1875, 2025, "iggeegeiiidhfffgiehiecfkgjhjhhhkihjhjgkjikgjkklimmlo"],
    ["Morelia, Mexico", "North America", 1878, 2025, "dbaaacgdgccdcdegfhhihiiikgieiihekifijgjkilkklmlmknor"],
    ["Morocco", "Africa", 1858, 2025, "feigghhecdcggfddcedffggdhghjihgiiigddhiikhiknmlnnnoq"],
    ["Moscow, Russia", "Asia", 1850, 2025, "fggcggefgggfgghgidhhghhggkidgjhghihfjhgjelhjkkmmlmop"],
    ["Mosul, Iraq", "Middle East", 1850, 2025, "dhgegigilfgigefiegfihhghfjhhheiiiihifhkfiifioklmnqpr"],
    ["Mozambique", "Africa", 1897, 2025, "fffcdeegdfhfeefcedgegggfhgidihefgheijjmkklmnmmmmoplq"],
    ["Mudanjiang, China", "Asia", 1872, 2025, "chhhdggddigfedeegefeffgfggiffhhehfghhjhjllmjmmkjmnop"],
    ["Multān, Pakistan", "Asia", 1875, 2025, "iglgkigklkihfiiijgiiggjmilhlhijhijghjejjhghnnklllmmo"],
    ["Mumbai, India", "Asia", 1875, 2025, "efdadedghheddfegfgefccdgegfgfhfkifejigjihilkmlokoonp"],
    ["Munich, Germany", "Europe", 1850, 2025, "ecfggjegeggbeehfgdghghgheiffikieifhghjgigkmimmllmpoq"],
    ["Muscat, Oman", "Middle East", 1893, 2025, "feeheegdhadgfggggceiggdhgfhgeeheglidehgiimopooplrqqr"],
    ["Muzaffarābād, Pakistan", "Asia", 1875, 2025, "gfjefgefhgefdfheiehiifhkijfjhhhfgjhijgikggiomlmlmmmo"],
    ["Myanmar", "Asia", 1870, 2025, "cbebbbeceffbdccdefedgeeffhehfhigighfkhhjhjkkkmnmqprr"],
    ["Mykolayiv, Ukraine", "Europe", 1850, 2025, "ihgefiffhegggghhiefhgihgdjhdghigiijhihiidkihlkmmnopq"],
    ["Mysore, India", "Asia", 1869, 2025, "abcdbbcdchhegcefdffgfcgdgefgefgfihhfiijmihllnjklnppo"],
    ["N'Djamena, Chad", "Africa", 1902, 2025, "edddfieffgjelihikhiifgefgfefiikgiikjikhkljkmmpmoommo"],
    ["Nagoya, Japan", "Asia", 1863, 2025, "feeeefdcedfeeecefeegdgefggefhiikghghhhhikijmkllkmnpq"],
    ["Nagpur, India", "Asia", 1875, 2025, "decacedkkieeegefhgghcdfhegghgggkigijjijijhjiljojlnjl"],
    ["Nanchang, China", "Asia", 1871, 2025, "febfbbdbddfaedgceffidgghhihfegjjiegfigegjilkoonmoqrr"],
    ["Nanchong, China", "Asia", 1905, 2025, "ceedidefgghehgikkglghhgkijjgikgkifehhgiimkmnnlnoqqrr"],
    ["Nanded, India", "Asia", 1875, 2025, "cfcacedkjfeeehehghhgcfeheghfggfkjhhijjmgigkikjmjmojl"],
    ["Nangandao, China", "Asia", 1891, 2025, "gddhgcfeejdhhiigfehkiiiefeilgifghhgieihgkokmmmkoprrr"],
    ["Nanjing, China", "Asia", 1871, 2025, "geeeccedeefdddgefefhfggjhihhegkhhefghgehiklmnpmmnqrr"],
    ["Nanning, China", "Asia", 1865, 2025, "hffdfdbegcefhfdegdffedefgghihhiijfgigjfjikhmmlljmoqq"],
    ["Nantong, China", "Asia", 1871, 2025, "gddecbecfeededfefeegghgjgiiifgkhhefghgfgjklmnpmmnqrr"],
    ["Naples, Italy", "Europe", 1850, 2025, "cddgggeefhedddhfedefghhigidhijkgjihgfgeijjmkmnlmoppr"],
    ["Nashik, India", "Asia", 1875, 2025, "egdbcedijgeeehehfgefcdcgdhggghgkiffjjgkhiiljmlojnono"],
    ["Nashville, United States of America", "North America", 1850, 2025, "fhchddfgijdgfgifeiggflgiliiiiikkfhhgjhgikkihmkmkkono"],
    ["Nassau, The Bahamas", "Caribbean", 1850, 2025, "fccdcedeefeceehdeeececiffgffgihfhgfeghhijlljkmlklopp"],
    ["Natal, Brazil", "South America", 1896, 2025, "ceeccebecedbfedegfgeefgggggfffghehgiijikkmlnmnmnppqr"],
    ["Naucalpan de Juárez, Mexico", "North America", 1878, 2025, "dcaaabeefddeceeffhhjffiilihejjhekjfijijijlkjlkkllnpq"],
    ["Nay Pyi Taw, Myanmar", "Asia", 1870, 2025, "cbfbcbecffgbeccefffehdeefidgfijgifhglihjijkkjlnlqprq"],
    ["Neijiang, China", "Asia", 1899, 2025, "gicedegdefggfeghimiligihikkiejkfjigehhgkjjmkqmkpqprr"],
    ["Nepal", "Asia", 1875, 2025, "ggfdegfhgfcgecfdgffhedgjfihihigigfihigjjhkilknojnnnq"],
    ["Netherlands", "Europe", 1850, 2025, "gchefifgefgcefhfgeihfggggjgfijhfjehghjfjellimmnjmnoq"],
    ["New Orleans, United States of America", "North America", 1850, 2025, "hddiefeffhefgegdfihfgkghkhhgkkjkfhhfkgghjjhjmkmkkpop"],
    ["New York City, United States of America", "North America", 1850, 2025, "ffcfgdfchheegghgefheejeikgghiikiggghiigjjlhimjmmlnoo"],
    ["New Zealand", "Australasia", 1853, 2025, "fgddeefegcdggedcehdhegfdggeegfijhggkjgjikkgkmjjkknno"],
    ["Newark, United States of America", "North America", 1850, 2025, "ffcfgdfchheegghgefheejeikgghiikiggghiigjjlhimjmmlnoo"],
    ["Newcastle upon Tyne, United Kingdom", "Europe", 1850, 2025, "fcgeghfgdeecefiefehgfggfhijgjkhgifggiigjeliklnnlmnnr"],
    ["Newcastle, Australia", "Australasia", 1858, 2025, "dgehddgffhdegedfeiegfeeeeifgdffgeeghhikfjjillmmnpqoq"],
    ["Newport, United Kingdom", "Europe", 1850, 2025, "fcgehhfgeeeceeiffeigehgggihgikggjegghjgkeljlmnnklnor"],
    ["Niamey, Niger", "Africa", 1904, 2025, "ceddifcdhgfhghhgkfggedegdgefjlegjikmhijkkjkmknlkmmmn"],
    ["Nicaragua", "Central America", 1908, 2025, "ccefcgedgeifecggeiegifigfheighijijgmhkmkljlmjjlonqmr"],
    ["Nicosia, Cyprus", "Middle East", 1857, 2025, "cehhfflgffgfeigdfdjeiihgjhhjehjikhghfjgghgjlmkmnnpqq"],
    ["Niger", "Africa", 1904, 2025, "ccdeggecfihjigegkegeefegdgffiiehkghkgiimlkmnkqmmonnq"],
    ["Nigeria", "Africa", 1886, 2025, "eecedhcbccggcgfhfjhfghfgeddgfefhjfhiikihjlkknmpmonnq"],
    ["Niigata, Japan", "Asia", 1873, 2025, "egfdccgecedccdiegfdgfdgfdgighjjhhhhhjgfiljjllklkmmor"],
    ["Ningbo, China", "Asia", 1871, 2025, "gccebbeceeeceeffeedffghighijghkihffghffgjjmmopmlnqrr"],
    ["North Atlantic Ocean", "Ocean", 1850, 2025, "hheeeffeifegeegecccecdfgjijiihjghggfdfihhjilnnoonopq"],
    ["North Korea", "Asia", 1872, 2025, "cggfdfgeehgeddedgeegffigffhffhjggegiiifjkkllmllinnoq"],
    ["North Macedonia", "Europe", 1850, 2025, "chcjghhfifeefghifggiijiifkfgjikgjiihghghiimhmlmnqpqq"],
    ["North Pacific Ocean", "Ocean", 1877, 2025, "hefdfdedebdacccdeggfghkihgieighhhfeiihijllkkmlklqqpr"],
    ["North York, Canada", "North America", 1850, 2025, "fhegfcfdjiceghihefhgejdgkgghiilihhghiigjkkghnjlllmno"],
    ["Northampton, United Kingdom", "Europe", 1850, 2025, "gchegiggeeebdfiffehgeggggihgikhgjeghhifjekkkmnollonr"],
    ["Northern Ireland, United Kingdom", "Europe", 1884, 2025, "gehggkfffeggfhehggkgiimijiikhfgghihfjcikilmmoojmlnoq"],
    ["Norway", "Europe", 1850, 2025, "gffggegfeehfghgegghefghhjljfikihjhffkifjfljiklnkmomo"],
    ["Norwich, United Kingdom", "Europe", 1850, 2025, "hcgefifgefebdfifgdigeghghihgjkhgjfhghifielkkmnnlloor"],
    ["Nottingham, United Kingdom", "Europe", 1850, 2025, "gcgdgiggeeecdfifgdhgeggggiigikhgjegghjfjeljkmnollnor"],
    ["Nouakchott, Mauritania", "Africa", 1891, 2025, "eeeeedcdddbfgggffgfhigefeefgfeigeiiiflkiklnkmkllnmpq"],
    ["Nova Iguaçu, Brazil", "South America", 1851, 2025, "jhfddkabgdehdefffeeedeehefgffgfejdifjihijikkkmklnoop"],
    ["Nowrangapur, India", "Asia", 1875, 2025, "afbaceejhgcedfffgfgfdgfhehgjhgfjifjhjjkhhimjkknknnmo"],
    ["Oakland, United States of America", "North America", 1850, 2025, "bddffefhjdhhffegheefdehgfijigefflggifgkjiijojlkimoom"],
    ["Odessa, Ukraine", "Europe", 1850, 2025, "hhfeghffhegffgihhefhgihgdjhdghifiijhhhhidkihlkmmnnpq"],
    ["Łódź, Poland", "Europe", 1850, 2025, "hdgggieggggefgighfiigghgfkhfikjgigigjjgkflkhlkmjloop"],
    ["Okayama, Japan", "Asia", 1863, 2025, "ffedffdcfdffdecdfeffdgeeffffhhjjghghhghhjiimklmkknoq"],
    ["Oklahoma City, United States of America", "North America", 1850, 2025, "fgdkeeedgfceegefehhgejggkijhifjkfiigiiigiihhmjllknko"],
    ["Omaha, United States of America", "North America", 1850, 2025, "ffdggcfdigceehfgeggggkfgkikiifhjgihhijghkkihmklikmkm"],
    ["Oman", "Middle East", 1893, 2025, "edegceedgccffggffdeighcgggggfdhegkicghjjioooonqmqrqr"],
    ["Onitsha, Nigeria", "Africa", 1886, 2025, "cbbedeaccbgfegdfdeggggggfdcgfefgidihiijijmkknoompoor"],
    ["Oran, Algeria", "Africa", 1850, 2025, "eegdfhfggfccegiggdffedghggfhijhfjkhgdeghikhmmmlomoqr"],
    ["Ordos, China", "Asia", 1891, 2025, "geehidfdfgeihggfdcgkggiefehiifehghghdikgipmmnnkqpoqr"],
    ["Orlando, United States of America", "North America", 1850, 2025, "hfcgdgeeeieeffgdehgfgjfhihggklihgghekhgijljjkkljlpqp"],
    ["Orūmīyeh, Iran", "Middle East", 1850, 2025, "fggegijjlghiifhifffiigigehiihfiijiiiehkfjiekokkmnooq"],
    ["Osaka, Japan", "Asia", 1863, 2025, "eeedefdcecfedecdfeefdgefggffhiijghghghhijijmkmlklnpq"],
    ["Osasco, Brazil", "South America", 1851, 2025, "igfdejbcgdehdfhfedegeefheehefggdieigiigjjhkkkllkmono"],
    ["Oslo, Norway", "Europe", 1838, 2025, "cfgefhfgffeegfgghghgihggghlkfikhhigggkifigmillnkmmoo"],
    ["Ottawa, Canada", "North America", 1850, 2025, "hgefgdgdjhceegigdfhgeidhkgghijliihhhhihjjkginjmnlmmo"],
    ["Ouagadougou, Burkina Faso", "Africa", 1902, 2025, "dacedgddfggehgejiggigeeghfegigifiimikjhlmjlmkmlmmnmo"],
    ["Oxford, United Kingdom", "Europe", 1850, 2025, "fchegiggeeebefiffeigehgggihgikggjeghhifjekjkmnnklonq"],
    ["Oyo, Nigeria", "Africa", 1886, 2025, "dbdgdfbbbcfgegggegfggfggfedffefhieiijkjijlklnnmlonnq"],
    ["Pakistan", "Asia", 1875, 2025, "hfjehhgijighehhfifhhgfilhjgjghhghigijfijhiioolmlmnnp"],
    ["Palau", "Pacific", 1922, 2025, "ccedeceeeee-geegedeegeggiigiggigklkijllkkmnmmoqrrqor"],
    ["Palembang, Indonesia", "Asia", 1866, 2025, "bbabccbcbbedcdbebccddfdehghffdgeghgfhiijjjklmnmnoopq"],
    ["Palermo, Italy", "Europe", 1850, 2025, "cddefghfghdfefhfcdgffgihiieiijigiiggffehjjljnommnmnq"],
    ["Palestine", "Middle East", 1861, 2025, "djifflggfiefjhffdhfghijijjfihiigjhhfgjehigkmmlmnoqqq"],
    ["Panama", "Central America", 1908, 2025, "acggbfedggieeejefgfhgdjgfgegfgiiijikikklklmllkmqoqlq"],
    ["Panamá, Panama", "Central America", 1908, 2025, "acggafeeggieeejfegfhgcjggheffgiiijikilkmkkmllknqoqlq"],
    ["Panshan, China", "Asia", 1887, 2025, "fgeeifegdceegeggffgihicgefejigifhhhhifljlmklloiknoor"],
    ["Papua New Guinea", "Australasia", 1903, 2025, "bccddecccedceffefeehgfggegefhfhfiijjkjimmlmlmomlqoqq"],
    ["Paraguay", "South America", 1877, 2025, "kddcdcfdhffcdicedhgfggfgghheghgiihgkjhjhikjlkkklmmlp"],
    ["Paramaribo, Suriname", "South America", 1887, 2025, "ccbddfcdddfbdcefeeffieeehgggggehfeijhihjjmkmnmonoonq"],
    ["Paris, France", "Europe", 1850, 2025, "ecgfgifgeffbeeifgehgehghfifgikhgjfhghjfjekkkmnmlmopr"],
    ["Pasragad Branch, Iran", "Middle East", 1882, 2025, "ihkhgegifeegkiggggfghkhhehigiikggfgjfhjigknmllnmoopq"],
    ["Patna, India", "Asia", 1875, 2025, "egecdfdgghcfededfefhddgieghjkihkhfjgjfjijkkjklnimmko"],
    ["Perth, Australia", "Australasia", 1880, 2025, "gcfgdggeegdfifieeeggggeghfefhlfffijjhjihikljjkmpmlnq"],
    ["Peru", "South America", 1901, 2025, "fcdaceeedegfefdeihgfdgfehffghfgehikgkikkoilmlomnqonq"],
    ["Peshawar, Pakistan", "Asia", 1875, 2025, "gfjdgffgihefeghgjeiigfikijgkhhhfgkghigjkgghpnkmkknmn"],
    ["Petaling Jaya, Malaysia", "Asia", 1869, 2025, "acbccccbaedbebddbccefdeghgfffgggghgeiiijjikmmnlmpopq"],
    ["Peterborough, United Kingdom", "Europe", 1850, 2025, "gcgegiggeeebdfifgdhgeggggihgikhgjegghjfielkkmnnllnnr"],
    ["Philadelphia, United States of America", "North America", 1850, 2025, "fgdfgdgchheegghgefhfejeikghiiikihgfhiigijkhimkmmknoo"],
    ["Philippines", "Asia", 1883, 2025, "abecaedbcbdecccdggegfffgdgfggefheggiiilkjjmlmmmnoooq"],
    ["Phnom Penh, Cambodia", "Asia", 1891, 2025, "ccgfecedegadcdceeggkfggggfjgggigghiihmkiilknkjnmoomp"],
    ["Phoenix, United States of America", "North America", 1850, 2025, "ajdghgfiiefiggeghfefefhgfjjhghgikgfgggjgikimkmmlnpno"],
    ["Pietermaritzburg, South Africa", "Africa", 1881, 2025, "cddgcdcedccefcdegfgefhfhggdggigggghhiijimhokmlkkollo"],
    ["Pikine, Senegal", "Africa", 1891, 2025, "ecgefccccfbfegeddghgggfeeefgfgigeiijgkiiklmkmlnlmjpq"],
    ["Pimpri, India", "Asia", 1875, 2025, "egdacedhigdddgdgfgeecdcgdgfgfifkjggjjhlhihljmknjnomo"],
    ["Pingdingshan, China", "Asia", 1891, 2025, "gedhhcedejdgiijgfghlijhfgejlhiggiigifiggknklmmkopqrr"],
    ["Pittsburgh, United States of America", "North America", 1850, 2025, "fgdgfdfdijefggigefhgfkehlgihijkjgghhjhfjklihmklkknoo"],
    ["Plano, United States of America", "North America", 1850, 2025, "ffekfeeeggcefgffejhgekhgjijhigkkfiigihhhjihinimlknlp"],
    ["Plymouth, United Kingdom", "Europe", 1850, 2025, "gcgeghffdedbediefehgehggfhhfhkggjegghjgkeljlmnmklnor"],
    ["Podgorica, Montenegro", "Europe", 1850, 2025, "dgejhigeggeeffhhgffiijhjfjehkjlgiiggggfhjilimmknppqr"],
    ["Pohang, South Korea", "Asia", 1870, 2025, "feffdegdggeecdeeefdggffghdhhgikggghijhgjljllllkjnmnr"],
    ["Poland", "Europe", 1850, 2025, "hdggfieggggefgigheiihghgfkhfhkigigigjjgkflkhllmkloop"],
    ["Poole, United Kingdom", "Europe", 1850, 2025, "gcgeghfgeeebdeiffeigehgggihghkggjegghifjelkkmnnkmoor"],
    ["Port au Prince, Haiti", "Caribbean", 1864, 2025, "bedcgcbcebffedccebdegfdffgeggdihhhfegijiiillmnllompq"],
    ["Port Elizabeth, South Africa", "Africa", 1881, 2025, "cdcfceefcbadededffighhgigeddhighgghhhkkjkhmkmklinnnp"],
    ["Port Harcourt, Nigeria", "Africa", 1886, 2025, "ccbedeacbbhfdfdfddgggfggfddffeggieiiiijikmklnoomqoor"],
    ["Port Louis, Mauritius", "Africa", 1887, 2025, "cbdeffcdddfbecfdfdffgcfehgedfdehfgkigjjijkknlmqnormr"],
    ["Port Moresby, Papua New Guinea", "Australasia", 1903, 2025, "ceefefdcdefddggfgfehggihfggfheigiiljkiikkllkmmlkqnop"],
    ["Port Said, Egypt", "Middle East", 1861, 2025, "chhedifdffffifddcgeggiijiigighihihgggiehhhjlmlnpqqrq"],
    ["Portland, United States of America", "North America", 1850, 2025, "effdfgefgcgheeffifefffjfgijihdhejgjhggihijkkkmjilnlm"],
    ["Porto Alegre, Brazil", "South America", 1876, 2025, "jfecedcehffcchbfdifhgfggfggggifihhgihikgjjimmmjkmolo"],
    ["Portsmouth, United Kingdom", "Europe", 1850, 2025, "gcgehhfgeeebefiffeigehgggihgikggjeghhjfkeljkmnnkloor"],
    ["Portugal", "Europe", 1850, 2025, "gbfghgggffbbefjefedeefggeeggilgggihgegihjlhnklkmkmmq"],
    ["Poznań, Poland", "Europe", 1850, 2025, "gcgggieggggefghghfihgghgfkhfhkifigifiigkellhmlmjlnop"],
    ["Prague, Czechia", "Europe", 1850, 2025, "gcfggjegffgdeehghfhhggghfkfeikjeigigijgjfklhmlmkmooq"],
    ["Praia, Cabo Verde", "Africa", 1894, 2025, "cfgeccddfcfdfgeefkgehgfffffhghgeejjigkjimklklkompmpq"],
    ["Preston, United Kingdom", "Europe", 1850, 2025, "fcgdfhggdeecefiffehgeggghiigikhgjeggijfjelikmnnklnor"],
    ["Pretoria, South Africa", "Africa", 1881, 2025, "cecdcgdeeadffcefgfhgfhgiihdhgiighgfhikjilimjnkkkoojo"],
    ["Pristina, Kosovo", "Europe", 1850, 2025, "ehdifigfhffdfghigggihiijfkfgjjlgihihghghhimhmmmnpopr"],
    ["Puebla, Mexico", "North America", 1878, 2025, "dcaaabedfcdfcdeefggiffihkhheijhfjifijgiijmkilkkllnpr"],
    ["Puente Alto, Chile", "South America", 1861, 2025, "acbabjfaedbfhgfeffgbhfhdefifgfgigfhefiiijjkmkmllnoqp"],
    ["Puerto Rico", "Caribbean", 1887, 2025, "cdcedfcdcedcebegfecdieedgfhihgdgfehkiiiikmjnmmmmpnor"],
    ["Puerto Rico, United States of America", "North America", 1887, 2025, "cdcedfcdcedcebegfecdieedgfhihgdgfehkiiiikmjnmmmmpnor"],
    ["Pune, India", "Asia", 1875, 2025, "egdacedhigdddgdgfgeecdcgdgfgfifkjggjjhlhihljmknjnomo"],
    ["Puyang Chengguanzhen, China", "Asia", 1891, 2025, "gedhgdfeejdhghigeehkhiiefejkgiffihgjeiigknkmmmjoprrr"],
    ["Puyang, China", "Asia", 1871, 2025, "gdbebbecedebeefedeefeghihiihfhjiifgfhfegijllppnloqrr"],
    ["Pyongyang, North Korea", "Asia", 1870, 2025, "gegfefgdhigeedfdgeefgffhgdhfghjggehihifjkklkmlkiomnq"],
    ["Qatar", "Middle East", 1893, 2025, "geeidegdggfgighgfgghghchigeihdhffikdiiggjoonmmpnqrrr"],
    ["Qingdao, China", "Asia", 1869, 2025, "gefeedfgfgffeedgegegfggjihghhekghegfjgggkkknlnnjoqrr"],
    ["Qinhuangdao, China", "Asia", 1889, 2025, "fdegggeecfcfgegfggfiiffgffhjhgegghgkghmjknlmmnilpppr"],
    ["Qiqihar, China", "Asia", 1850, 2025, "aggcghdggggeefihgfdefdffhghhfieehiefghhigkkmkmmijmon"],
    ["Qom, Iran", "Middle East", 1882, 2025, "hgjgggfhffehjigghfefhmhhegifhhkfhfgjhgjifkmollnmoopq"],
    ["Québec, Canada", "North America", 1850, 2025, "ifefgdhcifcdefhgdeggehehjgghijlhihhihhijhiginilnmlmo"],
    ["Quetta, Pakistan", "Asia", 1876, 2025, "ekigiihkkihhgkgihgigggkgjeikhhhijhehifijhikooklkmmnp"],
    ["Quilmes, Argentina", "South America", 1856, 2025, "bddgccfcdbdcgfffbeefdfhgfghigidghgjhhhlijijlkkklnnnn"],
    ["Quito, Ecuador", "South America", 1901, 2025, "edecegedeefehdeeiighegfghfgggggeijkhljkjogmmknmpqqmq"],
    ["Rabat, Morocco", "Africa", 1850, 2025, "hdegfgfgfdbceeifededeeggdfhgijhhijggcehhikhnlmlpmonr"],
    ["Raipur, India", "Asia", 1875, 2025, "cebadeekiideegfehfghdfgifigjhgfkifiijikijikjkjnjnnjl"],
    ["Rājkot, India", "Asia", 1875, 2025, "ggfcfggikiheegfgggeifegjejghgghkifhjhelijijlmkmjoonn"],
    ["Rājshāhi, Bangladesh", "Asia", 1870, 2025, "dfffcdgdgfgdedcedgefgeeigffihkhiifghkgjmiiikjmnjonoq"],
    ["Raleigh, United States of America", "North America", 1850, 2025, "fgdfgdfdghdegghgefhgekgglgiiijkjggfgjigikkjhlkmlkopo"],
    ["Ranchi, India", "Asia", 1875, 2025, "egdbefeihicgfefehfhheegiehiklihkgfhgjhjjkkkkjknjnnln"],
    ["Rasht, Iran", "Middle East", 1881, 2025, "egggieggeegeiichhdefijheggighkifhegiigijeknnllnooqqr"],
    ["Rawalpindi, Pakistan", "Asia", 1875, 2025, "gfkegfehihfgefhfieiiggiljkhkhhighjhhifjkghhpmlmllmmn"],
    ["Reading, United Kingdom", "Europe", 1850, 2025, "gcgegiggeeebefiffeigehgggihgikggjegghjfjeljkmnnlloor"],
    ["Recife, Brazil", "South America", 1896, 2025, "cdeccdceceebedeegfgeffgeegeefgghfggjijilknlnmnlmqpor"],
    ["Reykjavík, Iceland", "Europe", 1850, 2025, "jgggechgefeeghfgfhhgdgilmjlllijklkhgjiffjihjjomnnmmm"],
    ["Ribeirão Preto, Brazil", "South America", 1851, 2025, "ijfdfjdcgdehefhgeeegdefhffhffggdhfgghhhijijkkmmmnoqp"],
    ["Riga, Latvia", "Europe", 1850, 2025, "gfheggefgggefhigheihggiggkhdhkhgihhfkigkemjilklkkmoo"],
    ["Rio de Janeiro, Brazil", "South America", 1851, 2025, "jhfddkabgcehdeffeeefdeegefgffggejdifjhhijikkkmklnoop"],
    ["Riverside, United States of America", "North America", 1850, 2025, "ahcfghfghegggffgieeeeehggijheefglghiggkiijkmikmioqnm"],
    ["Riyadh, Saudi Arabia", "Middle East", 1920, 2025, "giigiieggghgijdiiiefgjghjfiehkhegkgeijkommlmqmmpqprq"],
    ["Romania", "Europe", 1850, 2025, "gheggigghegefghhgfghhiiiekgeijjejhihiigifkkgllmmoopq"],
    ["Rome, Italy", "Europe", 1850, 2025, "bcdfghffehdcedhfedeffhhifidiijjgiiggffehjiljmnmmoppr"],
    ["Rosario, Argentina", "South America", 1856, 2025, "bdeicbgdebdbhfeedgggdfhfgggkgicgigjighkhjijlkkkknmmo"],
    ["Rotherham, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefifgehgeggghiihikhgjegghjfjelikmnnllnor"],
    ["Rotterdam, Netherlands", "Europe", 1850, 2025, "gcgefifgffgbefhfgeihfggggjgfijhgjehgijfjdllimmnkmoor"],
    ["Russia", "Asia", 1869, 2025, "eefgfceegghfhgefgiihfiijhhjghfhigehhfiihmimimlomoppq"],
    ["Rwanda", "Africa", 1901, 2025, "ieecfcbcdddhgeffgiffggfdheedgefejkjjmhkjmglpnpmoqpor"],
    ["Sacramento, United States of America", "North America", 1850, 2025, "bfedgffhjdgieffghgeedehfhjkhgfgflfgighkhiijnjmmjoooo"],
    ["Safotulafai, Samoa", "Pacific", 1890, 2025, "bbaffccadgaeddfedfggffgegehggcgfhgjjijkkkkkmmlmnqqpr"],
    ["Saint Kitts and Nevis", "Caribbean", 1864, 2025, "bddbecbcddcdfdcddcdcfgdfegedheihgegfgjhiijklnmmmnnoq"],
    ["Saint Lucia", "Caribbean", 1855, 2025, "cbbccdcddcdebdfdececceehdeidfffghgggfgjhjiknkmlnmnop"],
    ["Saint Paul, United States of America", "North America", 1850, 2025, "gedfgcgcjhceehghfghgfkegkgiiihhiiifhhihikjhgnklkjmln"],
    ["Saint Vincent and the Grenadines", "Caribbean", 1855, 2025, "cbbbcccddcdebdfdecdcceegdeiefffghgggfgjhjikmkmlmmnop"],
    ["Saitama, Japan", "Asia", 1873, 2025, "gggdccgedeebceiefgdgfdhgdhhgijjhihggjgfiljkllklkmnpr"],
    ["Sakai, Japan", "Asia", 1863, 2025, "eeedefdcecfedecdfeffdgeffgefhijjghghhhgijijmkmmklnpq"],
    ["Sale, Morocco", "Africa", 1850, 2025, "hdegfgfgfdbceeifededeeggdfhgijhhijggcehhikhnlmlpmonr"],
    ["Salem, India", "Asia", 1865, 2025, "dcabecbbecihegdgfdgggfeggeghicieihgggikmjijlnjklopoo"],
    ["Salta, Argentina", "South America", 1871, 2025, "adgdcbdbgeiffcgffcgffeggfihhdfghiihhhijjhikimkkmmmmq"],
    ["Saltillo, Mexico", "North America", 1850, 2025, "gbchfigeeddadfeggidefjgihghhilkkgjhhifhgfikknkkkiino"],
    ["Salvador, Brazil", "South America", 1911, 2025, "eecaceegefdeggeegeggegifffegjgghgjkiijmokmokomnpoqoq"],
    ["Samoa", "Pacific", 1890, 2025, "bbaffccadfadddfddgggefgegehggcgghgiiijjkkkkmmmonqqpr"],
    ["San Antonio, United States of America", "North America", 1850, 2025, "hcfkgigggeedghgffkgggjgijiihijjkfjhfiggiikijmjmmlnmq"],
    ["San Diego, United States of America", "North America", 1850, 2025, "cfcffgdfhegfgfggifefffhgfhjhfefglghifgkkijlnikkinqml"],
    ["San Francisco, United States of America", "North America", 1850, 2025, "bddffefhjdhhffegheefdehgfijigefflggifgkjiijojlkimoom"],
    ["San José, Costa Rica", "Central America", 1908, 2025, "bdegcgeegfkfeehfghehgejgegegggiihjilillkkmmlkilonplq"],
    ["San Jose, United States of America", "North America", 1850, 2025, "cgeffghijehhffeghfefdehggjjigfgflfhiggjhjijojmkjnpon"],
    ["San Juan, United States of America", "North America", 1887, 2025, "cdcedfddcedbebfgfeddieedgfgihgeggehjiiijkljnmmmmpmor"],
    ["San Luis Potosí, Mexico", "North America", 1871, 2025, "gecdcaabedihffcffghihfijhkkjghkidijgijghhlmllljmhmlq"],
    ["San Marino", "Europe", 1850, 2025, "cbcfgjggfgeceeigfeggghgifidhijifihhfggegijmjonlloopr"],
    ["San Miguel de Tucumán, Argentina", "South America", 1870, 2025, "acfddcdbgeieedhggbgeefhegihhdfhgikghihikhjkiljlnmlmp"],
    ["San Salvador, El Salvador", "Central America", 1911, 2025, "gcfdfccgfggecegekggieigfhggfigjjiikikmkoillkjikpnqmr"],
    ["Sanaa, Yemen", "Middle East", 1886, 2025, "cceeffdeededfegihggehjigfheggdffiehkhgijlmqnnlnmqqpr"],
    ["Sāngli, India", "Asia", 1875, 2025, "cfdacfchigeedgcgegefcedhdgeeegfjjgghjhliiglinklioomp"],
    ["Santa Ana, United States of America", "North America", 1850, 2025, "cfcffgefhegggfggiefefehgfhihfefglfhifgklijlmijkinqmm"],
    ["Santa Cruz de la Sierra, Bolivia", "South America", 1898, 2025, "ciefdcgkccdgfgegghcjfhhdcfhdhkhghhhikjinkjmkklommmmp"],
    ["Santa María Chimalhuacán, Mexico", "North America", 1878, 2025, "dcaaabeegddecdeffghiffiiligejjhekifikhjiklkjlkkllnpq"],
    ["Santiago de Cuba, Cuba", "Caribbean", 1864, 2025, "bfcdgdbbebefddcdebdggfdefggfgdiggfgghhjilklklllkonqq"],
    ["Santiago de los Caballeros, Dominican Republic", "Caribbean", 1864, 2025, "bedcgcbcdbeeedcceccegfdefgffgdihgfgfijiijjklnnllomoq"],
    ["Santiago de Querétaro, Mexico", "North America", 1873, 2025, "dbdababdfdfddedegggihfijijihfiifhjifjjhjimmjkljmjmnq"],
    ["Santiago, Chile", "South America", 1861, 2025, "acbabjfaddbfhgfdfegbhfhdefifgefihfhefiiijjkmknllnopp"],
    ["Santo André, Brazil", "South America", 1851, 2025, "igfdejbcgdehdfhfedegeefheehefggdieigiihijhkkklkkmono"],
    ["Santo Domingo Este, Dominican Republic", "Caribbean", 1887, 2025, "cdbeefcdccdbebfgfddeieeegfgiffggfeikihiijlknommnomor"],
    ["Santo Domingo Oeste, Dominican Republic", "Caribbean", 1887, 2025, "ccbeefcdcdebebfgfddeieeefegiffggfeikihiijlkmnmmnomor"],
    ["Santo Domingo, Dominican Republic", "Caribbean", 1887, 2025, "ccbeefcdcdebebfgfddeieeefegiffggfeikihiijlkmnmmnomor"],
    ["São Bernardo do Campo, Brazil", "South America", 1851, 2025, "igfdejbcgdehdfhfedegeefheehefggdieigiihijhkkklkkmono"],
    ["São José dos Campos, Brazil", "South America", 1851, 2025, "ihfdejbbgdehdfhfedegeefheegefggdjehfiigiiilkkmllnoop"],
    ["São Luís, Brazil", "South America", 1896, 2025, "eeeddecgafcdefidgfighfihfifehhgeghihiikkkmlnnmnpqpor"],
    ["São Paulo, Brazil", "South America", 1851, 2025, "igfdejbcgdehdfhfedegeefheehefggdieigiihijhkkklkkmono"],
    ["São Tomé and Principe", "Africa", 1901, 2025, "eabcdeecfedfdefgffhfgfedeeffgfhdhiigmjilmkmmnqklqpop"],
    ["São Tomé, São Tomé and Principe", "Africa", 1901, 2025, "eabcdeecfedfdefgffhfgfedeeffgggdhiigmjilmkmmnqklqpop"],
    ["Sapporo, Japan", "Asia", 1872, 2025, "egfhbffdcdeecdeggffgeggeeijfhjjhifjghhfjmkijkkmkmmpr"],
    ["Sarajevo, Bosnia and Herzegovina", "Europe", 1850, 2025, "cfejgigfgifeegihgfghhhhkfkegjklfjhhgghgihjmhmmlnqopr"],
    ["Sargodha, Pakistan", "Asia", 1875, 2025, "gglfhgfjkjggfghhjeiihgjlikhkhiigijhhiejjhihnnklllmmn"],
    ["Saudi Arabia", "Middle East", 1893, 2025, "eegjdegdgffghgiggghhihcjigfjhehgfikdgjigkmnnlmomqqqr"],
    ["Scarborough, Canada", "North America", 1850, 2025, "fhegfcfdjiceghihefhgejdgkgghiilihhghiigjkkghnjlllmno"],
    ["Scotland, United Kingdom", "Europe", 1884, 2025, "ecgffifegfhgfhehfhmhjhkiiigkhfffijhejdikhklnookmmnpq"],
    ["Seattle, United States of America", "North America", 1850, 2025, "eeeeefeehdhhedfgheegffjfgikihdhejhjgggihijlljmkjlolm"],
    ["Semarang, Indonesia", "Asia", 1866, 2025, "ccabcbbcbaeccdccbcdeegegfgifffhefhfgghgjijklonnmpqqq"],
    ["Sendai, Japan", "Asia", 1873, 2025, "ghgeddhedffccdifhfehfdggdhigijjhhighjgfiljjlkklkmmor"],
    ["Senegal", "Africa", 1890, 2025, "cdefgcccdeadggfehfehghfedeffgdhgfgijhjjkkokmmlmlmmoo"],
    ["Seongnam si, South Korea", "Asia", 1870, 2025, "fdffdegdhhfeddeefeefhffhgdihghkhhfhihhgkkklklkkiomnq"],
    ["Seoul, South Korea", "Asia", 1870, 2025, "fegfeegdhhfeedeefeefhffhhdigghjhhfhiihgkkklklkkiomnq"],
    ["Serbia", "Europe", 1850, 2025, "eheigjgghggdfghhhfhhhihjekggjjkfjhihhigigjlhmlmmoopr"],
    ["Sevilla, Spain", "Europe", 1850, 2025, "gcghfgfggfccefkefdceefggegghhkhghihgefihikhnkllmknnq"],
    ["Seychelles", "Africa", 1894, 2025, "dfcecbadgbecdeeeffeggfggejieefeffhiigkiikmnmonpoqpor"],
    ["Shanghai, China", "Asia", 1871, 2025, "gdcebbeceeedeeffefegghhighijfgkhhffggffgjklmopmlorrr"],
    ["Shangyu, China", "Asia", 1871, 2025, "gcbebbebedeceeffeedgfhhigiiifhkhhffggffgjkllppmmoqrr"],
    ["Shantou, China", "Asia", 1865, 2025, "dfedfbabdddcddedfbccffghgggijhiijggihhghiihnnlmknprq"],
    ["Shaoguan, China", "Asia", 1865, 2025, "gfececacebcdedddgcedfdfhhhgihghjkggihigjjhglmlnjoprr"],
    ["Sharjah, United Arab Emirates", "Middle East", 1893, 2025, "geeheegdheegihggfffighegiigiechefkkdhhhgiooppnqorrrr"],
    ["Sheffield, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefifgehgeggghiihikhgjegghjfjelikmnnllnor"],
    ["Shenyang, China", "Asia", 1868, 2025, "gfjhgefgffjgeeceehfggffihfeffdjggehhhhhilkklllmhmnop"],
    ["Shenzhen, China", "Asia", 1865, 2025, "fhedfbabebddfdddhcedeffggggihhhikgghgifiijhmnmmknprq"],
    ["Shihezi, China", "Asia", 1879, 2025, "ifghdhfffegghgghigdfciiigfdgffjffhfhiggmhjnlkoklnlnp"],
    ["Shijiazhuang, China", "Asia", 1891, 2025, "gdchgeeedgdhgghgeegiggiddeikhgegigfjeiiikollmnjnppqr"],
    ["Shiliguri, India", "Asia", 1870, 2025, "deegcdfcgefcddcedfdegefihhejgihfggghigikijilloplpoor"],
    ["Shiraz, Iran", "Middle East", 1893, 2025, "gffjeeidjgfihiigfgghiheiifgigcieflkhhjkginomloomrqqr"],
    ["Shivaji Nagar, India", "Asia", 1875, 2025, "egdacedhigdddgdgfgeecdcgdgfgfifkjggjjhlhihljmknjnomo"],
    ["Shiyan, China", "Asia", 1905, 2025, "bedeidfggiiggggljijgeggkkgkggigkiheihghjoklmmkmnporr"],
    ["Shizuoka, Japan", "Asia", 1873, 2025, "eefdbcgeeedccfidfgcggdghdhhhhkjhhhghjgfjljklmklkmopr"],
    ["Shuangyashan, China", "Asia", 1872, 2025, "cgghdggedgfffcdfgdgfgggeggiffhhfgfgihjhjllljmlkkmnoo"],
    ["Sierra Leone", "Africa", 1890, 2025, "bbeeeabaddbcfegfddehegeeedfegehfgfiiiijjjoknooolooop"],
    ["Singapore", "Asia", 1869, 2025, "bdbddccaaedbfbefcdcefcefigfffggffhgfijhjiilmlmlnoopp"],
    ["Singapore, Singapore", "Asia", 1869, 2025, "bdbddccaaedbfbdfcdcefcefigfffggfghgfijhjiikmlmlnoopq"],
    ["Siping, China", "Asia", 1868, 2025, "gejhhefhfeihefceeheffffhhgfffdjhgehhhhhhlkllllnhmmop"],
    ["Skopje, North Macedonia", "Europe", 1850, 2025, "chcigigfhfeefghifggiijiifkfgjjkgiiihghgghimhmlmnppqq"],
    ["Slough, United Kingdom", "Europe", 1850, 2025, "fcgegiggeeebdfiffeigehgggihgikggjegghjfjekjkmnnlloor"],
    ["Slovakia", "Europe", 1850, 2025, "ffghgieffggdfghggehhhghhfkgfikjfjgihijgjfjlhllmloooq"],
    ["Slovenia", "Europe", 1850, 2025, "ddeghjfgfggdefiggegggihiejfgikjejghghjfigjmimmmmpppr"],
    ["Sofia, Bulgaria", "Europe", 1850, 2025, "didigiggiefdeghifegihiiifkgfihkgjiihghghhilhmlmnpppq"],
    ["Sokoto, Nigeria", "Africa", 1903, 2025, "cccdggecghihjhfgjhegeeeeeiegiihgiiilgihkkjknkomlmlmn"],
    ["Solāpur, India", "Asia", 1875, 2025, "dgdacecijgffehdhfgffcfeiegheehfkjhgijilhigljmjmjnnkn"],
    ["Sorocaba, Brazil", "South America", 1851, 2025, "ihfdfjbcgeehdfhfdcegeefheehefggdiehgiigijhkkklllnooo"],
    ["South Africa", "Africa", 1881, 2025, "aecebedecbceeddegfhgghgihgdghihghgfhhkjhlhnjnklkoolp"],
    ["South Atlantic Ocean", "Ocean", 1850, 2025, "dcdeededdedbbbaabbcddeddefgefefefffgihijkkjkkkkmkmno"],
    ["South Korea", "Asia", 1870, 2025, "feffdegdhheeddeefedfgffhgdihgijghfhiihgjlkkklkkjnmnq"],
    ["South Pacific Ocean", "Ocean", 1869, 2025, "ecghgdfddghdeacdcddefeegggfffggfeggfjkjjjkljmmkkmomo"],
    ["South Tangerang, Indonesia", "Asia", 1866, 2025, "baabcbbcbbedcdcebbcedgefhgiggehfgggghhhiihklmomopqqq"],
    ["Southampton, United Kingdom", "Europe", 1850, 2025, "gcheghfgeeebeeiffeigehgggihgikggjeghhjfkeljkmnnkloor"],
    ["Southend on Sea, United Kingdom", "Europe", 1850, 2025, "gcgeghfgeeebdfifgdigehgggihgikhgjegghifjekkkmnnlmoor"],
    ["Soweto, South Africa", "Africa", 1881, 2025, "cfdedgeeeadffcefgghfghgiihdigihgigfhikjilimjnkkmooko"],
    ["Spain", "Europe", 1850, 2025, "ebgfggfgffcaeejdfeeeegfhfgggilhgiihgefhhjlimklkmloor"],
    ["Sri Lanka", "Asia", 1865, 2025, "feabcbabdbffdecehdeefedfheffgdgfhgffgiijkilmmllnmopp"],
    ["St. Louis, United States of America", "North America", 1850, 2025, "egcgeefdhhdfehhhehggekfglhjiigjkgihgjighkkihmklkjnlo"],
    ["St. Petersburg, United States of America", "North America", 1850, 2025, "gedgegeeehegfehdeggffjfgihggjliigghejhgiklkjkkkjlpqq"],
    ["Staten Island, United States of America", "North America", 1850, 2025, "ffcfgdfchheegghgefheejeikgghiikiggghiigjjlhimjmmlnoo"],
    ["Stockholm, Sweden", "Europe", 1756, 2025, "fhghifiigeffiiefgfghgfgegfghghihfgkiijhhgiihflklmkno"],
    ["Stockport, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggghiihikhgjeggijfjelikmnoklnnr"],
    ["Stockton, United States of America", "North America", 1850, 2025, "bfeeggghjegieffghfeedehghjjigffflfhiggkhiijnjmminppo"],
    ["Stoke on Trent, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggghihhikhgjegghjfjeljlmnnklnor"],
    ["Stuttgart, Germany", "Europe", 1850, 2025, "ebggfiefefgbdehfgdhhfhgheiffikieifhfhjgifkmimmmkmooq"],
    ["Sudan", "Africa", 1901, 2025, "icfgdehgdggkhiiiliefcgggiegfifiihkhikigjkklolqmoqnmr"],
    ["Sulţānah, Saudi Arabia", "Middle East", 1901, 2025, "kceideigfigiigihiiigckjeiighifjgjkegkhekjmmmlompqnrq"],
    ["Sunderland, United Kingdom", "Europe", 1850, 2025, "gcgeghfgddecefhefehgeggfhiigjkhgifgghigielikmonlmnnr"],
    ["Surakarta, Indonesia", "Asia", 1866, 2025, "cdbbdbcdbbdcbcccccdeegegfgifgfifghgghihihjllnnmmppqp"],
    ["Sūrat, India", "Asia", 1875, 2025, "egebdfeijifeeffhghegddehdhhghghkhfgihekiijkkllnknnnp"],
    ["Suriname", "South America", 1887, 2025, "ccafegddcegbdcegfeffiefehfggghehfeijihhkkmimnlnnpomq"],
    ["Sutton, United Kingdom", "Europe", 1850, 2025, "fcgegifgeeebdfifgeigehgggihgikggjegghifjekkkmnnlmoor"],
    ["Suva, Fiji", "Pacific", 1910, 2025, "gdegdeeehcggieeefhghighggcegikgiiihligkkmnknkonmopqq"],
    ["Suwon si, South Korea", "Asia", 1870, 2025, "fdffdegdhhfeddeefeefhffhgdihghkhhfhihhgkkklklkkiomnq"],
    ["Suzhou, China", "Asia", 1871, 2025, "gdcebbeceeeceefeffegfhgjgiiiegkihffgggfgjjlmopmlorrr"],
    ["Svalbard, Norway", "Europe", 1898, 2025, "geghhgdceijhfkkkmjgiikjlkjeiegijighlgkjijlllpmooqoop"],
    ["Swansea, United Kingdom", "Europe", 1850, 2025, "fcgehifgdeeceeiefeigeggggihghjghjegghjfkeljkmnnklnor"],
    ["Sweden", "Europe", 1850, 2025, "gggfgfffffhfgigfhgighghiikjfikigiiffkifkemjjklmjmmno"],
    ["Swindon, United Kingdom", "Europe", 1850, 2025, "fcheghfgeeebefiffeigehgggihgikggjegghifjeljkmnnklonq"],
    ["Switzerland", "Europe", 1864, 2025, "fgdeededbedhdedfedhfifggegjkhdihfhgghfihlklmnlmmopor"],
    ["Sydney, Australia", "Australasia", 1858, 2025, "dfeheegffhdegfdfeidhgeeeeifgdefhefghgjkgkjiklmlmprnp"],
    ["Syria", "Middle East", 1857, 2025, "feijghligggfdjhefejfihigjhhieijikiggfkghhgjllklmnpqq"],
    ["Tabriz, Iran", "Middle East", 1850, 2025, "effdfhjimfhihfghfffihghgehjihfihiiiiehkfjiekolkmmooq"],
    ["Tai’an, China", "Asia", 1868, 2025, "gfhfedfffdifdfcgdggggeeijigfhdkgiffgjgfhjjjnlmmjorrr"],
    ["Taichung, Taiwan", "Asia", 1865, 2025, "eefdebacececccedgbdcdffhghgijiiijfgihigghjimnlmknqrq"],
    ["Ta’if, Saudi Arabia", "Middle East", 1902, 2025, "ecgecgegiihkihihkiigdkighifggdifihggjigmjnomlqnqrprr"],
    ["Tainan, Taiwan", "Asia", 1865, 2025, "efedebacecebccedebdcefegggfhiiihjfgihihghjimmmmknpqq"],
    ["Taipei, Taiwan", "Asia", 1871, 2025, "gddcabfbdddbeeeecdbcffgfgghjiiihgghihifiijllnmmkorqr"],
    ["Taiwan", "Asia", 1865, 2025, "eeeddbacececcdedgbdcdffgggghjiihjfgihihhijimmlmknprq"],
    ["Taiyuan, China", "Asia", 1891, 2025, "gdehhdfceidhighgeehighkeeeijggehgggieijgjqmmonkopqrr"],
    ["Taizhou, China", "Asia", 1871, 2025, "gdeeccfdfeededfefefgfhgjgiiiegkhhefhhgegiklmnpmlnqrr"],
    ["Ta‘izz, Yemen", "Middle East", 1886, 2025, "cdeeffdedeedecfiigfdijigffchhcfgkeikhfijknnnmkmmqrpr"],
    ["Tajikistan", "Asia", 1875, 2025, "ggheffefdedfehidffeeddhigffggghgfigjkhijfijmlmlkmmmq"],
    ["Takeo, Cambodia", "Asia", 1891, 2025, "ccgeecdcegadcdceegfjfggfgfiggghgghiihlkiilknkjmmoonq"],
    ["Tallinn, Estonia", "Europe", 1850, 2025, "gfgdffeeffgefhhfhfighghihljfikihhigfjigkemjjkkmklmoo"],
    ["Tampa, United States of America", "North America", 1850, 2025, "gedgdgfeeheggehdehgfgjghihggjliighhekhgijlkklkkilpqq"],
    ["Tangerang, Indonesia", "Asia", 1866, 2025, "baabdbbcbbedcdcebbcedgefhgiggeheghgghhhiiiklnomopqqq"],
    ["Tanggu, China", "Asia", 1891, 2025, "gdeigeeddgdhffgfefhiififfeikhgegihgjeikjknllmnjnpqpr"],
    ["Tangier, Morocco", "Africa", 1850, 2025, "hdfhffeeedbcdfieeddedfggeffghkhhhjghdeigikhnllloloor"],
    ["Tangshan, China", "Asia", 1891, 2025, "fdeifeedcgdhffgfeghiififeeikhgegihgjeikjknkmlmjmpopr"],
    ["Tanzania", "Africa", 1892, 2025, "cdeghccbddccfegfgeggffffgegfceiffgikhmhjkkkoqnpoqonr"],
    ["Tashkent, Uzbekistan", "Asia", 1877, 2025, "iiedhfgcgfegfigdhiceehmhhdggfihjgggiihijhikmmmlklmnp"],
    ["Tbilisi, Georgia", "Asia", 1850, 2025, "fgedfgiilefhgehggffihhifehjhgfhhgjjhfgjghkfjnkllmopp"],
    ["Tébessa, Algeria", "Africa", 1850, 2025, "cdedhjigjheffgigefhhffhijhfijhigihhgeeghjjjkonmmonor"],
    ["Tegucigalpa, Honduras", "Central America", 1908, 2025, "ccdfcgedgfifecfgejfgifigehgigigjijgkiknkkklmjiknnqnq"],
    ["Tehran, Iran", "Middle East", 1882, 2025, "hgjgggfhfefgjifhgeeehkhhegifiijfhfgiggjifknollnmpppr"],
    ["Telford, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggggihgikggjeghhjfjeljlmnnklnor"],
    ["Tembisa, South Africa", "Africa", 1881, 2025, "cecddgdeeadffcefffhffhgiihdhhiigigfhikjilimjnkkloojo"],
    ["Teni, India", "Asia", 1865, 2025, "bdaacaabcbhfefcefceffeeggeffgeifihfggikljillmklnoppo"],
    ["Teresina, Brazil", "South America", 1896, 2025, "gggeegeiagccfgkdggjgigihgjgfghheghiiiikkkmmnmlmoqnmp"],
    ["Thailand", "Asia", 1876, 2025, "ddcbdccfefddeeaededfffgfhfgggifiiffgkijjjjlklllloooq"],
    ["Thāne, India", "Asia", 1875, 2025, "efdadedghheddfegfgefccdgegfgfhfkifejigjihilkmlokoonp"],
    ["The Bahamas", "Caribbean", 1850, 2025, "eccdbeddeeecddgcddecdcifffffghgfhggeghhijllkknlkmoqq"],
    ["The Bronx, United States of America", "North America", 1850, 2025, "ffcfgdfchhefgghgdfheejeikgghiikiggghiigijlhimjmmlnoo"],
    ["Thimphu, Bhutan", "Asia", 1870, 2025, "gefhddhdhggceecgegefgfghhhgjhjgeegihigjkhjjmkoplpqqr"],
    ["Thiruvananthapuram, India", "Asia", 1865, 2025, "feaadaabbbghffcegddegfehheffhdieigfegiiljilmmmmnnpqq"],
    ["Tianjin, China", "Asia", 1891, 2025, "gdeifeeddgdhffgfefhiigieeeikhgegihgjeikilnllmninpqpr"],
    ["Tianshui, China", "Asia", 1915, 2025, "fcgghfifigekklkkfgkghiiggggjggihdgihiijpmmlqmkqrqqrr"],
    ["Tijuana, Mexico", "North America", 1850, 2025, "cfcffgdfhegfgfggifefffhgfhjhfefglghifgkkijlnikkinqml"],
    ["Tirana, Albania", "Europe", 1850, 2025, "cgdiiigehgeeeghifffiiiijfjehjikgiighggghjilhmmknppqr"],
    ["Tiruchirappalli, India", "Asia", 1865, 2025, "dcabdbabdchgegdffdfggeegfegghchehhfggijlkikmnjlmoppo"],
    ["Tlalnepantla, Mexico", "North America", 1878, 2025, "ccaaabeefdddceefghhiffiikiieijiejjfijiiijkkilkklknpq"],
    ["Tlalpan, Mexico", "North America", 1878, 2025, "dcaaabeefddeceeffhhjffiilihejjhekjfijijijlkjlkkllnpq"],
    ["Togo", "Africa", 1886, 2025, "dccgdfbccafgeggggfeiggggfeeffefgiehijkjhkmklnmnloonq"],
    ["Tokyo, Japan", "Asia", 1873, 2025, "gfgdbchfdeebceieffdgfdhgdhhgijjgihggjgeiljkllklkmopr"],
    ["Toledo, United States of America", "North America", 1850, 2025, "fhegfdfeiicfghhgeghgfkehkgiiiijjhhghiifikkhhnjlkkmmo"],
    ["Toluca, Mexico", "North America", 1878, 2025, "dbaaacedfcdeceeffhhiffiikhhejihekjfijhjijlkjmlkllnqr"],
    ["Tonga", "Pacific", 1920, 2025, "eefefcghigegfhggiifgheedehkgfkiigkkiflkmmmmompooqqqq"],
    ["Tongshan, China", "Asia", 1871, 2025, "gggfeefeefgdecgegfghgffkhihhegkhjefhiheiiklmmollorrr"],
    ["Toronto, Canada", "North America", 1850, 2025, "fgfggcfdjiceghihegihfjdglgghiilihhghihgijkhhnjlllnno"],
    ["Torreon, Mexico", "North America", 1850, 2025, "eacifjgfeddadfdgeidefkhjihgijkikhkiiighjfkjjljkkkkpq"],
    ["Touba, Senegal", "Africa", 1891, 2025, "edgfgddcedbfgheffgeihgeeeefgfdhhehjjhkjkllmllllmmlpo"],
    ["Trinidad and Tobago", "Caribbean", 1850, 2025, "cdbcaccbfccfcdegddcdcbefgeghefgeihfhffihhijlmllmmnop"],
    ["Tripoli, Libya", "Africa", 1864, 2025, "hghehhffeiiihffghhggjiiiegiejggigffeffgilhlmpmoppppr"],
    ["Tucson, United States of America", "North America", 1850, 2025, "ajdgigghjefifgdhgeegefggfkjigihiigggfgkfijjmkmmlnpno"],
    ["Tulsa, United States of America", "North America", 1850, 2025, "fgcjddecghbfegfgdihgekfgkijhifikfiigiiihjjhhmjmkknlo"],
    ["Tunis, Tunisia", "Africa", 1850, 2025, "bcecfggfhhdeefigecffegighhehiihfgihgefehijklnnmmonor"],
    ["Tunisia", "Africa", 1850, 2025, "beecghhgjhegfhigeeghefihjhehjhigihggeefhijjkonmnpnor"],
    ["Turin, Italy", "Europe", 1850, 2025, "cceffgefefdaddjefdeeeihhehfgilifihhfhgehhllklnmlnppr"],
    ["Turkiye", "Middle East", 1850, 2025, "eiffhihimegggfgiffejhhiifjigiehiijijgfkgiifimjkmnopq"],
    ["Turkmenistan", "Asia", 1877, 2025, "ihfegffegffheigehhceegkggdghgihifgfhiiikhjlmkmlklmnp"],
    ["Uberlândia, Brazil", "South America", 1855, 2025, "gddgiecfddgdehhfcficcfggffgfeehefgggihhijillkmlmnnqq"],
    ["Uganda", "Africa", 1901, 2025, "idfdeabccdegfeeegggefefdhedeffggikjimgkjmimqmqnpqnor"],
    ["Ukraine", "Europe", 1850, 2025, "hggefhffhfgfgfhiieghgiifekidgiigihigiigjdkihlkmmnopq"],
    ["Ulan Bator, Mongolia", "Asia", 1882, 2025, "ggefjfghegfgeiigfcdcgfgdhdedghgegighjfijklllkpjhnonp"],
    ["Ulhasnagar, India", "Asia", 1875, 2025, "efdacedhigeddfegfgefccdhegfgfhfkiffjjfkhhilkmlokoonp"],
    ["Ulsan, South Korea", "Asia", 1870, 2025, "fefedegdggdecdefffdgfffggehhgijghghiihgjljllmlkjmmor"],
    ["Umraniye, Turkiye", "Middle East", 1850, 2025, "ejdgfeggicffffhieeeighhhfkhdieighjjighihghigmkmnooqq"],
    ["United Arab Emirates", "Middle East", 1893, 2025, "gdeheegdhdegighgfffihhdhihfigchegjkcghhgjoopnmqmqrrr"],
    ["United Kingdom", "Europe", 1884, 2025, "ebeffiffgfigfhdgggkhigkiihfkgegghihejdjkilmnookmmopr"],
    ["United States of America", "North America", 1895, 2025, "eeieegieeejfigklijihihelhhghgfgigeihkilhiommoinjqmpr"],
    ["Uppsala, Sweden", "Europe", 1739, 2025, "hggfjgiheijgfggjghfgghgfgegfhfgjgggkgjjfigjghjkmmkno"],
    ["Uruguay", "South America", 1856, 2025, "ceeiechdeadcgfffcfefefgggggifidhifjhhhlijijklkkjmnmn"],
    ["Ürümqi, China", "Asia", 1879, 2025, "iefhdgfffefghgghhgdfciiiffdgggigfgfhigglgjnllomlnnpq"],
    ["Üsküdar, Turkiye", "Middle East", 1850, 2025, "ejdgfeggicffffhieeeighhhfkhdieighjjighihghigmkmnooqq"],
    ["Uzbekistan", "Asia", 1875, 2025, "gifegdffegeefiidhhdddfihgfdhgghjfghgjhijhkjmlmlklmnp"],
    ["Vadodara, India", "Asia", 1875, 2025, "ehfbeffjkjhffggihhegeegidjhhhhhlifhihdmijjjkljmknonm"],
    ["Valencia, Spain", "Europe", 1850, 2025, "dcgfegeghgbbdeiefeefeffifhfgijgfiihgdehhjkjmmmllooor"],
    ["Valencia, Venezuela", "South America", 1891, 2025, "ccggeddedgbdcffgfddiheefgdiihhigehiifkgijmknmmloponq"],
    ["Vancouver, Canada", "North America", 1850, 2025, "ffeeeffehdhheeggheegeejggikkidhejhigggjhijllkmkjlomm"],
    ["Varanasi, India", "Asia", 1875, 2025, "egdbdeeihicgeeeegefhddgjehhjiiglheigjgjjjkjkklnilmkm"],
    ["Venezuela", "South America", 1887, 2025, "cdafefcdcdebcbeefeedjeeehfghhifggejhiggijminmknmqonp"],
    ["Veracruz, Mexico", "North America", 1878, 2025, "eebbacdeecfgbeegehekffgjjiifihifgkihjhfjjllikljmlopq"],
    ["Vienna, Austria", "Europe", 1775, 2025, "egdhjhggdhgdgcedefghfeeceeeeffffehchifhggihhjkllmopp"],
    ["Vientiane, Laos", "Asia", 1880, 2025, "cbbfbggffedefaefedeeffhigfigigigghgjijkkjilkkjolpoop"],
    ["Vietnam", "Asia", 1890, 2025, "ebefgceeffaedcdceeghfhggifihgihehfiigkkiinjlmkkmpppq"],
    ["Vijayawada, India", "Asia", 1875, 2025, "cgdbbddihgggfgdhgggecfehfhgfeheihfihljkhhinklklknoln"],
    ["Vilnius, Lithuania", "Europe", 1850, 2025, "gfhfgheffggffhigheihgghggkhdhkhgihhfjigkemjilklklmoo"],
    ["Virginia Beach, United States of America", "North America", 1850, 2025, "gfdfhdgcgheefghgefhgejfgkgiiijkihgegjifijljhllmllopo"],
    ["Visakhapatnam, India", "Asia", 1875, 2025, "afbbbddjhfdecedggffdcfdgegggfgeihfigkkkihhllllmmpnnq"],
    ["Wales, United Kingdom", "Europe", 1884, 2025, "ebegejfeffjifiehggjhihkijhgkgegghihfjdjkjkmmnnkmmopq"],
    ["Walsall, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggggihgikggjeghhjfjeljkmnnllnor"],
    ["Warangal, India", "Asia", 1875, 2025, "cfcacediigeffhehggigcfehehggfgekigiikjlhhhliljljmnjl"],
    ["Warri, Nigeria", "Africa", 1886, 2025, "cbbeceaccbffegegcdgggfgffddgfefgieiiiijiklkknoomqoor"],
    ["Warsaw, Poland", "Europe", 1850, 2025, "hegfgiefgggdggigheiihghgfkhehkigigigijgkflkhlkmjloop"],
    ["Washington DC, United States of America", "North America", 1895, 2025, "eggdgehgeeigfhkigjgijihkiifgfghkifhikhmiioljmkpjooop"],
    ["Watford, United Kingdom", "Europe", 1850, 2025, "fcgegifgeeebdfiffeigehgggihgikggjegghjfjeljkmnnlmoor"],
    ["Wenzhou, China", "Asia", 1871, 2025, "gccdaaecddebfeeecededfhhhhiighihhfgghgfhijlmoomkoqrr"],
    ["West Bromwich, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggggihgikggjeghhjfjeljkmnnllnor"],
    ["Western Sahara", "Africa", 1884, 2025, "cfcgdheecededgggggehhhjhggifihggdefjjiliillmmlolomqq"],
    ["Wichita, United States of America", "North America", 1850, 2025, "fidjfeechgbeehggehhgekggkijhifikfiihhiigjkihmjkkknln"],
    ["Windhoek, Namibia", "Africa", 1920, 2025, "fiekhggcecjggiifgdfgjigghiedghikhkiiilmikoknmfkqnplp"],
    ["Winnipeg, Canada", "North America", 1850, 2025, "idehjehckecfegfiffggfjfgifjiheihhieggjijkjignjkljmlm"],
    ["Wolverhampton, United Kingdom", "Europe", 1850, 2025, "fcgdghggeeecefiffehgeggggihgikggjeghhjfjeljlmnnklnor"],
    ["Wrocław, Poland", "Europe", 1850, 2025, "hcgggjeggggdffhghfiigghgfkgfikjfigigijgkfllgllmjmoop"],
    ["Wuhan, China", "Asia", 1871, 2025, "gfefddfdeegbechdfghifgfjgjigehjiieggihfgijlmmomlnrrr"],
    ["Wuhu, China", "Asia", 1871, 2025, "geefcbecedfcddgefefheggjhjhhegjhiefghgehiklmnpmmnqrr"],
    ["Wuxi, China", "Asia", 1871, 2025, "gddecbeceeededfefffgfhgjgiiiegkihefghgfgjjlmnpmlnrrr"],
    ["Xiamen, China", "Asia", 1865, 2025, "deecebacdcdccdedebdcefghghhijghijgghhiggijhmnlnjnqrq"],
    ["Xi’an, China", "Asia", 1905, 2025, "cedfiefggghggeglkijefhfkjgkggifkhgeihgikomnnmlnoqprr"],
    ["Xiangtan, China", "Asia", 1871, 2025, "efdfccfdedhbechdfgfifhgjhjgffhjjiehgjhfhihkkmonloqrr"],
    ["Xianyang, China", "Asia", 1905, 2025, "cedfiefghghggeglkijefhfjjgkfgifkigeihgijomnnmlnoqorr"],
    ["Xingtai, China", "Asia", 1891, 2025, "gdchgdeddhdhhhigfehihhjeeeikgheghggjeiiikolmmnjopqrr"],
    ["Xining, China", "Asia", 1923, 2025, "fegigkedkkjfljfkgfjhghfggjgchiefijjgiipmnmqopopqoqrr"],
    ["Xinyang, China", "Asia", 1871, 2025, "ggggeegfeegcedhefgiiggfkhjhhdhkhieghihfhijlmlnllnprr"],
    ["Yancheng, China", "Asia", 1871, 2025, "geeeccfdffeeedfegefgghgjhhiiegkghefhigfgiklmnomlnqrr"],
    ["Yangon, Myanmar", "Asia", 1870, 2025, "bbfbbcdbedfbecccedeeheeffhegdjihjgffkhijijljkmmlqrqq"],
    ["Yangzhou, China", "Asia", 1871, 2025, "geeeccfdeeedddgefefgfhgjhihhegkhhefhhgegiklmnpmlnqrr"],
    ["Yantai, China", "Asia", 1869, 2025, "hegffdegfggffdcgegeffggjigfghekghegfjhghkkjnlmnhnprq"],
    ["Yaoundé, Cameroon", "Africa", 1900, 2025, "eccbbfgbedcedefigighgfedgfffggheiiifkiikljmonpmnqpoq"],
    ["Yemen", "Middle East", 1886, 2025, "cdeeefeedcededfhgfgehiigfheggeggidiiehiilmomnknmqppr"],
    ["Yerevan, Armenia", "Asia", 1850, 2025, "fhgfgijjmggiighhffgjihjgeijiigiiiiiiegkgjieknjkmmnoq"],
    ["Yingkou, China", "Asia", 1887, 2025, "egeejfegdcediffgffgihichegejighehghhiflklmkllojlopor"],
    ["Yogyakarta, Indonesia", "Asia", 1866, 2025, "cdbbcbbcbadcbdcbccddegegegieggiefhghgihiiikmnnmnopqq"],
    ["Yokohama, Japan", "Asia", 1873, 2025, "fegdbcgfdedbcfieffdfgdhhdhhhijihihggjgejljkllkllnopr"],
    ["Yono, Japan", "Asia", 1873, 2025, "gggdccgedeebceiefgdgfdhgdhhgijjhihggjgfiljkllklkmnpr"],
    ["York, United Kingdom", "Europe", 1850, 2025, "gcgdghggdeecefhfgehgeggfhiigikhgjegghjfjelikmnnllnor"],
    ["Yueyang, China", "Asia", 1871, 2025, "ffegddfdedhbdchdfghifggkhjggfhjjieggjhfhjiklmomlnqqr"],
    ["Yunfu, China", "Asia", 1865, 2025, "ggedfcacfcdegeeehdfeedeghigihhhikfgigifiiihmmmljnorq"],
    ["Zagreb, Croatia", "Europe", 1850, 2025, "eeeghjgggggdefighfhhgihiekffikjejgiggigifjmhmmmmoppr"],
    ["Zahedan, Iran", "Middle East", 1878, 2025, "iighfhihjeheigfgghhgeglgiekhhghgjfejjijgghlonnnmnoor"],
    ["Zambia", "Africa", 1897, 2025, "eggeddficgiggggedeighggghigdhggfeghkkllkkklnnmmopqmq"],
    ["Zapopan, Mexico", "North America", 1878, 2025, "cbaaadgegdeeceehgigifjkhlihhiihfkjgikfilhmjmlljnkopr"],
    ["Zaporizhia, Ukraine", "Europe", 1850, 2025, "hihefgffifgggehijffhgihfejidghhgiijhihiidkhhlkmmnnop"],
    ["Zaragoza, Spain", "Europe", 1850, 2025, "dbffhifggfcaeeiefeefefgififgilhfjiiheggijkjllmlmmnnr"],
    ["Zaria, Nigeria", "Africa", 1888, 2025, "idffhhbcfehfdhgijjgfkgfgeegfifhgighiimhhiljlnmolmmlo"],
    ["Zarqa, Jordan", "Middle East", 1861, 2025, "ekjffmgggiffkhfgdhfghijijjfihiihjhifgkfiigklmkmnnqqq"],
    ["Zhangjiakou, China", "Asia", 1891, 2025, "geehgefeefeigggfdegihfieedhihgehiggiejkikpkllninoooq"],
    ["Zhangzhou, China", "Asia", 1865, 2025, "dfecebabeddcceedebecffghghhijghijgghhhghiihmnlmknprq"],
    ["Zhanjiang, China", "Asia", 1865, 2025, "ghgegdadfcffhfeegdfdeeeghhgiiiiikffhhkfiikimmlljnnrq"],
    ["Zhengzhou, China", "Asia", 1891, 2025, "gedhgcfeejdghiigeehkiiiffeilgifghhgieihgknkmmmkoprrr"],
    ["Zhenjiang, China", "Asia", 1871, 2025, "geeeccfceeedddfefefgfhgjhihhegkhhefghgegiklmnpmmnqrr"],
    ["Zhongshan, China", "Asia", 1865, 2025, "ghfefdadfcffhfeegdedeeeghigiiihikffhhjfiijimmmljnnrq"],
    ["Zhu Cheng City, China", "Asia", 1869, 2025, "hfhffdfgefgfeedhfgfggffjjhgghekgiegfjgfhkkknlnmjoqrr"],
    ["Zhuhai, China", "Asia", 1865, 2025, "fgeefbabebddfddehcedeefghhfihhhijfghgifjijhmmmmknorq"],
    ["Zhumadian, China", "Asia", 1871, 2025, "gggfdegfffgcedheggiiggflhjhhdhkhjegiihfhhkkllnllnprr"],
    ["Zhuzhou, China", "Asia", 1871, 2025, "efdfccfdedhbechdfggifhgjhjgffhjkiehgjhfgihkkmonloqrr"],
    ["Zibo, China", "Asia", 1887, 2025, "gggehgeeecgdiffgfeeijggifgejihidfgjhggjhklmlmmkmqqqr"],
    ["Zigong, China", "Asia", 1899, 2025, "gicedegdefggedghililigiihjkiejkfjigehhgkjjmkqmkpqprr"],
    ["Zimbabwe", "Africa", 1897, 2025, "eghfedgidgjghggefeigiiggiiifhjgfgggjkjmlijklklmmnokp"],
    ["Zürich, Switzerland", "Europe", 1850, 2025, "dcfggiegdfgaddhfgdgffhghdiegikieighfgigjgkmjlmllmooq"],
  ]
  # END DATA

  var chosen, pos, places_key, order_key
  var index, colors, style_in, style_out, decks
  var order, warm, tiles, seed
  var start, title_ms, build, out_start

  def init()
    self.chosen = [0]
    self.pos = -1
    self.places_key = nil
    self.order_key = nil
    self.index = -1
    self.colors = []
    self.style_in = Stripes.SWEEP
    self.style_out = Stripes.FADE
    self.decks = [[], []]
    self.order = []
    self.warm = []
    self.tiles = []
    self.seed = now_ms() & 0x7FFFFFFF
    self.start = now_ms()
    self.title_ms = 0
    self.build = 8000
    self.out_start = -1
  end

  def duration()
    var value = int(store.get("durationMs", 30000))
    if value < 8000 value = 8000 end
    return value
  end

  def rand(n)
    self.seed = (self.seed * 1103515245 + 12345) & 0x7FFFFFFF
    return (self.seed >> 8) % n
  end

  def shuffle(a)
    var n = size(a)
    for i : 0 .. n - 2
      var j = i + self.rand(n - i)
      var t = a[i]
      a[i] = a[j]
      a[j] = t
    end
    return a
  end

  def range(n)
    var a = []
    for i : 0 .. n - 1 a.push(i) end
    return a
  end

  def trim(s)
    var a = 0
    var b = size(s) - 1
    while a <= b && s[a] == " " a += 1 end
    while b >= a && s[b] == " " b -= 1 end
    return a > b ? "" : s[a .. b]
  end

  # The places the Places setting names, in list order or shuffled
  def resolve()
    var key = str(store.get("places", Stripes.DEFAULT_PLACES))
    var order = str(store.get("order", "list"))
    if key == self.places_key && order == self.order_key return end
    self.places_key = key
    self.order_key = order

    # Places play in the order they are named, each once
    var places = Stripes.PLACES
    var n = size(places)
    var taken = []
    for i : 0 .. n - 1 taken.push(false) end
    self.chosen = []
    for raw : string.split(key, ";")
      var want = string.tolower(self.trim(raw))
      if want == "" continue end
      var hits = []
      if want == "all"
        hits = self.range(n)
      else
        # A full name, else a place without its country, else a region
        for i : 0 .. n - 1
          if string.tolower(places[i][0]) == want hits.push(i) end
        end
        if size(hits) == 0
          var prefix = want + ", "
          for i : 0 .. n - 1
            if string.find(string.tolower(places[i][0]), prefix) == 0 hits.push(i) end
          end
        end
        if size(hits) == 0
          for i : 0 .. n - 1
            if string.tolower(places[i][1]) == want hits.push(i) end
          end
        end
      end
      for i : hits
        if !taken[i]
          taken[i] = true
          self.chosen.push(i)
        end
      end
    end
    if size(self.chosen) == 0 self.chosen = [0] end
    if order == "shuffled" self.shuffle(self.chosen) end
    self.pos = -1
  end

  # A style by name; Random deals each style once in a new order, never the same twice in a row
  def pick(name, which)
    if name == "none" return -1 end
    if Stripes.OLD_NAMES.contains(name) name = Stripes.OLD_NAMES[name] end
    if name != "random"
      var i = Stripes.STYLES.find(name)
      return i == nil ? Stripes.SWEEP : i
    end
    var deck = self.decks[which]
    var last = which == 0 ? self.style_in : self.style_out
    if size(deck) == 0
      deck = self.shuffle(self.range(10))
      self.decks[which] = deck
      if deck[9] == last
        deck[9] = deck[0]
        deck[0] = last
      end
    end
    return deck.pop()
  end

  # Each column's rank from coldest to warmest; equal columns go left to right
  def warmth_ranks(levels)
    var idx = []
    for i : 0 .. 51
      var j = size(idx)
      while j > 0 && levels[idx[j - 1]] > levels[i] j -= 1 end
      idx.insert(j, i)
    end
    var rank = []
    rank.resize(52)
    for r : 0 .. 51 rank[idx[r]] = r end
    return rank
  end

  def on_show()
    self.resolve()
    self.pos = (self.pos + 1) % size(self.chosen)
    if self.pos == 0 && self.order_key == "shuffled" && size(self.chosen) > 1
      var last = self.index
      self.shuffle(self.chosen)
      if self.chosen[0] == last
        self.chosen[0] = self.chosen[-1 + size(self.chosen)]
        self.chosen[size(self.chosen) - 1] = last
      end
    end
    self.index = self.chosen[self.pos]

    var cols = Stripes.PLACES[self.index][4]
    var levels = []
    self.colors = []
    for x : 0 .. 51
      var ch = cols[x]
      var v = ch == "-" ? -1 : string.byte(ch) - 97
      levels.push(v)
      self.colors.push(v < 0 ? Stripes.GREY : Stripes.SCALE[v])
    end

    self.style_in = self.pick(str(store.get("styleIn", "sweep")), 0)
    var out = self.pick(str(store.get("styleOut", "fade")), 1)
    if out >= 0 self.style_out = out end
    self.order = self.shuffle(self.range(52))
    self.warm = self.warmth_ranks(levels)
    if self.style_in == Stripes.DISSOLVE || (out == Stripes.DISSOLVE)
      self.tiles = self.shuffle(self.range(416))
    end

    # The turn's timeline after the title: build in, hold, build out
    # The clock's transition runs on the app's own time, so the title holds through it too
    self.title_ms = 0
    if store.get("title", true)
      var fade = settings.get("transitionDurationMs")
      self.title_ms = Stripes.TITLE_MS + (fade == nil ? 0 : int(fade))
    end
    var avail = self.duration() - self.title_ms - Stripes.MARGIN_MS
    var build = int(store.get("buildMs", 8000))
    if build < 2000 build = 2000 end
    if out >= 0
      self.build = build * 2 > avail ? avail / 2 : build
      self.out_start = avail - self.build
    else
      self.build = build > avail ? avail : build
      self.out_start = -1
    end
    self.start = now_ms()
  end

  def clamp(v)
    return v < 0 ? 0.0 : (v > 1 ? 1.0 : v)
  end

  def smooth(v)
    return v * v * (3 - 2 * v)
  end

  def abs(v)
    return v < 0 ? -v : v
  end

  def dim(c, a)
    if a >= 1 return c end
    if a <= 0 return 0 end
    var r = int(((c >> 16) & 255) * a)
    var g = int(((c >> 8) & 255) * a)
    var b = int((c & 255) * a)
    return (r << 16) | (g << 8) | b
  end

  # A fall under gravity, then two short, low bounces
  def drop_fall(t)
    var h1 = 0.06
    var h2 = 0.015
    var b1 = 2 * math.sqrt(h1)
    var b2 = 2 * math.sqrt(h2)
    var u = t * (1 + b1 + b2)
    if u < 1 return u * u end
    u -= 1
    if u < b1
      var v = u - b1 / 2
      return 1 - (h1 - v * v)
    end
    u -= b1
    if u < b2
      var v = u - b2 / 2
      return 1 - (h2 - v * v)
    end
    return 1.0
  end

  # Progress of column x through a left-to-right wave that is w columns wide
  def wave(p, x, w)
    return self.clamp((p * (52 + w) - x) / w)
  end

  # Column x at progress p through style s. Erasing replays the motion in black.
  def paint(x, c, s, p, erase)
    var a = -1.0
    if s == Stripes.SWEEP
      a = self.clamp(p * 52 - x)
    elif s == Stripes.FADE
      a = self.smooth(p)
    elif s == Stripes.SCATTER
      a = self.clamp((p * 54.6 - self.order[x]) / 2.6)
    elif s == Stripes.WARMING
      a = self.clamp((p * 54.6 - self.warm[x]) / 2.6)
    elif s == Stripes.BLINDS
      # 13 slats, 4 columns each, open one after another and darker while edge-on
      var k = x / 4
      var q = self.smooth(self.clamp((p - 0.7 * k / 12.0) / 0.3))
      a = self.clamp(2 * q - self.abs(x + 0.5 - (4 * k + 2)) + 0.5)
      if !erase a *= 0.4 + 0.6 * q end
    end

    if a >= 0
      var v = self.dim(c, erase ? 1 - a : a)
      for y : 0 .. 15 pixel(x, y, v) end
      return
    end

    var top = 0.0
    var bottom = 16.0
    var shade = 1.0
    if s == Stripes.RISE
      top = 16 - 16 * self.smooth(self.wave(p, x, 13.0))
    elif s == Stripes.DROP
      var q = self.wave(p, x, 52 / 14.0)
      bottom = q > 0 ? 16 * self.drop_fall(q) : 0.0
    elif s == Stripes.OPEN
      # The column turns about its middle row
      var q = self.smooth(self.wave(p, x, 6.5))
      top = 8 - 8 * q
      bottom = 8 + 8 * q
      if !erase shade = 0.4 + 0.6 * q end
    end

    var r = self.smooth(p) * 27.2
    var dx = x + 0.5 - 26
    for y : 0 .. 15
      if s == Stripes.IRIS
        var dy = y + 0.5 - 8
        a = self.clamp(r - math.sqrt(dx * dx + dy * dy) + 0.5)
      elif s == Stripes.DISSOLVE
        a = self.clamp((p * 436.8 - self.tiles[x * 8 + y / 2]) / 20.8)
      else
        a = self.clamp(y + 1 - top) * self.clamp(bottom - y) * shade
      end
      pixel(x, y, self.dim(c, erase ? 1 - a : a))
    end
  end

  def draw_title(place)
    clear()
    var name = place[0]
    var comma = string.find(name, ", ")
    if comma > 0 name = name[0 .. comma - 1] end
    scroll_text(1, 6, 51, string.toupper(name), 0xFFFFFF)
    text(1, 14, str(place[2]) + "-" + str(place[3]), 0x8C8C8C)
  end

  def draw()
    if self.index < 0 self.on_show() end
    var t = now_ms() - self.start
    if t < self.title_ms
      self.draw_title(Stripes.PLACES[self.index])
      return
    end
    t -= self.title_ms

    var s = -1
    var p = 1.0
    var erase = false
    if t < self.build
      s = self.style_in
      p = real(t) / self.build
    elif self.out_start >= 0 && t >= self.out_start
      p = real(t - self.out_start) / self.build
      if p >= 1
        clear()
        return
      end
      s = self.style_out
      erase = true
    end

    for x : 0 .. 51
      if s < 0
        var c = self.colors[x]
        for y : 0 .. 15 pixel(x, y, c) end
      else
        self.paint(x, self.colors[x], s, p, erase)
      end
    end
  end
end

return Stripes()
