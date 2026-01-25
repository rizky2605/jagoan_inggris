import '../../models/word_model.dart';

class VocabularyData {
  static final List<WordModel> masterWordBank = [
    
    // =======================================================
    // LEVEL 1: KATA SIFAT (ADJECTIVES) - DASAR & MENENGAH
    // =======================================================
    WordModel(
      id: 'abundant',
      word: 'Abundant', 
      pronunciation: '/əˈbʌn.dənt/', 
      category: 'Adjective', 
      meaning: 'Melimpah', 
      mnemonic: "Roti 'Bun' untuk 'Dance' tersedia MELIMPAH.", 
      exampleSentence: "We have abundant food for everyone.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'gloomy',
      word: 'Gloomy', 
      pronunciation: '/ˈɡluː.mi/', 
      category: 'Adjective', 
      meaning: 'Suram / Murung', 
      mnemonic: "Kena 'LEM' (Glu) di muka jadi SURAM.", 
      exampleSentence: "The sky looks gloomy today.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'keen',
      word: 'Keen', 
      pronunciation: '/kiːn/', 
      category: 'Adjective', 
      meaning: 'Tertarik / Tajam', 
      mnemonic: "Si 'IKIN' sangat TERTARIK belajar gitar.", 
      exampleSentence: "She is keen on learning music.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'candid',
      word: 'Candid', 
      pronunciation: '/ˈkæn.dɪd/', 
      category: 'Adjective', 
      meaning: 'Jujur / Terus Terang', 
      mnemonic: "KANDIDat presiden harus JUJUR.", 
      exampleSentence: "To be candid, I dislike the food.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'huge',
      word: 'Huge', 
      pronunciation: '/hjuːdʒ/', 
      category: 'Adjective', 
      meaning: 'Sangat Besar', 
      mnemonic: "'HIU' itu badannya SANGAT BESAR.", 
      exampleSentence: "That is a huge mistake.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'fragile',
      word: 'Fragile', 
      pronunciation: '/ˈfrædʒ.aɪl/', 
      category: 'Adjective', 
      meaning: 'Rapuh / Mudah Pecah', 
      mnemonic: "Per'GI' (Gile) kalau hati RAPUH.", 
      exampleSentence: "Handle with care, it's fragile.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'rural',
      word: 'Rural', 
      pronunciation: '/ˈrʊə.rəl/', 
      category: 'Adjective', 
      meaning: 'Pedesaan', 
      mnemonic: "'RUSA' banyak tinggal di PEDESAAN.", 
      exampleSentence: "I prefer living in a rural area.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'frugal',
      word: 'Frugal',
      pronunciation: '/ˈfruː.ɡəl/',
      category: 'Adjective',
      meaning: 'Hemat',
      mnemonic: "Makan 'FRUit' (buah) gagal 'GAL' biar HEMAT.", 
      exampleSentence: "He is frugal with his money.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'meticulous',
      word: 'Meticulous',
      pronunciation: '/məˈtɪk.jə.ləs/',
      category: 'Adjective',
      meaning: 'Sangat Teliti',
      mnemonic: "'MATI' kutu 'KULOS' kalau diperiksa SANGAT TELITI.", 
      exampleSentence: "She is meticulous about her work.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'lethargic',
      word: 'Lethargic',
      pronunciation: '/ləˈθɑː.dʒɪk/',
      category: 'Adjective',
      meaning: 'Lesu / Tidak Berenergi',
      mnemonic: "Telat 'LET' lari 'HAR' jadi LESU.", 
      exampleSentence: "I feel lethargic after eating too much.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'impeccable',
      word: 'Impeccable',
      pronunciation: '/ɪmˈpek.ə.bəl/',
      category: 'Adjective',
      meaning: 'Sempurna / Tanpa Cacat',
      mnemonic: "Kabel 'CABLE' ini dipasang dengan SEMPURNA.", 
      exampleSentence: "Her English is impeccable.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'garrulous',
      word: 'Garrulous',
      pronunciation: '/ˈɡær.əl.əs/',
      category: 'Adjective',
      meaning: 'Cerewet / Banyak Bicara',
      mnemonic: "'GARUK' terus karena nyamuknya CEREWET.", 
      exampleSentence: "The garrulous driver annoyed me.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'stubborn',
      word: 'Stubborn',
      pronunciation: '/ˈstʌb.ən/',
      category: 'Adjective',
      meaning: 'Keras Kepala',
      mnemonic: "'STAB' (tusuk) 'BORN' (lahir). Bayi lahir KERAS KEPALA.", 
      exampleSentence: "Don't be so stubborn.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'vulnerable',
      word: 'Vulnerable',
      pronunciation: '/ˈvʌl.nər.ə.bəl/',
      category: 'Adjective',
      meaning: 'Rentan',
      mnemonic: "'FULL' (Vul) 'NER'aka bikin kita RENTAN berdosa.", 
      exampleSentence: "Children are vulnerable to illness.", 
      nextReview: DateTime.now()
    ),

    // =======================================================
    // LEVEL 2: KATA KERJA (VERBS) - AKSI & PIKIRAN
    // =======================================================
    WordModel(
      id: 'vanish',
      word: 'Vanish', 
      pronunciation: '/ˈvæn.ɪʃ/', 
      category: 'Verb', 
      meaning: 'Menghilang', 
      mnemonic: "Pakai sabun 'Vanish', noda MENGHILANG.", 
      exampleSentence: "The ghost vanished into thin air.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'elaborate',
      word: 'Elaborate', 
      pronunciation: '/iˈlæb.ə.reɪt/', 
      category: 'Verb', 
      meaning: 'Menjelaskan Secara Detail', 
      mnemonic: "Di 'LAB'oratorium harus JELASKAN DETAIL.", 
      exampleSentence: "Can you elaborate on your idea?", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'ignite',
      word: 'Ignite',
      pronunciation: '/ɪɡˈnaɪt/',
      category: 'Verb',
      meaning: 'Menyalakan / Memicu',
      mnemonic: "'IG'or 'NITE' (night) MENYALAKAN api unggun.",
      exampleSentence: "Sparks ignite the fire.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'procrastinate',
      word: 'Procrastinate',
      pronunciation: '/prəˈkræs.tɪ.neɪt/',
      category: 'Verb',
      meaning: 'Menunda-nunda',
      mnemonic: "'PRO' 'KERAS' kepala suka MENUNDA 'NATE'.",
      exampleSentence: "Stop procrastinating and do your homework.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'scrutinize',
      word: 'Scrutinize',
      pronunciation: '/ˈskruː.tɪ.naɪz/',
      category: 'Verb',
      meaning: 'Memeriksa Dengan Teliti',
      mnemonic: "'SCRU' (Sekrup) ini harus DIPERIKSA TELITI.",
      exampleSentence: "The police scrutinized the evidence.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'ponder',
      word: 'Ponder',
      pronunciation: '/ˈpɒn.də/',
      category: 'Verb',
      meaning: 'Merenungkan / Memikirkan',
      mnemonic: "Di 'POND'ok 'DER'ita aku MERENUNG.",
      exampleSentence: "She pondered over the decision.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'rejuvenate',
      word: 'Rejuvenate',
      pronunciation: '/rɪˈdʒuː.vən.eɪt/',
      category: 'Verb',
      meaning: 'Meremajakan / Menyegarkan Kembali',
      mnemonic: "'JUVEN'ile (Remaja). RE-Juvenate = Jadi REMAJA lagi.",
      exampleSentence: "Sleep helps to rejuvenate the body.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'yearn',
      word: 'Yearn',
      pronunciation: '/jɜːn/',
      category: 'Verb',
      meaning: 'Sangat Merindukan / Mengidamkan',
      mnemonic: "Tiap 'YEAR' (Tahun) aku RINDU kampung halaman.",
      exampleSentence: "He yearns for freedom.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'hinder',
      word: 'Hinder',
      pronunciation: '/ˈhɪn.də/',
      category: 'Verb',
      meaning: 'Menghalangi',
      mnemonic: "'HIN'dari rintangan yang MENGHALANGI.",
      exampleSentence: "Don't let fear hinder your success.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'abolish',
      word: 'Abolish',
      pronunciation: '/əˈbɒl.ɪʃ/',
      category: 'Verb',
      meaning: 'Menghapuskan (Hukum/Aturan)',
      mnemonic: "A 'BOL' (Bola) menggelinding MENGHAPUS jejak.",
      exampleSentence: "Slavery was abolished years ago.",
      nextReview: DateTime.now()
    ),

    // =======================================================
    // LEVEL 3: KATA BENDA (NOUNS) - ABSTRAK & BENDA
    // =======================================================
    WordModel(
      id: 'obstacle',
      word: 'Obstacle', 
      pronunciation: '/ˈɒb.stə.kəl/', 
      category: 'Noun', 
      meaning: 'Hambatan / Rintangan', 
      mnemonic: "'OB'or 'STA'bil (Obsta) menerangi HAMBATAN.", 
      exampleSentence: "Fear is the biggest obstacle.", 
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'hazard',
      word: 'Hazard',
      pronunciation: '/ˈhæz.əd/',
      category: 'Noun',
      meaning: 'Bahaya / Risiko',
      mnemonic: "'HAZAR' (Hajar) saja kalau ada BAHAYA.",
      exampleSentence: "Smoking is a health hazard.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'cacophony',
      word: 'Cacophony',
      pronunciation: '/kəˈkɒf.ə.ni/',
      category: 'Noun',
      meaning: 'Suara Sumbang / Berisik',
      mnemonic: "'KAKO' (Kakek) 'PHONY' (Telepon) suaranya BERISIK/SUMBANG.",
      exampleSentence: "A cacophony of car horns.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'zenith',
      word: 'Zenith',
      pronunciation: '/ˈzen.ɪθ/',
      category: 'Noun',
      meaning: 'Puncak / Titik Tertinggi',
      mnemonic: "'ZENI't (Jenit) naik ke PUNCAK gunung.",
      exampleSentence: "At the zenith of his career.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'dilemma',
      word: 'Dilemma',
      pronunciation: '/daɪˈlem.ə/',
      category: 'Noun',
      meaning: 'Situasi Sulit (Dilema)',
      mnemonic: "'DI' 'LEM' a (di lem). Terjebak SITUASI SULIT.",
      exampleSentence: "I am facing a moral dilemma.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'paradox',
      word: 'Paradox',
      pronunciation: '/ˈpær.ə.dɒks/',
      category: 'Noun',
      meaning: 'Pertentangan (Paradoks)',
      mnemonic: "'PARA' 'DOK'ter bingung karena BERTENTANGAN.",
      exampleSentence: "It is a paradox that computers save time but waste it too.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'nostalgia',
      word: 'Nostalgia',
      pronunciation: '/nɒsˈtæl.dʒə/',
      category: 'Noun',
      meaning: 'Kenangan Masa Lalu',
      mnemonic: "NOSTALGIA = NOS (Hidung/Aroma) TAlgi (Tali) kenangan.",
      exampleSentence: "Old photos bring back nostalgia.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'knack',
      word: 'Knack',
      pronunciation: '/næk/',
      category: 'Noun',
      meaning: 'Bakat / Keahlian Khusus',
      mnemonic: "Ke 'NAK' (Enak) kalau punya BAKAT masak.",
      exampleSentence: "She has a knack for solving puzzles.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'sanctuary',
      word: 'Sanctuary',
      pronunciation: '/ˈsæŋk.tʃʊə.ri/',
      category: 'Noun',
      meaning: 'Tempat Perlindungan',
      mnemonic: "'SANG'kar burung itu TEMPAT PERLINDUNGAN.",
      exampleSentence: "The park is a sanctuary for wildlife.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'chaos',
      word: 'Chaos',
      pronunciation: '/ˈkeɪ.ɒs/',
      category: 'Noun',
      meaning: 'Kekacauan',
      mnemonic: "Kaos (CHAOS) kakiku hilang, jadi KEKACAUAN.",
      exampleSentence: "The room was in total chaos.",
      nextReview: DateTime.now()
    ),

    // =======================================================
    // LEVEL 4: KATA TINGKAT LANJUT (ADVANCED)
    // =======================================================
    WordModel(
      id: 'ephemeral',
      word: 'Ephemeral',
      pronunciation: '/əˈfem.ər.əl/',
      category: 'Adjective',
      meaning: 'Sementara / Singkat',
      mnemonic: "Ingat 'FM' (Radio). Lagu di radio itu EPHEMERAL (lewat sebentar).",
      exampleSentence: "Fashions are ephemeral.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'ubiquitous',
      word: 'Ubiquitous',
      pronunciation: '/juːˈbɪk.wɪ.təs/',
      category: 'Adjective',
      meaning: 'Ada Di Mana-mana',
      mnemonic: "'UBI' 'KUIT'ansi (Qui-tous) ADA DI MANA-MANA pasar.",
      exampleSentence: "Smartphones are ubiquitous nowadays.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'eloquent',
      word: 'Eloquent',
      pronunciation: '/ˈel.ə.kwənt/',
      category: 'Adjective',
      meaning: 'Fasih / Pandai Bicara',
      mnemonic: "'ELANG' (El) 'KWAN' (Quent) bicaranya FASIH.",
      exampleSentence: "An eloquent speech.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'benevolent',
      word: 'Benevolent',
      pronunciation: '/bəˈnev.əl.ənt/',
      category: 'Adjective',
      meaning: 'Baik Hati / Dermawan',
      mnemonic: "'BEN' benci 'VOL'ume keras karena dia BAIK HATI (lembut).",
      exampleSentence: "A benevolent donor gave money.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'inevitable',
      word: 'Inevitable',
      pronunciation: '/ɪˈnev.ɪ.tə.bəl/',
      category: 'Adjective',
      meaning: 'Tak Terelakkan',
      mnemonic: "'INI' 'VITA' 'BEL'i takdir yang TAK TERELAKKAN.",
      exampleSentence: "Change is inevitable.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'resilient',
      word: 'Resilient',
      pronunciation: '/rɪˈzɪl.jənt/',
      category: 'Adjective',
      meaning: 'Tangguh / Cepat Pulih',
      mnemonic: "'RESI' (Resi) 'LIEN' (Lient) orangnya TANGGUH.",
      exampleSentence: "She is resilient to criticism.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'mundane',
      word: 'Mundane',
      pronunciation: '/mʌnˈdeɪn/',
      category: 'Adjective',
      meaning: 'Biasa / Membosankan',
      mnemonic: "'MUN'gkin 'DANE' (Senin) hari yang MEMBOSANKAN.",
      exampleSentence: "Mundane daily chores.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'candid',
      word: 'Candid',
      pronunciation: '/ˈkæn.dɪd/',
      category: 'Adjective',
      meaning: 'Jujur / Apa Adanya',
      mnemonic: "Foto 'CANDID' itu JUJUR apa adanya.",
      exampleSentence: "Let's be candid about the problem.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'lucid',
      word: 'Lucid',
      pronunciation: '/ˈluː.sɪd/',
      category: 'Adjective',
      meaning: 'Jelas / Jernih (Pikiran)',
      mnemonic: "'LU' 'SID' (Lihat) airnya JERNIH/JELAS.",
      exampleSentence: "A lucid explanation.",
      nextReview: DateTime.now()
    ),
    WordModel(
      id: 'obscure',
      word: 'Obscure',
      pronunciation: '/əbˈskjʊər/',
      category: 'Adjective',
      meaning: 'Samar / Tidak Jelas',
      mnemonic: "'OBS'tacle 'CURE' (Kur) bikin pandangan TIDAK JELAS.",
      exampleSentence: "The meaning is obscure.",
      nextReview: DateTime.now()
    ),
  ];
}