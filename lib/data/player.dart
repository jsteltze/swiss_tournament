class Player {
  final String name;
  final int rating;

  Player({required this.name, required this.rating});

  Map<String, dynamic> toJson() => {
    'name': name,
    'rating': rating,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      rating: json['rating'],
    );
  }
}
