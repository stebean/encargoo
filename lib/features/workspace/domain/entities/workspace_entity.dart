class WorkspaceEntity {
  final String id;
  final String name;
  final String accessCode;
  final DateTime createdAt;

  const WorkspaceEntity({
    required this.id,
    required this.name,
    required this.accessCode,
    required this.createdAt,
  });
}
