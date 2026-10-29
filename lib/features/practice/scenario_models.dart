class Scenario {
  const Scenario({
    required this.topic,
    required this.situation,
    required this.challenge,
    this.situationEn,
    this.challengeEn,
  });

  final String topic;
  final String situation;
  final String challenge;
  /// English originals for evaluation — avoids a slow reverse-translate.
  final String? situationEn;
  final String? challengeEn;
}
