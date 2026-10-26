import 'package:flutter_test/flutter_test.dart';
import 'package:studytrip/data/universities.dart';
import 'package:studytrip/data/university_profiles.dart';

void main() {
  test('setiap kampus punya profil detail dan perkiraan biaya hidup', () {
    expect(
      kUniversityProfiles.keys.toSet(),
      kUniversities.map((university) => university.name).toSet(),
    );

    for (final university in kUniversities) {
      final profile = kUniversityProfiles[university.name]!;
      expect(profile.introduction, isNotEmpty);
      expect(profile.studyAreas, isNotEmpty);
      expect(profile.monthlyLivingCost, isNotEmpty);
    }
  });
}
