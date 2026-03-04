class ClientEntity {
  final String id;
  final String workspaceId;
  final String name;
  final String? phone;
  final String? notes;
  final DateTime createdAt;

  const ClientEntity({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.phone,
    this.notes,
    required this.createdAt,
  });
}
