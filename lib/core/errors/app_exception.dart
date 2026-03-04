abstract class AppException {
  final String message;
  const AppException(this.message);
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

class StorageException extends AppException {
  const StorageException(super.message);
}

class WorkspaceException extends AppException {
  const WorkspaceException(super.message);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión a internet']);
}
