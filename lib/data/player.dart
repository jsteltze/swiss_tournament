class Player {
  String name;
  int rating;
  final int joinedAt;
  int? leftAt;

  Player({required this.name, required this.rating, int? joinedAt})
    : joinedAt = joinedAt ?? 0;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (rating != 0) 'rating': rating,
    if (joinedAt != 0) 'joinedAt': joinedAt,
    if (leftAt != null) 'leftAt': leftAt,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    var p = Player(
      name: json['name'],
      rating: json['rating'] ?? 0,
      joinedAt: json['joinedAt'] ?? 0,
    );
    if (json['leftAt'] != null) {
      p.leftAt = json['leftAt'];
    }
    return p;
  }
}
