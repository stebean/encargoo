enum UserRole { owner, member }

class UserEntity {
  final String id;
  final String email;
  final String fullName;
  final String? workspaceId;
  final UserRole role;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.workspaceId,
    this.role = UserRole.member,
  });

  bool get isOwner => role == UserRole.owner;
  bool get canDelete => role == UserRole.owner;
}
