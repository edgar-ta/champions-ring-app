import 'package:champions_ring_app/core/result.dart';
import 'package:champions_ring_app/features/authentication/enums/user_register_failure.dart';
import 'package:champions_ring_app/features/authentication/models/register_user_data.dart';
import 'package:champions_ring_app/features/authentication/models/user.dart';

abstract class UserRepository {
  Future<Result<User, UserRegisterFailure>> registerUser(RegisterUserData data);
}
