import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDatabase {
  static const String defaultOutfitId = 'default';
  static const String royalOutfitId = 'royal_set';
  static const String maidOutfitId = 'maid_set';
  static const String clownOutfitId = 'clown_set';

  static const String defaultModelPath = 'assets/models/TrashGO_BaseModel.glb';
  static const String royalModelPath = 'assets/models/Set_Royal.glb';
  static const String maidModelPath = 'assets/models/Maid_SET.glb';
  static const String clownModelPath = 'assets/models/Clown_SET.glb';

  static const String defaultPreviewPath = 'assets/models/TrashGO_BaseModel.png';
  static const String royalPreviewPath = 'assets/models/Set_Royal.png';
  static const String maidPreviewPath = 'assets/models/Maid_SET.png';
  static const String clownPreviewPath = 'assets/models/Clown_SET.png';

  static const Set<String> validOutfitIds = {
    defaultOutfitId,
    royalOutfitId,
    maidOutfitId,
    clownOutfitId,
  };

  static const Set<String> validModelPaths = {
    defaultModelPath,
    royalModelPath,
    maidModelPath,
    clownModelPath,
  };

  static const Set<String> validPreviewPaths = {
    defaultPreviewPath,
    royalPreviewPath,
    maidPreviewPath,
    clownPreviewPath,
  };

  static String previewPathForOutfit(String outfitId) {
    switch (outfitId) {
      case royalOutfitId:
        return royalPreviewPath;
      case maidOutfitId:
        return maidPreviewPath;
      case clownOutfitId:
        return clownPreviewPath;
      case defaultOutfitId:
      default:
        return defaultPreviewPath;
    }
  }

  static String modelPathForOutfit(String outfitId) {
    switch (outfitId) {
      case royalOutfitId:
        return royalModelPath;
      case maidOutfitId:
        return maidModelPath;
      case clownOutfitId:
        return clownModelPath;
      case defaultOutfitId:
      default:
        return defaultModelPath;
    }
  }

  static String characterNameForOutfit(String outfitId) {
    switch (outfitId) {
      case royalOutfitId:
        return 'Set Royal';
      case maidOutfitId:
        return 'Maid Set';
      case clownOutfitId:
        return 'Clown Set';
      case defaultOutfitId:
      default:
        return 'Default Character';
    }
  }

  static String displayCharacterName(String value, {String? outfitId}) {
    final clean = value.trim();

    if (outfitId == defaultOutfitId ||
        clean.isEmpty ||
        clean == 'Default_Char' ||
        clean == 'Default Char' ||
        clean == 'default_char') {
      return 'Default Character';
    }

    return clean.replaceAll('_', ' ');
  }

  static Map<String, dynamic> initialUserData({
    required String uid,
    required String fullName,
    required String email,
  }) {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'characterName': 'Default Character',
      'points': 0,
      'level': 1,
      'xp': 0,
      'maxXp': 200,
      'rank': '-',
      'streakDays': 0,
      'totalScans': 0,
      'unlockedItems': <String, dynamic>{},
      'ownedOutfits': <String, dynamic>{
        defaultOutfitId: true,
      },
      'selectedOutfitId': defaultOutfitId,
      'selectedOutfitModel': defaultModelPath,
      'selectedOutfitPreview': defaultPreviewPath,
      'lastScanTrash': '',
      'lastScanTrashName': '',
      'lastScanCategory': '',
      'activeDates': <String, dynamic>{},
      'completedMissions': <String, dynamic>{},
      'missionProgress': <String, dynamic>{},
      'lastActiveDate': '',
      'lastMissionDate': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<void> ensureUserDocument(User user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    final defaultData = initialUserData(
      uid: user.uid,
      fullName: user.displayName ?? 'TrashGo User',
      email: user.email ?? '',
    );

    if (!snapshot.exists) {
      await userRef.set(defaultData);
      return;
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final updateData = <String, dynamic>{};

    for (final entry in defaultData.entries) {
      if (!data.containsKey(entry.key) || data[entry.key] == null) {
        updateData[entry.key] = entry.value;
      }
    }

    final selectedOutfitId = (data['selectedOutfitId'] ?? defaultOutfitId).toString();
    final selectedOutfitModel = (data['selectedOutfitModel'] ?? defaultModelPath).toString();
    final selectedOutfitPreview = (data['selectedOutfitPreview'] ?? defaultPreviewPath).toString();

    if (!validOutfitIds.contains(selectedOutfitId) ||
        !validModelPaths.contains(selectedOutfitModel) ||
        !validPreviewPaths.contains(selectedOutfitPreview)) {
      updateData['selectedOutfitId'] = defaultOutfitId;
      updateData['selectedOutfitModel'] = defaultModelPath;
      updateData['selectedOutfitPreview'] = defaultPreviewPath;
      updateData['characterName'] = 'Default Character';
    }

    final ownedOutfits = Map<String, dynamic>.from(data['ownedOutfits'] ?? {});
    if (ownedOutfits[defaultOutfitId] != true) {
      ownedOutfits[defaultOutfitId] = true;
      updateData['ownedOutfits'] = ownedOutfits;
    }

    final currentCharacterName = (data['characterName'] ?? '').toString();
    if (currentCharacterName == 'Default_Char' ||
        currentCharacterName == 'Default Char' ||
        currentCharacterName == 'default_char') {
      updateData['characterName'] = 'Default Character';
    }

    updateData['updatedAt'] = FieldValue.serverTimestamp();

    if (updateData.isNotEmpty) {
      await userRef.set(updateData, SetOptions(merge: true));
    }
  }
}
