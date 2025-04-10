import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fit_track_app/data/models/auth/create_user_req.dart';

abstract class AuthFirebaseService {
  Future<Either<String, String>> signup(CreateUserReq createUserReq);
  Future<void> signin();
}

class AuthFirebaseServiceImpl extends AuthFirebaseService {
  @override
  Future<Either<String, String>> signup(CreateUserReq createUserReq) async {
    try {
      // Criar utilizador no Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: createUserReq.email,
            password: createUserReq.password,
          );

      // Obter UID do utilizador
      final uid = userCredential.user?.uid;

      if (uid == null) {
        return Left('Erro ao obter UID do utilizador');
      }

      // Criar documento no Firestore (coleção "users")
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': createUserReq.name,
        'lastName': createUserReq.lastname,
        'email': createUserReq.email,
        'createdAt': Timestamp.now(),
      });

      return Right('Utilizador registado com sucesso');
    } on FirebaseAuthException catch (e) {
      String message = '';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email já está em uso';
          break;
        case 'invalid-email':
          message = 'Email inválido';
          break;
        case 'operation-not-allowed':
          message = 'Operação não permitida';
          break;
        case 'weak-password':
          message = 'Password fraca';
          break;
        default:
          message = 'Ocorreu um erro desconhecido';
      }

      return Left(message);
    } catch (e) {
      return Left('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<void> signin() {
    throw UnimplementedError();
  }
}
