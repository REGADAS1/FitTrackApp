import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/data/models/auth/create_user_req.dart';

abstract class AuthFirebaseService {
  Future<Either> signup(CreateUserReq createUserReq);
  Future<void> signin();
}

class AuthFirebaseServiceImpl extends AuthFirebaseService {
  @override
  Future<Either> signup(CreateUserReq createUserReq) async {
    try {
      // Simulate a network call
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: createUserReq.email,
        password: createUserReq.password,
      );
      return Right('User signed up successfully'); // Return success
    } on FirebaseAuthException catch (e) {
      String message = '';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already in use';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          message = 'Operation not allowed';
          break;
        case 'weak-password':
          message = 'Weak password';
          break;
        default:
          message = 'An unknown error occurred';
      }

      return Left(message);
    }
  }

  @override
  Future<void> signin() {
    throw UnimplementedError();
  }
}
