import 'package:dartz/dartz.dart';
import 'package:fit_track_app/data/models/auth/create_user_req.dart';
import 'package:fit_track_app/data/sources/auth/auth_firebase_service.dart';
import 'package:fit_track_app/domain/repository/auth/auth.dart';
import 'package:fit_track_app/service_locator.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<void> signin() {
    // TODO: implement signIn
    throw UnimplementedError();
  }

  @override
  Future<Either> signup(CreateUserReq createUserReq) async {
    return await sl<AuthFirebaseService>().signup(createUserReq);
  }
}
