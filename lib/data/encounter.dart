class Encounter {
  final int playerIdW;
  final int playerIdB;
  String result;

  Encounter({
    required this.playerIdW,
    required this.playerIdB,
    this.result = '',
  });

  Map<String, dynamic> toJson() => {
    'w': playerIdW,
    'b': playerIdB,
    'result': result,
  };

  factory Encounter.fromJson(Map<String, dynamic> json) {
    return Encounter(
      playerIdW: json['w'],
      playerIdB: json['b'],
      result: json['result'],
    );
  }
}
