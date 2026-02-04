enum FirstRoundPairing {
  white1(
    displayName: 'White',
    javaFoCode: 'XXC white1',
    description: 'The highest rated player will get white in the first round.',
  ),
  black1(
    displayName: 'Black',
    javaFoCode: 'XXC black1',
    description: 'The highest rated player will get black in the first round.',
  ),
  random(
    displayName: 'Random',
    javaFoCode: '',
    description:
        'Let the pairing engine (JaVaFo) decide the first round. This is the default. Beware that it is a semi-random choice: to compute it, JaVaFo uses the hash of some data taken from the tournament data. This means that repeating the process with the exact same tournament will give the same result each time.',
  );

  const FirstRoundPairing({
    required this.displayName,
    required this.javaFoCode,
    required this.description,
  });

  final String displayName;
  final String javaFoCode;
  final String description;
}
