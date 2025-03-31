import 'package:dartz/dartz.dart';
import 'package:fit_track_app/data/core/usecase/usecase.dart';
import 'package:fit_track_app/data/models/auth/create_user_req.dart';
import 'package:fit_track_app/domain/repository/auth/auth.dart';
import 'package:fit_track_app/service_locator.dart';

class SignupUseCase implements UseCase<Either, CreateUserReq> {
  @override
  Future<Either> call({CreateUserReq? params}) async {
    return sl<AuthRepository>().signup(params!);
  }
}
