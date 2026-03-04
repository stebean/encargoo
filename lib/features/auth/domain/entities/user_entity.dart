class UserEntity {
  final String id;
  final String email;
  final String fullName;
  final String? workspaceId;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.workspaceId,
  });
}
