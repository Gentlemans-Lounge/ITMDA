import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String> _generateUserId(String displayName, String role) async {
    // Convert display name to lowercase and remove spaces
    String baseId = displayName.toLowerCase().replaceAll(' ', '');

    // Append 'pm' if role is project manager
    if (role == 'project_manager') {
      baseId += 'pm';
    }

    // Get all users
    QuerySnapshot query = await _firestore.collection('users').get();

    int highestId = 0;

    // Find the highest ID for users with similar role identifier
    for (var doc in query.docs) {
      String docId = doc.id;
      // For project managers, look for 'pm_' pattern
      if (role == 'project_manager' && docId.contains('pm_')) {
        // Extract the numeric part after the last underscore
        String numericPart = docId.split('_').last;
        int? currentId = int.tryParse(numericPart);
        if (currentId != null && currentId > highestId) {
          highestId = currentId;
        }
      }
      // For developers, look for IDs without 'pm_' pattern
      else if (role == 'developer' && !docId.contains('pm_')) {
        String numericPart = docId.split('_').last;
        int? currentId = int.tryParse(numericPart);
        if (currentId != null && currentId > highestId) {
          highestId = currentId;
        }
      }
    }

    // Increment the highest ID found
    int newId = highestId + 1;

    // Format new ID with padding (e.g., 001, 002)
    String formattedId = newId.toString().padLeft(3, '0');

    return '${baseId}_$formattedId';
  }

  // Helper function to check if user exists in Firestore
  Future<DocumentSnapshot?> _checkUserExists(String email) async {
    QuerySnapshot query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }

  // Sign in with email
  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    try {
      // First check if user exists in Firestore
      DocumentSnapshot? userDoc = await _checkUserExists(email);
      if (userDoc == null) {
        return {
          'success': false,
          'message': 'No account found with this email',
          'needsRegistration': true
        };
      }

      // Attempt Firebase Auth sign in
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await updateUserLastLogin(userDoc.id);
        return {
          'success': true,
          'user': result.user,
          'userData': userDoc.data()
        };
      }

      return {
        'success': false,
        'message': 'Sign in failed'
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  // Sign up with email
  Future<Map<String, dynamic>> signUpWithEmailAndPassword(
      String email,
      String password,
      String displayName,
      String role
      ) async {
    try {
      // Check if user already exists
      DocumentSnapshot? existingUser = await _checkUserExists(email);
      if (existingUser != null) {
        return {
          'success': false,
          'message': 'An account with this email already exists'
        };
      }

      // Create auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Generate proper document ID
        String docId = await _generateUserId(displayName, role);

        // Create user document
        await _firestore.collection('users').doc(docId).set({
          'email': email,
          'displayName': displayName,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'user': result.user,
          'userData': {
            'displayName': displayName,
            'role': role,
            'email': email
          }
        };
      }

      return {
        'success': false,
        'message': 'Registration failed'
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
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
          // Check if user exists in Firestore
          DocumentSnapshot? existingUser = await _checkUserExists(user.email!);

          if (existingUser != null) {
            // Existing user - normal sign in
            await updateUserLastLogin(existingUser.id);
            return {
              'success': true,
              'user': user,
              'userData': existingUser.data(),
              'isNewUser': false
            };
          } else {
            // New user - needs to complete registration
            return {
              'success': true,
              'user': user,
              'needsRegistration': true,
              'isNewUser': true,
              'email': user.email
            };
          }
        }
      }

      return {
        'success': false,
        'message': 'Google sign in failed'
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  // Complete Google Sign Up (called after user provides additional details)
  Future<Map<String, dynamic>> completeGoogleSignUp(
      User user,
      String displayName,
      String role
      ) async {
    try {
      String docId = await _generateUserId(displayName, role);

      await _firestore.collection('users').doc(docId).set({
        'email': user.email,
        'displayName': displayName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'user': user,
        'userData': {
          'displayName': displayName,
          'role': role,
          'email': user.email
        }
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
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

  Future<String?> getUserDocumentId(String? email) async {
    if (email == null) return null;

    final usersQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (usersQuery.docs.isNotEmpty) {
      return usersQuery.docs.first.id;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserDetailsByEmail(String? email) async {
    if (email == null) return null;

    final usersQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (usersQuery.docs.isNotEmpty) {
      return {
        'id': usersQuery.docs.first.id,
        'data': usersQuery.docs.first.data(),
      };
    }
    return null;
  }

  Future<int> getUserTaskCount(String userId) async {
    final userTasksDoc = await _firestore
        .collection('user_tasks')
        .doc(userId)
        .get();

    if (userTasksDoc.exists) {
      final tasks = userTasksDoc.data()?['tasks'] as List<dynamic>?;
      return tasks?.length ?? 0;
    }
    return 0;
  }

  Future<Map<String, dynamic>?> getTaskDetails(String projectId, String taskId) async {
    final taskDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .get();

    if (taskDoc.exists) {
      return taskDoc.data();
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProjectDetails(String projectId) async {
    final projectDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .get();

    if (projectDoc.exists) {
      return projectDoc.data();
    }
    return null;
  }

  Stream<DocumentSnapshot> streamTaskDetails(String projectId, String taskId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .snapshots()
        .map((doc) {
      return doc;
    });
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