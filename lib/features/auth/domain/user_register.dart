class UserRegister {
  final String email;
  final String fullName;
  final String password;
  final int academicProgramId;

  UserRegister({
    required this.email,
    required this.fullName,
    required this.password,
    required this.academicProgramId,
  });

  Map<String, dynamic> toJson() => {
        "email": email,
        "full_name": fullName,
        "password": password,
        "programa_academico_id": academicProgramId,
      };
}