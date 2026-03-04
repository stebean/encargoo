import '../../domain/entities/workspace_entity.dart';

class WorkspaceModel extends WorkspaceEntity {
  const WorkspaceModel({
    required super.id,
    required super.name,
    required super.accessCode,
    required super.createdAt,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      accessCode: json['access_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
