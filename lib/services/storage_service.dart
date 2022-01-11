import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:real_time_chatapp/utilities/constant.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  Future<File> _compressImage(String imageId, File image) async {
    final tempDir = await getTemporaryDirectory();
    //local file system in each person device
    final path = tempDir.path;
    File compressedImageFile = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path, '$path/img_$imageId.jpg',
        quality: 70);
    return compressedImageFile;
  }

  Future<String> _uploadImage(String path, String imageId, File image) async {
    UploadTask uploadTask = storageRef.child(path).putFile(image);
    TaskSnapshot storageSnap = await uploadTask.whenComplete(() => null);
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

//Uuid will give us the random alpha numeric string
  Future<String> uploadChatImage(String url, File imageFile) async {
    String imageId = const Uuid().v4();
    File image = await _compressImage(imageId, imageFile);

    if (url != null) {
      RegExp exp = RegExp(r'chat_(.*).jpg');
      imageId = exp.firstMatch(url)[1];
    }

    String downloadUrl = await _uploadImage(
      'images/chats/chat_$imageId.jpg',
      imageId,
      image,
    );
    return downloadUrl;
  }

  Future<String> uploadMessageImage(File imageFile) async {
    String imageId = const Uuid().v4();
    File image = await _compressImage(imageId, imageFile);
    String downloadUrl = await _uploadImage(
      'images/messages/message_$imageId.jpg',
      imageId,
      image,
    );
    return downloadUrl;
  }
}
