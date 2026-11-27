import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../model/profile_model.dart';

// Handles the communication with Firestore and Storage for profiles.
class ProfileRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  // Reads go to the server so offline errors are not hidden by Firestore's own cache
  static const GetOptions _serverOnly = GetOptions(source: Source.server);

  // Uses the provided instances or the default ones.
  ProfileRemoteDatasource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Gets the user's name, photo, friend code, streak and pet level.
  Future<ProfileModel> fetchProfile(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);

    // Read the profile and the progress at the same time
    final docs = await Future.wait([
      userRef.get(_serverOnly),
      userRef.collection('progress').doc('current').get(_serverOnly),
    ]);

    return ProfileModel.fromFirestore(
      uid: uid,
      profile: docs[0].data() ?? {},
      progress: docs[1].data() ?? {},
    );
  }

  // Emits the profile every time the name, photo, streak or pet level changes.
  Stream<ProfileModel> watchProfile(String uid) {
    final userRef = _firestore.collection('users').doc(uid);
    final progressRef = userRef.collection('progress').doc('current');

    // The profile needs both documents, so the last data of each one is kept
    Map<String, dynamic>? profile;
    Map<String, dynamic>? progress;
    final subscriptions = <StreamSubscription>[];
    late final StreamController<ProfileModel> controller;

    void emit() {
      if (profile == null || progress == null) return;
      controller.add(ProfileModel.fromFirestore(
        uid: uid,
        profile: profile!,
        progress: progress!,
      ));
    }

    controller = StreamController<ProfileModel>(
      // Start listening to Firestore only when someone listens to the profile
      onListen: () {
        // Snapshots from Firestore's own cache are skipped: offline they can be
        // empty and would replace the saved profile. Firestore sends the
        // server data by itself when the connection comes back. Metadata changes
        // are included so the server copy arrives even if it equals the cached one
        subscriptions.add(userRef.snapshots(includeMetadataChanges: true).listen((doc) {
          if (doc.metadata.isFromCache) return;
          profile = doc.data() ?? {};
          emit();
        }, onError: controller.addError));
        subscriptions.add(progressRef.snapshots(includeMetadataChanges: true).listen((doc) {
          if (doc.metadata.isFromCache) return;
          progress = doc.data() ?? {};
          emit();
        }, onError: controller.addError));
      },
      // Stop listening to Firestore when the screen is closed
      onCancel: () => Future.wait(subscriptions.map((s) => s.cancel())),
    );

    return controller.stream;
  }

  // Saves the new display name of the user.
  Future<void> updateDisplayName(String uid, String displayName) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'displayName': displayName});
    // Also in Firebase Auth, so the rest of the app (Home) shows the new name
    await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
  }

  // Uploads the photo, saves its URL in the profile and returns it.
  Future<String> uploadPhoto(String uid, Uint8List photo) async {
    final photoRef = _storage.ref('profile_photos/$uid.jpg');
    await photoRef.putData(photo, SettableMetadata(contentType: 'image/jpeg'));

    final photoUrl = await photoRef.getDownloadURL();
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'photoUrl': photoUrl});
    return photoUrl;
  }
}
