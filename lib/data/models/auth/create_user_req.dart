class CreateUserReq {
  final String name;
  final String lastname;
  final String email;
  final String password;
  double? weight; // peso (em kg)
  double? height; // altura (em cm)
  String? goal; // exemplo: "emagrecer", "ganhar massa"

  CreateUserReq({
    required this.name,
    required this.lastname,
    required this.email,
    required this.password,
    this.weight,
    this.height,
    this.goal,
  });
}
