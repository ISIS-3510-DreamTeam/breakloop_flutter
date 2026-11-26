import 'dart:typed_data';

import '../model/profile_model.dart';
import 'profile_photo_compressor.dart';
import 'profile_remote_datasource.dart';

/// Repository that manages the user's profile and the profiles of friends.
class ProfileRepository {
  final ProfileRemoteDatasource _remoteDatasource;
  final ProfilePhotoCompressor _photoCompressor;

  // Uses the provided dependencies or creates the default ones
  ProfileRepository({
    ProfileRemoteDatasource? remoteDatasource,
    ProfilePhotoCompressor? photoCompressor,
  })  : _remoteDatasource = remoteDatasource ?? ProfileRemoteDatasource(),
        _photoCompressor = photoCompressor ?? ProfilePhotoCompressor();

  // Gets the profile of any user (own or friend)
  Future<ProfileModel> getProfile(String uid) =>
      _remoteDatasource.fetchProfile(uid);

  // Emits the profile again every time it changes in Firestore
  Stream<ProfileModel> watchProfile(String uid) =>
      _remoteDatasource.watchProfile(uid);

  // Crops and compresses the photo picked from the camera or gallery
  Future<Uint8List> compressPhoto(Uint8List bytes) =>
      _photoCompressor.compress(bytes);

  // Uploads the compressed photo and returns its URL
  Future<String> uploadPhoto(String uid, Uint8List photo) =>
      _remoteDatasource.uploadPhoto(uid, photo);

  // Changes the name of the user
  Future<void> updateDisplayName(String uid, String displayName) =>
      _remoteDatasource.updateDisplayName(uid, displayName);
}
