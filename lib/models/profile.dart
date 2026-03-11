import 'package:equatable/equatable.dart';

/// User profile from Supabase (profiles table).
class Profile extends Equatable {
  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, displayName, avatarUrl, createdAt, updatedAt];

  static Profile fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
