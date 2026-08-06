# Phase 1 Local Language Translation Matrix

## Purpose

This document prepares Phase 1 translation work for Acholi, Ateso, Lusoga, and Runyankole. It lists every current key from the `_strings` map in `lib/core/l10n/app_strings.dart` so reviewed translations can be prepared before any app code is updated.

## Important Clarification

Adding `AppLocale` entries only makes the languages selectable. It does not translate the app. Real translation values must be added under every key in `_strings` before those languages can display localized app copy.

## Phase 1 Languages

- Acholi: `AppLocale.ach`
- Ateso: `AppLocale.teo`
- Lusoga: `AppLocale.xog`
- Runyankole: `AppLocale.nyn`

## Translation Workflow

English source text
→ machine draft if available
→ native/fluent speaker review
→ approved translation
→ add approved values into `app_strings.dart`
→ test in the app

## Review Rule

Do not add unreviewed translations directly into the app.

## Implementation Rule

After translations are approved, `app_strings.dart` can be updated by adding `AppLocale.ach`, `AppLocale.teo`, `AppLocale.xog`, and `AppLocale.nyn` under each translation key.

## Translation Matrix

| Key | English | Luganda | Kiswahili | Acholi | Ateso | Lusoga | Runyankole | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| app_name | Otic She Connect | Otic She Connect | Otic She Connect | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| online | Online | Ku mutimbagano | Mtandaoni | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| offline | Offline | Toli ku mutimbagano | Nje ya mtandao | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| good_morning | Good morning | Wasuze otya | Habari za asubuhi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| good_afternoon | Good afternoon | Osiibye otya | Habari za mchana | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| good_evening | Good evening | Oweddeko otya | Habari za jioni | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| hero_title | Empowering your\ndigital journey | Tukubudde mu\nntambula yo ey'ekikompyuta | Kuwezesha safari\nyako ya kidijitali | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| hero_subtitle | Learn, Earn, Grow & Thrive — your path to opportunity starts here. | Soma, Funa, Kukula & Terera — ekkubo lyo ery'emikisa litandikira wano. | Jifunze, Pata, Kua & Stawi — njia yako ya fursa inaanzia hapa. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| continue_learning | Continue Learning | Weyongere Okusoma | Endelea Kujifunza | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| day_streak | day streak! | ennaku empita! | siku mfululizo! | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| your_progress | YOUR PROGRESS | ENTAMBULA YO | MAENDELEO YAKO | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| quick_actions | QUICK ACTIONS | BIKOLWA EBYANGUWA | VITENDO VYA HARAKA | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| explore_pillars | EXPLORE PILLARS | NOONYEREZA EMPAGI | GUNDUA NGUZO | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| all_services | ALL SERVICES | EMPEEREZA ZONNA | HUDUMA ZOTE | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| courses | Courses | Amasomo | Kozi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| points | Points | Obubonero | Pointi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| streak | Streak | Empita | Mfululizo | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| learn | Learn | Soma | Jifunze | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| earn | Earn | Funa | Pata | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| grow | Grow | Kukula | Kua | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| thrive | Thrive | Terera | Stawi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| learn_desc | Courses & digital skills | Amasomo n'obukugu bw'ekikompyuta | Kozi na ujuzi wa kidijitali | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| earn_desc | Marketplace & finance | Akatale n'ensimbi | Soko na fedha | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| grow_desc | Mentorship & careers | Obuyambi n'emirimu | Ushauri na kazi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| thrive_desc | Health & community | Obulamu n'ekibiina | Afya na jamii | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| ask_ai | Ask AI | Buuza AI | Uliza AI | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| find_jobs | Find Jobs | Noonya Emirimu | Tafuta Kazi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| marketplace | Marketplace | Akatale | Soko | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| finance | Finance | Ensimbi | Fedha | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| mentors | Mentors | Abayambi | Washauri | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| jobs | Jobs | Emirimu | Kazi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| skills | Skills | Obukugu | Ujuzi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| health | Health | Obulamu | Afya | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| community | Community | Ekibiina | Jamii | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| wellbeing | Wellbeing | Embeera ennungi | Ustawi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| settings | Settings | Entegeka | Mipangilio | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| profile | Profile | Ebikukwatako | Wasifu | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| ai_chat | AI Chat | Yogera ne AI | Soga na AI | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| home | Home | Ennyumba | Nyumbani | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| market | Market | Akatale | Soko | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| chat | Chat | Yogera | Soga | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| finance_tip | Finance Tip | Amagezi g'Ensimbi | Kidokezo cha Fedha | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| community_tip | Community Tip | Amagezi g'Ekibiina | Kidokezo cha Jamii | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| business_tip | Business Tip | Amagezi g'Obusubuzi | Kidokezo cha Biashara | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| health_tip | Health Tip | Amagezi g'Obulamu | Kidokezo cha Afya | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| skills_tip | Skills Tip | Amagezi g'Obukugu | Kidokezo cha Ujuzi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| tip_save | Save at least 10% of your income each week — small amounts grow fast! | Tereka watoowozo 10% ey'ensimbi zo buli wiiki — ebitono bikula mangu! | Weka akiba angalau 10% ya mapato yako kila wiki — kiasi kidogo hukua haraka! | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| tip_sacco | Join a local savings group (SACCO) to access loans and build credit. | Yingira mu kibiina ky'okuterekawo (SACCO) ofune ebbanja era ozimbe okwesigwa. | Jiunge na kikundi cha akiba (SACCO) kupata mikopo na kujenga sifa ya mkopo. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| tip_photos | Take photos of your products in natural light for better online sales. | Kuba ebifaananyi by'ebyobusubuzi byo mu musana ogw'obutonde ofune okutunda obulungi. | Piga picha za bidhaa zako kwenye mwanga wa asili kwa mauzo bora mtandaoni. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| tip_water | Drink at least 8 glasses of water daily for better health and energy. | Okunywa watoowozo gilasi 8 ez'amazzi buli lunaku olw'obulamu obulungi n'amaanyi. | Kunywa angalau glasi 8 za maji kila siku kwa afya na nishati bora. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| tip_digital | Practice one new digital skill each week — consistency beats speed. | Gezaako obukugu bw'ekikompyuta obuggya buli wiiki — okugoberera kusinga okwanguyiriza. | Fanya mazoezi ya ujuzi mpya wa kidijitali kila wiki — uthabiti unashinda kasi. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| welcome_to | Welcome to\nOtic She Connect | Tukusanyukira ku\nOtic She Connect | Karibu kwenye\nOtic She Connect | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| welcome_desc | Your digital companion for learning, earning, growing, and thriving. Works online and offline — your progress is always safe. | Munno wo ow'ekikompyuta okusoma, okufuna, okukula, n'okuterera. Akola ku mutimbagano ne bw'otaba — entambula yo etereka. | Mwenzako wa kidijitali wa kujifunza, kupata, kukua, na kustawi. Inafanya kazi mtandaoni na nje — maendeleo yako ni salama daima. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| whats_your_name | What's your name? | Erinnya lyo ggwe ani? | Jina lako ni nani? | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| enter_your_name | Enter your name | Wandiika erinnya lyo | Ingiza jina lako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| continue_btn | Continue | Okwongera | Endelea | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| back | Back | Nnyuma | Rudi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| start_journey | Start your journey | Sooka olugendo lwo | Anza safari yako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| about_you | About you | Ebikukwatako | Kuhusu wewe | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| about_you_desc | This helps us personalise your experience with relevant opportunities and resources. | Kino kituyamba okukukolera ebikugyanira mu mbeera n'ebyobulamu. | Hii inatusaidia kubinafsisha uzoefu wako na fursa na rasilimali zinazofaa. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| what_describes_you | What best describes you? | Kiki ekikukubaganya? | Ni nini kinachokuelezea vyema? | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| where_based | Where are you based? | Obeera wa? | Uko wapi? | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| location_hint | e.g. Kampala, Mukono, Mbale | okugeza Kampala, Mukono, Mbale | mf. Kampala, Mukono, Mbale | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| choose_language | Choose your language | Londa olulimi lwo | Chagua lugha yako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| please_enter_name | Please enter your name | Nsaba wandiike erinnya lyo | Tafadhali ingiza jina lako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_entrepreneur | Entrepreneur | Omusubuzi | Mjasiriamali | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_entrepreneur_desc | I run or want to start a business | Nkola obusubuzi oba njagala okutandika | Ninaendesha au nataka kuanzisha biashara | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_farmer | Farmer | Omulimi | Mkulima | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_farmer_desc | I work in agriculture or agribusiness | Nkola mu bulimi | Ninafanya kazi katika kilimo | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_student | Student | Omuyizi | Mwanafunzi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_student_desc | I am currently studying or in training | Ndi mu kusoma oba okutendekebwa | Ninasoma au ninafunzwa sasa | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_job_seeker | Job Seeker | Anoonya omulimu | Mtafuta kazi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_job_seeker_desc | I am looking for employment | Nnoonya omulimu | Ninatafuta ajira | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_leader | Community Leader | Omukulembeze w'ekibiina | Kiongozi wa jamii | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_leader_desc | I lead or organize in my community | Nkulembera oba ntegeka mu kibiina kyange | Ninaongoza au ninapanga katika jamii yangu | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_artisan | Artisan / Creator | Omukozi w'emikono | Fundi / Muundaji | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| role_artisan_desc | I create handmade goods or crafts | Nkola ebintu n'emikono gyange | Ninaunda bidhaa za mikono au sanaa | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| appearance | Appearance | Endabika | Muonekano | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| language | Language | Olulimi | Lugha | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| app_language | App Language | Olulimi lw'App | Lugha ya App | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| data_sync | Data & Sync | Ebikukwatako n'Okukolagana | Data na Usawazishaji | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| notifications | Notifications | Amawulire | Arifa | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| about | About | Ebikwata ku | Kuhusu | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| new_chat | New chat | Emboozi empya | Mazungumzo mapya | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| ask_anything | Ask anything... | Buuza ekikyamu kyonna... | Uliza chochote... | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| thinking | Thinking... | Nlowooza... | Nafikiri... | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| knowledge_is_power | Knowledge is power | Amagezi ge Amaanyi | Maarifa ni nguvu | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| knowledge_is_power_desc | Practical courses designed for women — from digital skills to business management, all in your language. | Amasomo ag'obukwatirivu ga bakazi — okuva mu bukugu bw'ekikompyuta okutuuka mu kulabirira obusubuzi, byonna mu lulimi lwo. | Kozi za vitendo zilizoundwa kwa wanawake — kutoka ujuzi wa kidijitali hadi usimamizi wa biashara, zote kwa lugha yako. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| next_milestone | Next milestone | Ekigendererwa Ekiddako | Lengo linalofuata | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| featured_courses | Featured Courses | Amasomo Agasingayo | Kozi Maalum | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| browse_topics | Browse Topics | Noonyereza Ebyagenda | Vinjari Mada | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| practical_skills_sub | Practical skills for everyday life | Obukugu obw'okukozesa buli lunaku | Ujuzi wa vitendo kwa maisha ya kila siku | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| ai_learning_assistant | AI Learning Assistant | Omuyambi w'Okusoma wa AI | Msaidizi wa AI wa Kujifunza | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| ai_learning_desc | Ask any question and get instant help | Buuza ekibuuzo kyonna ofune obuyambi mangu | Uliza swali lolote na upate msaada wa haraka | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| ask_ai_assistant | Ask AI Assistant | Buuza Omuyambi wa AI | Uliza Msaidizi wa AI | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| ask_ai_assistant_desc | Get personalised answers on business, farming, health, and more | Funa ennyini z'obukwatirivu ku busubuzi, bulimi, obulamu, n'ebirala | Pata majibu ya kibinafsi kuhusu biashara, kilimo, afya, na zaidi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| lessons | lessons | amasomo | masomo | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| in_progress | In Progress | Mu Entambula | Inaendelea | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_digital | Digital Skills | Obukugu bw'Ekikompyuta | Ujuzi wa Kidijitali | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_digital_desc | Computers, internet, and mobile basics | Ebyekikompyuta, mutimbagano, n'omukono gw'ettelefooni | Kompyuta, intaneti, na misingi ya simu | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_finance_lit | Financial Literacy | Okumanya Ensimbi | Elimu ya Fedha | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_finance_lit_desc | Budgeting, savings, and money management | Okubala ensimbi, okuterekawo, n'okulabirira ensimbi | Bajeti, akiba, na usimamizi wa pesa | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_entrepreneur | Entrepreneurship | Obusubuzi | Ujasiriamali | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_entrepreneur_desc | Start and grow your business | Tandika era okule obusubuzi bwo | Anza na kukua biashara yako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_agri | Agriculture | Obulimi | Kilimo | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_agri_desc | Modern farming techniques and agribusiness | Enkolagana ez'obulimi obupya n'obusubuzi bw'ebyobulimi | Mbinu za kisasa za kilimo na biashara ya kilimo | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_health_nut | Health & Nutrition | Obulamu n'Ebyokulya | Afya na Lishe | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_health_nut_desc | Family health, nutrition, and wellness | Obulamu bw'oluganda, ebyokulya, n'emirembe | Afya ya familia, lishe, na ustawi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_leadership | Leadership | Obukulu | Uongozi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_leadership_desc | Community leadership and advocacy skills | Obukulu bw'ekibiina n'obukugu bw'okwogera | Uongozi wa jamii na ujuzi wa utetezi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| sell_products | Sell your products & services | Tunda ebintu byo n'empeereza zo | Uza bidhaa na huduma zako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| sell_products_desc | Connect with buyers in your community and beyond. List your products, set prices, and grow your business. | Kolagana n'abaagula mu kibiina kyo n'ebirala. Wandiika ebintu byo, teekawo emiwendo, era okule obusubuzi bwo. | Unganika na wanunuzi katika jamii yako na zaidi. Orodhesha bidhaa zako, weka bei, na kukua biashara yako. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| list_product_btn | List a Product | Wandiika Ekintu | Orodhesha Bidhaa | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| categories | Categories | Emitono | Makundi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| browse_products | Browse products and services | Noonyereza ebintu n'empeereza | Vinjari bidhaa na huduma | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| featured_listings | Featured Listings | Ebintu Ebyasinguliriziddwa | Orodha Zilizoangaziwa | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| popular_products_desc | Popular products from women in your area | Ebintu ebisinganyiziddwa okuva ku bakazi mu kifo kyo | Bidhaa maarufu kutoka kwa wanawake eneo lako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| see_all | See all | Laba byonna | Ona yote | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_crafts | Crafts | Ebikozesebwa emikono | Ufundi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_food_drink | Food & Drink | Ebyokulya n'Okunywa | Chakula na Vinywaji | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_fashion | Fashion | Engoye | Mitindo | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_beauty | Beauty | Obuwanguzi | Urembo | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| cat_services | Services | Empeereza | Huduma | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| grow_with_guidance | Grow with guidance | Kula n'Amagezi | Kua kwa mwongozo | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| grow_with_guidance_desc | Every successful woman had someone who believed in her. Find your mentor or become one. | Omukazi buli omu eyakuwerera yaali n'omuntu eyamwesiga. Noonyereza omuyambi wo oba gwa obenga. | Kila mwanamke aliyefanikiwa alikuwa na mtu aliyemwamini. Tafuta mshauri wako au uwe mmoja. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| find_mentor_title | Find a Mentor | Noonyereza Omuyambi | Tafuta Mshauri | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| find_mentor_desc | Connect with experienced women who can guide you | Kolagana n'abakazi ab'obutegefu abasobola okukuyongereza | Unganika na wanawake wenye uzoefu wanaoweza kukuongoza | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| become_mentor_title | Become a Mentor | Gwa Omuyambi | Kuwa Mshauri | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| become_mentor_desc | Share your experience and uplift others | Gabana obutegefu bwo era oyinze abalala | Shiriki uzoefu wako na inua wengine | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| connect_btn | Connect | Kolagana | Unganika | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| apply_to_mentor | Apply to Mentor | Saba Okuba Omuyambi | Omba Kuwa Mshauri | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| share_knowledge | Share your knowledge | Gabana Amagezi go | Shiriki maarifa yako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| share_knowledge_desc | Help other women grow by sharing your skills and experience. Being a mentor is one of the most impactful things you can do. | Yamba abakazi abalala okukula nga ogabana obukugu bwo n'obutegefu bwo. Okuba omuyambi kye kimu mu bintu ebimu ebyongeza ennyo. | Saidia wanawake wengine kukua kwa kushiriki ujuzi na uzoefu wako. Kuwa mshauri ni moja ya mambo yenye athari zaidi unayoweza kufanya. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| yrs_experience | yrs experience | emyaka gy'obutegefu | miaka ya uzoefu | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| your_health_matters | Your health matters | Obulamu bwo bwa muvubuka | Afya yako ni muhimu | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| your_health_matters_desc | Access trusted health information and connect with services in your community. | Funa amakwate g'obulamu ag'okwesiga era okolagane n'empeereza mu kibiina kyo. | Pata habari za afya za kuaminika na unganike na huduma katika jamii yako. | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| health_resources | Health Resources | Ebikwatira ku Obulamu | Rasilimali za Afya | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| trusted_health_desc | Trusted information for you and your family | Amakwate ag'okwesiga ku lwenyo n'oluganda lwo | Habari za kuaminika kwako na familia yako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| maternal_health | Maternal Health | Obulamu bw'Omuzadde | Afya ya Uzazi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| maternal_health_desc | Pregnancy, postnatal care, and family planning | Okubeerawo, okukuuma omuzadde, n'okutegekereza oluganda | Ujauzito, huduma baada ya kuzaa, na upangaji uzazi | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| nutrition_guide | Nutrition Guide | Ebiragiro by'Ebyokulya | Mwongozo wa Lishe | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| nutrition_guide_desc | Healthy eating for you and your children | Okulya obulungi ku lwenyo n'abaana bo | Ulaji bora kwako na watoto wako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| child_health | Child Health | Obulamu bw'Omwana | Afya ya Mtoto | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| child_health_desc | Immunisation, common illnesses, and child care | Enkangavvulo, emikungulu egy'omukutu, n'okukuuma abaana | Chanjo, magonjwa ya kawaida, na utunzaji wa mtoto | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| mental_wellness | Mental Wellness | Emirembe gw'Omutima | Afya ya Akili | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| mental_wellness_desc | Stress management, self-care, and emotional support | Okukuuma ettima, okwekuuma, n'obuyambi bw'emirembe | Usimamizi wa msongo, kujitunza, na msaada wa kihisia | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| nearby_services_title | Nearby Services | Empeereza Eziri Kumpi | Huduma Zilizo Karibu | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| nearby_services_sub | Health facilities and services in your area | Ebitalo n'empeereza z'obulamu mu kifo kyo | Vituo vya afya na huduma eneo lako | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| get_directions | Directions | Ekkubo | Elekeo | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| km_away | km away | km ewala | km mbali | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| powered_by_groq | Powered by Groq · Llama 3.3 | Yakozesebwa Groq · Llama 3.3 | Inayotumia Groq · Llama 3.3 | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| ai_greeting | Hello! I'm your AI assistant from Otic She Connect. I can help you with business advice, farming tips, health information, financial guidance, and much more. What would you like to know? | Oli otya! Nze omuyambi wo wa AI okuva ku Otic She Connect. Nsobola okukuyamba n'amagezi g'obusubuzi, ebyobulimi, amakwate g'obulamu, ebiragiro by'ensimbi, n'ebirala bingi. Oyagala okumanya ki? | Habari! Mimi ni msaidizi wako wa AI kutoka Otic She Connect. Ninaweza kukusaidia na ushauri wa biashara, vidokezo vya kilimo, habari za afya, mwongozo wa fedha, na mengi zaidi. Ungependa kujua nini? | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| chat_cleared | Chat cleared! How can I help you? | Emboozi esaziddwa! Nsobola kukuyamba otya? | Mazungumzo yamesafishwa! Ninawezaje kukusaidia? | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| topic_business_q | How do I start a small business? | Ndinda otya obusubuzi obuto? | Nianzisheje biashara ndogo vipi? | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| topic_savings_q | Tips for saving money | Amagezi g'okuterekawo ensimbi | Vidokezo vya kuweka akiba | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| topic_farming_q | Best crops for my region | Ebimera ebirungi mu kitundu kyange | Mazao bora kwa eneo langu | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
| topic_sell_online_q | How to sell online | Otunda otya ku mutimbagano | Jinsi ya kuuza mtandaoni | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Needs reviewed translation | Review required |
