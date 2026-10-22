class QuizQ {
  final String question;
  final List<String> options;
  final int answer; // indeks jawaban benar
  final String explanation;
  const QuizQ(this.question, this.options, this.answer, this.explanation);
}

const kQuiz = <QuizQ>[
    QuizQ('Apa ibu kota Australia?', ['Sydney', 'Melbourne', 'Canberra', 'Perth'], 2,
      'Ibu kota Australia adalah Canberra, bukan Sydney.'),
  QuizQ('Apa ibu kota Kanada?', ['Toronto', 'Ottawa', 'Vancouver', 'Montreal'], 1,
      'Ibu kota Kanada adalah Ottawa.'),
  QuizQ('Apa ibu kota Swiss?', ['Bern', 'Zürich', 'Jenewa', 'Basel'], 0,
      'Ibu kota Swiss adalah Bern, bukan Zürich atau Jenewa.'),
  QuizQ('Apa ibu kota Brasil?', ['Rio de Janeiro', 'São Paulo', 'Salvador', 'Brasília'], 3,
      'Ibu kota Brasil adalah Brasília.'),
  QuizQ('Apa ibu kota Turki?', ['Istanbul', 'Ankara', 'Izmir', 'Antalya'], 1,
      'Ibu kota Turki adalah Ankara, bukan Istanbul.'),
  QuizQ('Apa mata uang resmi Korea Selatan?', ['Yen', 'Yuan', 'Won', 'Ringgit'], 2,
      'Korea Selatan memakai won (KRW).'),
  QuizQ('Sungai terpanjang di Eropa adalah...', ['Danube (Donau)', 'Rhein', 'Volga', 'Seine'], 2,
      'Volga di Rusia adalah sungai terpanjang di Eropa.'),
  QuizQ('Negara terkecil di dunia berdasarkan luas wilayah adalah...',
      ['Vatikan', 'Monako', 'San Marino', 'Liechtenstein'], 0,
      'Vatikan adalah negara terkecil di dunia.'),
  QuizQ('Menara Eiffel awalnya dibangun untuk acara apa?',
      ['Olimpiade modern pertama', 'Pameran Dunia 1889', 'Peringatan kemenangan perang', 'Penobatan raja'], 1,
      'Menara Eiffel dibangun untuk Pameran Dunia (Exposition Universelle) 1889 di Paris.'),
  QuizQ('Gunung tertinggi di dunia diukur dari permukaan laut adalah...',
      ['K2', 'Kangchenjunga', 'Everest', 'Makalu'], 2,
      'Gunung Everest, di perbatasan Nepal dan Tiongkok.'),
  QuizQ('Gurun panas terbesar di dunia adalah...', ['Gobi', 'Sahara', 'Kalahari', 'Gurun Arab'], 1,
      'Sahara di Afrika Utara adalah gurun panas terbesar.'),
  QuizQ('Negara yang identik dengan kincir angin dan ladang tulip adalah...',
      ['Denmark', 'Belgia', 'Belanda', 'Swedia'], 2, 'Belanda terkenal dengan kincir angin dan ladang tulip.'),
  QuizQ('Festival Oktoberfest yang terkenal berasal dari kota...',
      ['Berlin', 'München', 'Hamburg', 'Wina'], 1, 'Oktoberfest berasal dari München (Munich), Jerman.'),
  QuizQ('Taj Mahal berada di negara...', ['Pakistan', 'India', 'Bangladesh', 'Nepal'], 1,
      'Taj Mahal berada di Agra, India.'),
  QuizQ('Machu Picchu dibangun oleh peradaban...', ['Maya', 'Aztek', 'Inca', 'Olmec'], 2,
      'Machu Picchu di Peru dibangun oleh peradaban Inca.'),
  QuizQ('Terusan Panama menghubungkan dua samudra, yaitu...',
      ['Atlantik dan Pasifik', 'Laut Merah dan Mediterania', 'Atlantik dan Hindia', 'Pasifik dan Arktik'], 0,
      'Terusan Panama menghubungkan Samudra Atlantik dan Pasifik.'),
  QuizQ('Negara dengan garis pantai terpanjang di dunia adalah...',
      ['Rusia', 'Kanada', 'Australia', 'Brasil'], 1, 'Kanada memiliki garis pantai terpanjang di dunia.'),
  QuizQ('Bahasa resmi Brasil adalah...', ['Spanyol', 'Portugis', 'Inggris', 'Prancis'], 1,
      'Brasil memakai bahasa Portugis, berbeda dari negara-negara tetangganya yang berbahasa Spanyol.'),
  QuizQ('Danau terdalam di dunia adalah...', ['Danau Victoria', 'Danau Superior', 'Danau Baikal', 'Danau Toba'], 2,
      'Danau Baikal di Rusia adalah danau terdalam di dunia.'),
  QuizQ('Basilika Sagrada Família di Barcelona dirancang oleh arsitek...',
      ['Antoni Gaudí', 'Le Corbusier', 'Frank Lloyd Wright', 'Zaha Hadid'], 0,
      'Sagrada Família dirancang oleh Antoni Gaudí.')];