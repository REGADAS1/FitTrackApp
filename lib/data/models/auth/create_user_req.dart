class CreateUserReq {
  final String name;
  final String lastname;
  final String email;
  final String password;

  CreateUserReq({
    required this.name,
    required this.lastname,
    required this.email,
    required this.password,
  });
}
