import 'package:fit_track_app/data/core/usecase/auth/signup.dart';
import 'package:fit_track_app/data/repository/auth/auth_repository_impl.dart';
import 'package:fit_track_app/data/sources/auth/auth_firebase_service.dart';
import 'package:fit_track_app/domain/repository/auth/auth.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  sl.registerSingleton<AuthFirebaseService>(AuthFirebaseServiceImpl());

  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());

  sl.registerSingleton<SignupUseCase>(SignupUseCase());
}
