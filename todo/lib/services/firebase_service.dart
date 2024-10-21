import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth methods
  Future<User?> signUpWithEmailAndPassword(String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await createUser(user, role);
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await updateUserLastLogin(user.uid);
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult = await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null) {
          // Check if the user already exists in Firestore
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (!userDoc.exists) {
            // If the user doesn't exist, create a new document for them
            await createUser(user, 'developer'); // Default role as 'developer'
          }
          await updateUserLastLogin(user.uid);
        }

        return user;
      }
    } catch (error) {
      print(error);
      return null;
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User operations
  Future<void> createUser(User user, String role) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.email?.split('@')[0],
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserLastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // Project operations
  Future<String> createProject(String name, String description, String createdBy) async {
    DocumentReference projectRef = await _firestore.collection('projects').add({
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'members': [createdBy],
    });

    // Update user_projects
    await _firestore.collection('user_projects').doc(createdBy).set({
      'projects': FieldValue.arrayUnion([projectRef.id]),
    }, SetOptions(merge: true));

    return projectRef.id;
  }

  Future<void> addUserToProject(String projectId, String userId) async {
    await _firestore.collection('projects').doc(projectId).update({
      'members': FieldValue.arrayUnion([userId]),
    });

    await _firestore.collection('user_projects').doc(userId).set({
      'projects': FieldValue.arrayUnion([projectId]),
    }, SetOptions(merge: true));
  }

  // Task operations
  Future<String> createTask(String projectId, String title, String description, String createdBy, String assignedTo) async {
    DocumentReference taskRef = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .add({
      'title': title,
      'description': description,
      'status': 'todo',
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update user_tasks
    await _firestore.collection('user_tasks').doc(assignedTo).set({
      'tasks': FieldValue.arrayUnion([
        {'projectId': projectId, 'taskId': taskRef.id}
      ]),
    }, SetOptions(merge: true));

    return taskRef.id;
  }

  Future<void> updateTaskStatus(String projectId, String taskId, String status) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Fetching data
  Stream<QuerySnapshot> getUserProjects(String userId) {
    return _firestore
        .collection('projects')
        .where('members', arrayContains: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> getProjectTasks(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserTasks(String userId) {
    return _firestore
        .collection('user_tasks')
        .doc(userId)
        .snapshots();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user data
  Future<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }
}