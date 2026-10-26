class UniversityProfile {
  final String introduction;
  final String studyAreas;
  final String monthlyLivingCost;

  const UniversityProfile({
    required this.introduction,
    required this.studyAreas,
    required this.monthlyLivingCost,
  });
}

const kUniversityProfiles = <String, UniversityProfile>{
  'The University of Edinburgh': UniversityProfile(
    introduction: 'Universitas riset di Skotlandia dengan komunitas internasional dan tradisi akademik panjang. Kampusnya tersebar di pusat kota Edinburgh.',
    studyAreas: 'Informatika, kedokteran, ilmu sosial, dan humaniora',
    monthlyLivingCost: '£1.100–£1.700',
  ),
  'University of Manchester': UniversityProfile(
    introduction: 'Universitas riset besar di Manchester yang dikenal dengan lingkungan kampus multikultural dan kolaborasi lintas disiplin.',
    studyAreas: 'Teknik, ilmu komputer, bisnis, dan ilmu hayati',
    monthlyLivingCost: '£1.000–£1.500',
  ),
  "King's College London": UniversityProfile(
    introduction: 'Universitas riset di pusat London dengan jejaring akademik dan profesional yang luas serta beberapa kampus di sekitar kota.',
    studyAreas: 'Kesehatan, hukum, hubungan internasional, dan humaniora',
    monthlyLivingCost: '£1.500–£2.400',
  ),
  'TU Delft': UniversityProfile(
    introduction: 'Universitas teknologi di Delft yang berfokus pada rekayasa, desain, dan solusi untuk tantangan teknologi serta keberlanjutan.',
    studyAreas: 'Teknik sipil, arsitektur, aerospace, dan teknologi energi',
    monthlyLivingCost: '€1.000–€1.600',
  ),
  'Massachusetts Institute of Technology (MIT)': UniversityProfile(
    introduction: 'Universitas riset di Cambridge, Massachusetts, dengan pendekatan belajar yang kuat pada sains, teknologi, rekayasa, dan inovasi.',
    studyAreas: 'Ilmu komputer, teknik, sains, dan ekonomi',
    monthlyLivingCost: 'US\$2.500–US\$4.000',
  ),
  'Imperial College London': UniversityProfile(
    introduction: 'Universitas di London yang berfokus pada sains, teknik, kedokteran, dan bisnis, dengan kedekatan pada ekosistem riset dan industri.',
    studyAreas: 'Teknik, kedokteran, sains, dan bisnis',
    monthlyLivingCost: '£1.500–£2.400',
  ),
  'Stanford University': UniversityProfile(
    introduction: 'Universitas riset di California dengan kampus luas dan ekosistem kewirausahaan serta teknologi di kawasan Silicon Valley.',
    studyAreas: 'Ilmu komputer, teknik, bisnis, dan ilmu hayati',
    monthlyLivingCost: 'US\$2.500–US\$4.200',
  ),
  'Harvard University': UniversityProfile(
    introduction: 'Universitas riset di Cambridge, Massachusetts, dengan pilihan bidang studi luas dan akses ke perpustakaan serta institusi akademik.',
    studyAreas: 'Hukum, bisnis, kedokteran, kebijakan publik, dan sains',
    monthlyLivingCost: 'US\$2.500–US\$4.000',
  ),
  'University of Oxford': UniversityProfile(
    introduction: 'Universitas riset di kota Oxford dengan sistem perguruan tinggi (collegiate) dan pilihan program lintas bidang.',
    studyAreas: 'Humaniora, ilmu politik, kedokteran, dan sains',
    monthlyLivingCost: '£1.300–£2.000',
  ),
  'University of Cambridge': UniversityProfile(
    introduction: 'Universitas riset di Cambridge dengan sistem collegiate, komunitas akademik yang erat, dan tradisi pembelajaran lintas disiplin.',
    studyAreas: 'Sains, teknik, matematika, humaniora, dan kedokteran',
    monthlyLivingCost: '£1.200–£1.900',
  ),
  'ETH Zurich': UniversityProfile(
    introduction: 'Universitas sains dan teknologi di Zurich yang menggabungkan pendidikan, riset, dan kerja sama dengan komunitas ilmiah global.',
    studyAreas: 'Teknik, ilmu komputer, arsitektur, dan sains alam',
    monthlyLivingCost: 'CHF 1.800–CHF 2.800',
  ),
  'National University of Singapore (NUS)': UniversityProfile(
    introduction: 'Universitas riset komprehensif di Singapura dengan komunitas internasional dan pilihan program yang luas.',
    studyAreas: 'Teknik, komputasi, bisnis, dan ilmu hayati',
    monthlyLivingCost: 'S\$1.500–S\$3.000',
  ),
  'University College London (UCL)': UniversityProfile(
    introduction: 'Universitas riset multidisiplin di London yang menawarkan beragam program dan berada dekat dengan pusat budaya serta riset kota.',
    studyAreas: 'Arsitektur, pendidikan, kedokteran, dan ilmu sosial',
    monthlyLivingCost: '£1.500–£2.400',
  ),
  'California Institute of Technology (Caltech)': UniversityProfile(
    introduction: 'Institusi riset di Pasadena dengan fokus kuat pada sains dan rekayasa serta lingkungan akademik yang berorientasi riset.',
    studyAreas: 'Fisika, kimia, biologi, ilmu komputer, dan rekayasa',
    monthlyLivingCost: 'US\$2.000–US\$3.500',
  ),
  'The University of Hong Kong (HKU)': UniversityProfile(
    introduction: 'Universitas riset di Hong Kong dengan lingkungan belajar internasional dan program lintas disiplin.',
    studyAreas: 'Kedokteran, hukum, bisnis, dan ilmu sosial',
    monthlyLivingCost: 'HK\$12.000–HK\$22.000',
  ),
  'Nanyang Technological University (NTU)': UniversityProfile(
    introduction: 'Universitas riset di Singapura dengan kampus yang luas dan program dalam sains, teknologi, bisnis, serta humaniora.',
    studyAreas: 'Teknik, ilmu material, bisnis, dan komunikasi',
    monthlyLivingCost: 'S\$1.400–S\$2.800',
  ),
  'Peking University': UniversityProfile(
    introduction: 'Universitas riset di Beijing dengan cakupan bidang studi yang luas dan lingkungan akademik yang menghubungkan tradisi serta riset modern.',
    studyAreas: 'Humaniora, ilmu sosial, sains, dan kedokteran',
    monthlyLivingCost: '¥5.000–¥9.000',
  ),
  'Tsinghua University': UniversityProfile(
    introduction: 'Universitas riset di Beijing dengan kekuatan di bidang teknologi dan rekayasa, serta program di ilmu sosial dan humaniora.',
    studyAreas: 'Teknik, ilmu komputer, arsitektur, dan bisnis',
    monthlyLivingCost: '¥5.000–¥9.000',
  ),
  'The Chinese University of Hong Kong (CUHK)': UniversityProfile(
    introduction: 'Universitas riset di Hong Kong dengan kampus di Sha Tin dan program yang mencakup sains, humaniora, bisnis, serta kesehatan.',
    studyAreas: 'Bisnis, kedokteran, komunikasi, dan ilmu sosial',
    monthlyLivingCost: 'HK\$10.000–HK\$20.000',
  ),
  'UNSW Sydney': UniversityProfile(
    introduction: 'Universitas riset di Sydney yang menawarkan program lintas disiplin dan terhubung dengan pusat industri serta komunitas kota.',
    studyAreas: 'Teknik, bisnis, hukum, dan ilmu komputer',
    monthlyLivingCost: 'A\$2.000–A\$3.500',
  ),
  'Johns Hopkins University': UniversityProfile(
    introduction: 'Universitas riset di Baltimore dengan keterkaitan kuat antara pembelajaran akademik, riset, dan layanan kesehatan.',
    studyAreas:
        'Kesehatan masyarakat, kedokteran, hubungan internasional, dan sains',
    monthlyLivingCost: 'US\$1.800–US\$3.000',
  ),
  'University of California, Berkeley': UniversityProfile(
    introduction: 'Universitas publik riset di Berkeley, California, dengan komunitas akademik aktif dan beragam program studi.',
    studyAreas: 'Ilmu komputer, teknik, bisnis, dan ilmu sosial',
    monthlyLivingCost: 'US\$2.500–US\$4.000',
  ),
  'Technical University of Munich (TUM)': UniversityProfile(
    introduction: 'Universitas riset dan teknologi di Munich yang menghubungkan sains, rekayasa, kewirausahaan, dan industri.',
    studyAreas: 'Teknik, informatika, sains alam, dan kedokteran',
    monthlyLivingCost: '€1.200–€1.900',
  ),
  'Yale University': UniversityProfile(
    introduction: 'Universitas riset di New Haven dengan pendidikan multidisiplin, komunitas collegiate, serta koleksi perpustakaan dan seni.',
    studyAreas: 'Hukum, seni dan humaniora, ilmu sosial, dan kedokteran',
    monthlyLivingCost: 'US\$1.800–US\$3.000',
  ),
  'Cornell University': UniversityProfile(
    introduction: 'Universitas riset di Ithaca, New York, dengan beragam fakultas dan suasana kampus yang berada di kota perguruan tinggi.',
    studyAreas: 'Teknik, pertanian, bisnis, ilmu komputer, dan perhotelan',
    monthlyLivingCost: 'US\$1.500–US\$2.600',
  ),
  'University of Pennsylvania': UniversityProfile(
    introduction: 'Universitas riset di Philadelphia dengan pilihan program luas dan kolaborasi lintas bidang, termasuk bisnis dan kesehatan.',
    studyAreas: 'Bisnis, kedokteran, hukum, teknik, dan ilmu sosial',
    monthlyLivingCost: 'US\$2.000–US\$3.200',
  ),
};
