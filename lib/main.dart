// SocialApp — Firebase Auth • Firestore • رسائل مشفرة E2EE • صور بالخاص
// كل شيء حقيقي من قاعدة البيانات، لا توجد بيانات وهمية.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart' as cg;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

// ═════════════════════════ الإعدادات ═════════════════════════

class AppConfig {
  /// خذ القيم من google-services.json
  static const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: 'PASTE_API_KEY', // current_key → api_key
    appId: 'PASTE_APP_ID', // mobilesdk_app_id
    messagingSenderId: 'PASTE_SENDER_ID', // project_number
    projectId: 'PASTE_PROJECT_ID', // project_id
  );

  /// اسم مستخدم حساب الإدارة (سوّ حساب بهذا الاسم داخل التطبيق)
  static const String adminUsername = 'admin';

  static bool get firebaseConfigured =>
      !firebaseOptions.apiKey.startsWith('PASTE');
}

// ═════════════════════════ التشغيل ═════════════════════════

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;
  if (!AppConfig.firebaseConfigured) {
    initError = 'لم تضع إعدادات Firebase داخل AppConfig في أعلى الملف.';
  } else {
    try {
      await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    } catch (e) {
      initError = 'تعذّر تشغيل Firebase: $e';
    }
  }
  runApp(SocialApp(initError: initError));
}

// ═════════════════════════ الثيم ═════════════════════════

class AppTheme {
  static const Color bg = Colors.black;
  static const Color surfaceAlt = Color(0xFF262626);
  static const Color border = Color(0xFF2A2A2A);
  static const Color primary = Color(0xFF0095F6);
  static const Color textMuted = Color(0xFFA8A8A8);
  static const Color like = Color(0xFFFF3040);

  static const LinearGradient storyGradient = LinearGradient(
    colors: [
      Color(0xFFFEDA75),
      Color(0xFFFA7E1E),
      Color(0xFFD62976),
      Color(0xFF962FBF),
      Color(0xFF4F5BD5),
    ],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const List<List<Color>> palettes = [
    [Color(0xFFFEDA75), Color(0xFFD62976)],
    [Color(0xFF4F5BD5), Color(0xFF962FBF)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFF512F), Color(0xFFDD2476)],
    [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
  ];

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          surface: bg,
          error: like,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

// ═════════════════════════ أدوات مساعدة ═════════════════════════

class AppError implements Exception {
  final String message;
  AppError(this.message);
  @override
  String toString() => message;
}

String friendlyError(Object e) {
  if (e is AppError) return e.message;
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'صيغة الإيميل غير صحيحة';
      case 'email-already-in-use':
        return 'تعذّر إنشاء الحساب بهذا الإيميل. سجّل الدخول أو جرّب إيميلاً آخر';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، اختر كلمة أقوى';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return 'الإيميل أو كلمة المرور غير صحيحة';
      case 'user-disabled':
        return 'تم إيقاف هذا الحساب';
      case 'too-many-requests':
        return 'محاولات كثيرة، انتظر قليلاً ثم أعد المحاولة';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      case 'requires-recent-login':
        return 'سجّل الدخول من جديد ثم أعد المحاولة';
    }
    return 'خطأ في الحساب (${e.code})';
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return 'ليس لديك صلاحية لهذا الإجراء (تأكد من نشر قواعد Firestore)';
    }
    if (e.code == 'unavailable') return 'تحقق من اتصال الإنترنت';
    return 'خطأ في الخادم (${e.code})';
  }
  return 'حدث خطأ غير متوقع';
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String body,
  String confirmLabel,
) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child:
              const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: const TextStyle(color: AppTheme.like)),
        ),
      ],
    ),
  );
  return res ?? false;
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays == 1) return 'أمس';
  return 'منذ ${diff.inDays} يوم';
}

int hashName(String s) => s.codeUnits.fold<int>(0, (a, b) => a + b);

DateTime tsToDate(Object? ts) => ts is Timestamp ? ts.toDate() : DateTime.now();

final Map<String, Uint8List> _imgCache = {};
Uint8List decodeImg(String b64) {
  final k = '${b64.length}:${b64.hashCode}';
  final c = _imgCache[k];
  if (c != null) return c;
  if (_imgCache.length > 80) _imgCache.clear();
  final d = base64Decode(b64);
  _imgCache[k] = d;
  return d;
}

/// يختار صورة (معرض/كاميرا) ويرجعها base64 مضغوطة
Future<String?> pickImageB64(
  BuildContext context, {
  required double maxSize,
  required int quality,
  required int maxChars,
}) async {
  final src = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('من المعرض'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('من الكاميرا'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (src == null) return null;
  final x = await ImagePicker().pickImage(
    source: src,
    maxWidth: maxSize,
    maxHeight: maxSize,
    imageQuality: quality,
  );
  if (x == null) return null;
  final b64 = base64Encode(await x.readAsBytes());
  if (b64.length > maxChars) {
    throw AppError('الصورة كبيرة جداً، اختر صورة أصغر');
  }
  return b64;
}

// ═════════════════════════ النماذج ═════════════════════════

class UserProfile {
  final String uid;
  final String username;
  final String name;
  final String bio;
  final String photo;
  final String pk;

  const UserProfile({
    required this.uid,
    required this.username,
    required this.name,
    required this.bio,
    required this.photo,
    required this.pk,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) =>
      UserProfile(
        uid: uid,
        username: (m['username'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        bio: (m['bio'] ?? '') as String,
        photo: (m['photo'] ?? '') as String,
        pk: (m['pk'] ?? '') as String,
      );

  String get shownName => name.isNotEmpty ? name : username;
}

class PostData {
  final String id;
  final String authorId;
  final String authorUsername;
  final String caption;
  final String image;
  final int likes;
  final DateTime createdAt;

  const PostData({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.caption,
    required this.image,
    required this.likes,
    required this.createdAt,
  });

  factory PostData.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return PostData(
      id: d.id,
      authorId: (m['authorId'] ?? '') as String,
      authorUsername: (m['authorUsername'] ?? '') as String,
      caption: (m['caption'] ?? '') as String,
      image: (m['image'] ?? '') as String,
      likes: (m['likesCount'] as num?)?.toInt() ?? 0,
      createdAt: tsToDate(m['createdAt']),
    );
  }
}

class UserCache {
  static final Map<String, Future<UserProfile?>> _m = {};

  static Future<UserProfile?> get(String uid) =>
      _m.putIfAbsent(uid, () => _load(uid));

  static Future<UserProfile?> _load(String uid) async {
    try {
      final d = await Repo.userRef(uid).get();
      final data = d.data();
      return data == null ? null : UserProfile.fromMap(uid, data);
    } catch (_) {
      _m.remove(uid);
      return null;
    }
  }

  static void invalidate(String uid) => _m.remove(uid);
}

// ═════════════════════════ التشفير من طرف إلى طرف ═════════════════════════
// X25519 لكل مستخدم • المفتاح الخاص في التخزين الآمن للجهاز فقط
// مفتاح المحادثة = ECDH + HKDF-SHA256 • كل رسالة AES-256-GCM

class E2EE {
  static final cg.X25519 _x = cg.X25519();
  static final cg.AesGcm _aes = cg.AesGcm.with256bits();
  static const FlutterSecureStorage _store = FlutterSecureStorage();

  static cg.SimpleKeyPairData? _kp;
  static final Map<String, cg.SecretKey> _keys = {};
  static final Map<String, String> _plain = {};

  static Future<String> ensureKeys(String uid) async {
    final sk = await _store.read(key: 'sk_$uid');
    final pk = await _store.read(key: 'pk_$uid');
    if (sk != null && pk != null) {
      _kp = cg.SimpleKeyPairData(
        base64Decode(sk),
        publicKey: cg.SimplePublicKey(base64Decode(pk),
            type: cg.KeyPairType.x25519),
        type: cg.KeyPairType.x25519,
      );
      return pk;
    }
    final kp = await _x.newKeyPair();
    final priv = await kp.extractPrivateKeyBytes();
    final pub = await kp.extractPublicKey();
    final skB64 = base64Encode(priv);
    final pkB64 = base64Encode(pub.bytes);
    await _store.write(key: 'sk_$uid', value: skB64);
    await _store.write(key: 'pk_$uid', value: pkB64);
    _kp = cg.SimpleKeyPairData(
      priv,
      publicKey: cg.SimplePublicKey(pub.bytes, type: cg.KeyPairType.x25519),
      type: cg.KeyPairType.x25519,
    );
    return pkB64;
  }

  static Future<void> wipe(String uid) async {
    await _store.delete(key: 'sk_$uid');
    await _store.delete(key: 'pk_$uid');
    _kp = null;
    _keys.clear();
    _plain.clear();
  }

  static Future<cg.SecretKey> keyFor(String chatId, String otherPk) async {
    final cacheKey = '$chatId:$otherPk';
    final cached = _keys[cacheKey];
    if (cached != null) return cached;
    final kp = _kp;
    if (kp == null) throw AppError('مفاتيح التشفير غير جاهزة');
    final shared = await _x.sharedSecretKey(
      keyPair: kp,
      remotePublicKey: cg.SimplePublicKey(base64Decode(otherPk),
          type: cg.KeyPairType.x25519),
    );
    final key = await cg.Hkdf(hmac: cg.Hmac.sha256(), outputLength: 32)
        .deriveKey(
      secretKey: shared,
      nonce: utf8.encode('socialapp-e2ee-v1'),
      info: utf8.encode(chatId),
    );
    _keys[cacheKey] = key;
    return key;
  }

  static Future<String> encrypt(cg.SecretKey key, String text) async {
    final box = await _aes.encrypt(utf8.encode(text), secretKey: key);
    return base64Encode(box.concatenation());
  }

  static Future<String> decrypt(cg.SecretKey key, String cipher) async {
    final hit = _plain[cipher];
    if (hit != null) return hit;
    try {
      final box = cg.SecretBox.fromConcatenation(
        base64Decode(cipher),
        nonceLength: 12,
        macLength: 16,
      );
      final clear = await _aes.decrypt(box, secretKey: key);
      final s = utf8.decode(clear);
      if (_plain.length > 300) _plain.clear();
      _plain[cipher] = s;
      return s;
    } catch (_) {
      return '🔒 تعذّر فك تشفير الرسالة';
    }
  }
}

// ═════════════════════════ طبقة البيانات ═════════════════════════

class Repo {
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final RegExp usernameRe = RegExp(r'^[a-z0-9_.]{3,20}$');

  static final ValueNotifier<bool> busy = ValueNotifier<bool>(false);

  static String get uid => auth.currentUser!.uid;

  static DocumentReference<Map<String, dynamic>> userRef(String id) =>
      db.collection('users').doc(id);
  static CollectionReference<Map<String, dynamic>> get posts =>
      db.collection('posts');
  static DocumentReference<Map<String, dynamic>> privateRef(String id) =>
      userRef(id).collection('private').doc('info');

  static String chatId(String a, String b) =>
      a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

  // ── الحساب ──

  static Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  static Future<void> signUp(
      String email, String password, String username) async {
    final u = username.trim().toLowerCase();
    if (!usernameRe.hasMatch(u)) {
      throw AppError(
          'اسم المستخدم: من 3 إلى 20 خانة، أحرف إنجليزية صغيرة وأرقام و _ . فقط');
    }
    if (password.length < 8) {
      throw AppError('كلمة المرور يجب أن تكون 8 أحرف على الأقل');
    }
    busy.value = true;
    try {
      final cred = await auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = cred.user!;
      try {
        await createProfile(user, u);
      } catch (e) {
        try {
          await user.delete();
        } catch (_) {}
        rethrow;
      }
      try {
        await user.sendEmailVerification();
      } catch (_) {}
    } finally {
      busy.value = false;
    }
  }

  static Future<void> createProfile(User user, String username) async {
    final u = username.trim().toLowerCase();
    if (!usernameRe.hasMatch(u)) {
      throw AppError('اسم المستخدم غير صالح');
    }
    final pk = await E2EE.ensureKeys(user.uid);
    await db.runTransaction((tx) async {
      final nameRef = db.collection('usernames').doc(u);
      if ((await tx.get(nameRef)).exists) {
        throw AppError('اسم المستخدم مستخدم، اختر اسماً آخر');
      }
      tx.set(nameRef, {'uid': user.uid});
      tx.set(userRef(user.uid), {
        'username': u,
        'name': '',
        'bio': '',
        'photo': '',
        'pk': pk,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> updateProfile({
    required String name,
    required String bio,
    String? photo,
  }) async {
    final data = <String, dynamic>{'name': name.trim(), 'bio': bio.trim()};
    if (photo != null) data['photo'] = photo;
    await userRef(uid).update(data);
    UserCache.invalidate(uid);
  }

  static Future<void> savePrivate(String phone, String birth) async {
    await privateRef(uid).set({'phone': phone.trim(), 'birth': birth.trim()});
  }

  static Future<String?> uidOfUsername(String username) async {
    final d =
        await db.collection('usernames').doc(username.toLowerCase()).get();
    return d.data()?['uid'] as String?;
  }

  static Future<void> deleteAccount(String password) async {
    final user = auth.currentUser!;
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
    final me = user.uid;
    busy.value = true;
    try {
      final profile = await userRef(me).get();
      final username = profile.data()?['username'] as String?;

      final myPosts = await posts.where('authorId', isEqualTo: me).get();
      for (final d in myPosts.docs) {
        await d.reference.delete();
      }
      final following = await userRef(me).collection('following').get();
      for (final d in following.docs) {
        await userRef(d.id).collection('followers').doc(me).delete();
        await d.reference.delete();
      }
      final followers = await userRef(me).collection('followers').get();
      for (final d in followers.docs) {
        await userRef(d.id).collection('following').doc(me).delete();
        await d.reference.delete();
      }
      final saved = await userRef(me).collection('saved').get();
      for (final d in saved.docs) {
        await d.reference.delete();
      }
      await privateRef(me).delete();
      if (username != null) {
        await db.collection('usernames').doc(username).delete();
      }
      await userRef(me).delete();
      await E2EE.wipe(me);
      await user.delete();
    } finally {
      busy.value = false;
    }
  }

  // ── المتابعة ──

  static Future<void> follow(String target) async {
    final me = uid;
    final b = db.batch();
    b.set(userRef(target).collection('followers').doc(me),
        {'at': FieldValue.serverTimestamp()});
    b.set(userRef(me).collection('following').doc(target),
        {'at': FieldValue.serverTimestamp()});
    await b.commit();
  }

  static Future<void> unfollow(String target) async {
    final me = uid;
    final b = db.batch();
    b.delete(userRef(target).collection('followers').doc(me));
    b.delete(userRef(me).collection('following').doc(target));
    await b.commit();
  }

  // ── المنشورات ──

  static Future<void> addPost(String imageB64, String caption) async {
    final me = await userRef(uid).get();
    final username = me.data()?['username'] as String?;
    if (username == null) throw AppError('أكمل ملفك الشخصي أولاً');
    await posts.add({
      'authorId': uid,
      'authorUsername': username,
      'caption': caption.trim(),
      'image': imageB64,
      'likesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deletePost(String id) => posts.doc(id).delete();

  static Future<void> toggleLike(String postId, bool currentlyLiked) async {
    final postRef = posts.doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);
    final b = db.batch();
    if (currentlyLiked) {
      b.delete(likeRef);
      b.update(postRef, {'likesCount': FieldValue.increment(-1)});
    } else {
      b.set(likeRef, {'at': FieldValue.serverTimestamp()});
      b.update(postRef, {'likesCount': FieldValue.increment(1)});
    }
    await b.commit();
  }

  static Future<void> toggleSave(String postId, bool currentlySaved) async {
    final ref = userRef(uid).collection('saved').doc(postId);
    if (currentlySaved) {
      await ref.delete();
    } else {
      await ref.set({'at': FieldValue.serverTimestamp()});
    }
  }

  static Future<void> addComment(String postId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final me = await userRef(uid).get();
    await posts.doc(postId).collection('comments').add({
      'authorId': uid,
      'authorUsername': me.data()?['username'] ?? '',
      'text': t,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteComment(String postId, String commentId) =>
      posts.doc(postId).collection('comments').doc(commentId).delete();

  // ── البلاغات (تُحفظ في Firestore، ويتواصل المبلّغ مع حساب الإدارة) ──

  static Future<void> report({
    required String type,
    required String targetId,
    required String targetUid,
    required String reason,
    String details = '',
  }) async {
    await db.collection('reports').add({
      'reporterId': uid,
      'type': type,
      'targetId': targetId,
      'targetUid': targetUid,
      'reason': reason,
      'details': details.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── الرسائل (مشفرة) ──

  static Future<void> sendMessage({
    required String chatId,
    required String other,
    required cg.SecretKey key,
    required String type, // txt | img
    required String value,
    required String preview,
  }) async {
    final cipher = await E2EE.encrypt(key, jsonEncode({'t': type, 'v': value}));
    final previewCipher = await E2EE.encrypt(key, preview);
    final members = [uid, other]..sort();
    final chatRef = db.collection('chats').doc(chatId);
    await chatRef.set({
      'members': members,
      'last': previewCipher,
      'lastFrom': uid,
      'lastAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await chatRef.collection('messages').add({
      'from': uid,
      'c': cipher,
      'at': FieldValue.serverTimestamp(),
    });
  }
}

// ═════════════════════════ ودجات عامة ═════════════════════════

class Avatar extends StatelessWidget {
  final String name;
  final String photo;
  final double radius;

  const Avatar({super.key, required this.name, this.photo = '', this.radius = 18});

  @override
  Widget build(BuildContext context) {
    if (photo.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.memory(
            decodeImg(photo),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _letter(),
          ),
        ),
      );
    }
    return _letter();
  }

  Widget _letter() {
    final letter =
        name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();
    final colors = AppTheme.palettes[hashName(name) % AppTheme.palettes.length];
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String uid;
  final double radius;

  const UserAvatar({super.key, required this.uid, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: UserCache.get(uid),
      builder: (_, s) => Avatar(
        name: s.data?.username ?? '',
        photo: s.data?.photo ?? '',
        radius: radius,
      ),
    );
  }
}

class B64Image extends StatelessWidget {
  final String data;
  final int? cacheWidth;

  const B64Image({super.key, required this.data, this.cacheWidth});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(color: AppTheme.surfaceAlt);
    }
    return Image.memory(
      decodeImg(data),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Container(
        color: AppTheme.surfaceAlt,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

class Splash extends StatelessWidget {
  const Splash({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class ErrorView extends StatelessWidget {
  final Object error;
  const ErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(friendlyError(error),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted)),
        ),
      );
}

class GradientTitle extends StatelessWidget {
  final double size;
  const GradientTitle({super.key, required this.size});

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (r) => AppTheme.storyGradient.createShader(r),
        child: Text(
          'SocialApp',
          style: TextStyle(
            color: Colors.white,
            fontSize: size,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
}

/// شبكة منشورات 3 أعمدة
class PostsGrid extends StatelessWidget {
  final List<PostData> posts;
  final bool scroll;
  const PostsGrid({super.key, required this.posts, this.scroll = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: !scroll,
      physics: scroll ? null : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailPage(post: posts[i])),
        ),
        child: B64Image(data: posts[i].image, cacheWidth: 400),
      ),
    );
  }
}

// ═════════════════════════ التطبيق والبوابات ═════════════════════════

class SocialApp extends StatelessWidget {
  final String? initError;
  const SocialApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocialApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: initError != null
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(initError!, textAlign: TextAlign.center),
                ),
              ),
            )
          : const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Repo.busy,
      builder: (context, busy, _) => StreamBuilder<User?>(
        stream: Repo.auth.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Splash();
          }
          final user = snap.data;
          if (user == null || busy) return const AuthPage();
          return ProfileGate(key: ValueKey(user.uid), user: user);
        },
      ),
    );
  }
}

class ProfileGate extends StatefulWidget {
  final User user;
  const ProfileGate({super.key, required this.user});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late final Future<void> _init = _prepare();

  Future<void> _prepare() async {
    try {
      final uid = widget.user.uid;
      final pk = await E2EE.ensureKeys(uid);
      final snap = await Repo.userRef(uid).get();
      if (snap.exists && snap.data()?['pk'] != pk) {
        await Repo.userRef(uid).update({'pk': pk});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return const Splash();
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: Repo.userRef(widget.user.uid).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Scaffold(body: ErrorView(error: snap.error!));
            }
            if (!snap.hasData) return const Splash();
            if (!snap.data!.exists) {
              return SetupUsernamePage(user: widget.user);
            }
            return const MainShell();
          },
        );
      },
    );
  }
}

// ═════════════════════════ تسجيل الدخول / إنشاء حساب ═════════════════════════

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _user = TextEditingController();
  bool _signup = false;
  bool _loading = false;
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _user.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty || (_signup && _user.text.trim().isEmpty)) {
      toast(context, 'املأ كل الحقول أولاً');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_signup) {
        await Repo.signUp(email, pass, _user.text);
      } else {
        await Repo.signIn(email, pass);
      }
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final c = TextEditingController(text: _email.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('استعادة كلمة المرور'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: 'الإيميل'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    c.dispose();
    if (email == null || email.isEmpty) return;
    try {
      await Repo.auth.sendPasswordResetEmail(email: email);
    } catch (_) {}
    if (mounted) {
      toast(context, 'إن كان الإيميل مسجلاً فسيصلك رابط إعادة التعيين');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GradientTitle(size: 44),
                const SizedBox(height: 8),
                const Text('شارك لحظاتك مع أصدقائك',
                    style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  autocorrect: false,
                  decoration: const InputDecoration(hintText: 'الإيميل'),
                ),
                if (_signup) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _user,
                    textDirection: TextDirection.ltr,
                    autocorrect: false,
                    decoration: const InputDecoration(
                        hintText: 'اسم المستخدم (a-z و 0-9)'),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: _hide,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور',
                    suffixIcon: IconButton(
                      icon: Icon(_hide
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(_signup ? 'إنشاء حساب' : 'تسجيل الدخول',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (!_signup)
                  TextButton(
                    onPressed: _forgot,
                    child: const Text('نسيت كلمة المرور؟',
                        style: TextStyle(color: AppTheme.textMuted)),
                  ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _signup = !_signup),
                  child: Text(
                    _signup
                        ? 'لديك حساب؟ سجّل الدخول'
                        : 'ليس لديك حساب؟ أنشئ حساباً',
                    style: const TextStyle(color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'إيميلك لا يظهر لأي مستخدم، وكلمة مرورك لا تُخزَّن عندنا (تُدار بأمان عبر Firebase).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SetupUsernamePage extends StatefulWidget {
  final User user;
  const SetupUsernamePage({super.key, required this.user});

  @override
  State<SetupUsernamePage> createState() => _SetupUsernamePageState();
}

class _SetupUsernamePageState extends State<SetupUsernamePage> {
  final _c = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() => _loading = true);
    try {
      await Repo.createProfile(widget.user, _c.text);
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('اختر اسم المستخدم',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _c,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(hintText: 'username'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _go,
                  child: const Text('متابعة'),
                ),
              ),
              TextButton(
                onPressed: () => Repo.auth.signOut(),
                child: const Text('تسجيل الخروج',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════ الإطار الرئيسي ═════════════════════════

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  Future<void> _openCreate() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
    if (done == true && mounted) setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const FeedPage(),
          const ExplorePage(),
          const SizedBox.shrink(),
          UserProfilePage(uid: Repo.uid),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Colors.white,
          unselectedItemColor: AppTheme.textMuted,
          currentIndex: _index,
          onTap: (i) {
            if (i == 2) {
              _openCreate();
            } else {
              setState(() => _index = i);
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية'),
            BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded),
                activeIcon: Icon(Icons.manage_search_rounded),
                label: 'استكشاف'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_box_outlined),
                activeIcon: Icon(Icons.add_box_rounded),
                label: 'نشر'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════ الرئيسية ═════════════════════════

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool _onlyFollowing = false;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _posts = Repo.posts
      .orderBy('createdAt', descending: true)
      .limit(60)
      .snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _following =
      Repo.userRef(Repo.uid).collection('following').snapshots();

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('الكل'),
            selected: !_onlyFollowing,
            onSelected: (_) => setState(() => _onlyFollowing = false),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('المتابَعون'),
            selected: _onlyFollowing,
            onSelected: (_) => setState(() => _onlyFollowing = true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const GradientTitle(size: 26),
        actions: [
          IconButton(
            tooltip: 'الرسائل',
            icon: const Icon(Icons.send_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatsScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _following,
        builder: (context, fSnap) {
          final following = <String>{
            Repo.uid,
            ...?fSnap.data?.docs.map((d) => d.id),
          };
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _posts,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(error: snap.error!);
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var posts = snap.data!.docs.map(PostData.fromDoc).toList();
              if (_onlyFollowing) {
                posts =
                    posts.where((p) => following.contains(p.authorId)).toList();
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: posts.isEmpty ? 2 : posts.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) return _filterBar();
                  if (posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          _onlyFollowing
                              ? 'تابع أشخاصاً من تبويب الاستكشاف لتظهر منشوراتهم هنا'
                              : 'لا توجد منشورات بعد، كن أول من ينشر!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    );
                  }
                  final p = posts[i - 1];
                  return PostCard(key: ValueKey(p.id), post: p);
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ═════════════════════════ البلاغ ═════════════════════════

Future<void> showReportSheet(
  BuildContext context, {
  required String type,
  required String targetId,
  required String targetUid,
}) async {
  const reasons = [
    'محتوى مزعج أو إعلانات',
    'تحرش أو إساءة',
    'محتوى غير لائق',
    'انتحال شخصية',
    'معلومات مضللة',
    'أخرى',
  ];
  String? reason;
  bool sending = false;
  bool sent = false;
  final details = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: sent
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 48, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    const Text('تم إرسال البلاغ، شكراً لك',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('تقدر تراسل الإدارة مباشرة لو تريد تضيف شي.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          try {
                            final admin = await Repo.uidOfUsername(
                                AppConfig.adminUsername);
                            if (admin == null) {
                              if (ctx.mounted) {
                                toast(ctx, 'حساب الإدارة غير موجود بعد');
                              }
                              return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            nav.push(MaterialPageRoute(
                                builder: (_) => ChatScreen(otherUid: admin)));
                          } catch (e) {
                            if (ctx.mounted) toast(ctx, friendlyError(e));
                          }
                        },
                        child: const Text('تواصل مع الإدارة'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إغلاق',
                          style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إبلاغ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text(
                        'اختر السبب، والبلاغ سري ولن يعرف الطرف الآخر من أبلغ.',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reasons
                          .map((r) => ChoiceChip(
                                label: Text(r),
                                selected: reason == r,
                                onSelected: (_) => setS(() => reason = r),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: details,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                          hintText: 'تفاصيل إضافية (اختياري)'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: (reason == null || sending)
                            ? null
                            : () async {
                                setS(() => sending = true);
                                try {
                                  await Repo.report(
                                    type: type,
                                    targetId: targetId,
                                    targetUid: targetUid,
                                    reason: reason!,
                                    details: details.text,
                                  );
                                  setS(() => sent = true);
                                } catch (e) {
                                  setS(() => sending = false);
                                  if (ctx.mounted) toast(ctx, friendlyError(e));
                                }
                              },
                        child: const Text('إرسال البلاغ'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
  details.dispose();
}

// ═════════════════════════ بطاقة المنشور ═════════════════════════

class PostCard extends StatefulWidget {
  final PostData post;
  final bool inDetail;

  const PostCard({super.key, required this.post, this.inDetail = false});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _heart = false;
  bool _busy = false;

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _likeDoc = Repo
      .posts
      .doc(widget.post.id)
      .collection('likes')
      .doc(Repo.uid)
      .snapshots();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _savedDoc = Repo
      .userRef(Repo.uid)
      .collection('saved')
      .doc(widget.post.id)
      .snapshots();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _postDoc =
      Repo.posts.doc(widget.post.id).snapshots();

  Future<void> _like(bool liked) async {
    if (_busy) return;
    _busy = true;
    try {
      await Repo.toggleLike(widget.post.id, liked);
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      _busy = false;
    }
  }

  void _doubleTapLike(bool liked) {
    if (!liked) _like(false);
    setState(() => _heart = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _heart = false);
    });
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CommentsSheet(post: widget.post),
    );
  }

  void _openAuthor() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => UserProfilePage(uid: widget.post.authorId, pushed: true)));
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
        context, 'حذف المنشور', 'هل تريد حذف هذا المنشور نهائياً؟', 'حذف');
    if (!ok) return;
    try {
      await Repo.deletePost(widget.post.id);
      if (mounted && widget.inDetail) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final mine = p.authorId == Repo.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: _openAuthor,
                child: Row(
                  children: [
                    UserAvatar(uid: p.authorId, radius: 16),
                    const SizedBox(width: 10),
                    Text(p.authorUsername,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                color: const Color(0xFF1A1A1A),
                onSelected: (v) {
                  if (v == 'delete') _delete();
                  if (v == 'report') {
                    showReportSheet(context,
                        type: 'post', targetId: p.id, targetUid: p.authorId);
                  }
                },
                itemBuilder: (_) => [
                  if (mine)
                    const PopupMenuItem(value: 'delete', child: Text('حذف'))
                  else
                    const PopupMenuItem(value: 'report', child: Text('إبلاغ')),
                ],
              ),
            ],
          ),
        ),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _likeDoc,
          builder: (context, ls) {
            final liked = ls.data?.exists ?? false;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onDoubleTap: () => _doubleTapLike(liked),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        B64Image(data: p.image, cacheWidth: 900),
                        AnimatedOpacity(
                          opacity: _heart ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.favorite,
                              size: 90, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _like(liked),
                        icon: Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          color: liked ? AppTheme.like : Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _openComments,
                        icon: const Icon(Icons.mode_comment_outlined),
                      ),
                      const Spacer(),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: _savedDoc,
                        builder: (context, ss) {
                          final saved = ss.data?.exists ?? false;
                          return IconButton(
                            onPressed: () async {
                              try {
                                await Repo.toggleSave(p.id, saved);
                              } catch (e) {
                                if (context.mounted) {
                                  toast(context, friendlyError(e));
                                }
                              }
                            },
                            icon: Icon(saved
                                ? Icons.bookmark
                                : Icons.bookmark_border),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _postDoc,
                builder: (context, s) {
                  final n = (s.data?.data()?['likesCount'] as num?)?.toInt() ??
                      p.likes;
                  return Text('$n إعجاب',
                      style: const TextStyle(fontWeight: FontWeight.bold));
                },
              ),
              if (p.caption.isNotEmpty) ...[
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white),
                    children: [
                      TextSpan(
                          text: '${p.authorUsername} ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: p.caption),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _openComments,
                child: const Text('عرض التعليقات',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ),
              const SizedBox(height: 2),
              Text(timeAgo(p.createdAt),
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final PostData post;
  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _c = TextEditingController();
  bool _sending = false;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = Repo.posts
      .doc(widget.post.id)
      .collection('comments')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _c.text;
    if (t.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await Repo.addComment(widget.post.id, t);
      _c.clear();
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text('التعليقات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(color: AppTheme.border),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream,
                builder: (context, snap) {
                  if (snap.hasError) return ErrorView(error: snap.error!);
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('لا توجد تعليقات بعد',
                          style: TextStyle(color: AppTheme.textMuted)),
                    );
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final m = d.data();
                      final author = (m['authorId'] ?? '') as String;
                      return ListTile(
                        leading: UserAvatar(uid: author, radius: 16),
                        title: Text((m['authorUsername'] ?? '') as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text((m['text'] ?? '') as String),
                        trailing: author == Repo.uid
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: AppTheme.textMuted),
                                onPressed: () =>
                                    Repo.deleteComment(widget.post.id, d.id),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      onSubmitted: (_) => _send(),
                      decoration:
                          const InputDecoration(hintText: 'اكتب تعليقاً...'),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded,
                        color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostDetailPage extends StatelessWidget {
  final PostData post;
  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المنشور')),
      body: SingleChildScrollView(child: PostCard(post: post, inDetail: true)),
    );
  }
}

// ═════════════════════════ الاستكشاف والبحث ═════════════════════════

class UserSearchList extends StatefulWidget {
  final void Function(UserProfile user)? onPick;
  final Widget? whenEmpty;
  const UserSearchList({super.key, this.onPick, this.whenEmpty});

  @override
  State<UserSearchList> createState() => _UserSearchListState();
}

class _UserSearchListState extends State<UserSearchList> {
  final _c = TextEditingController();
  Timer? _deb;
  List<UserProfile> _results = [];
  bool _loading = false;
  String _q = '';

  @override
  void dispose() {
    _deb?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _deb?.cancel();
    final q = v.trim().toLowerCase();
    setState(() => _q = q);
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _deb = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final snap = await Repo.db
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: q)
          .where('username', isLessThan: '$q\uf8ff')
          .limit(20)
          .get();
      if (!mounted || _q != q) return;
      setState(() => _results = snap.docs
          .where((d) => d.id != Repo.uid)
          .map((d) => UserProfile.fromMap(d.id, d.data()))
          .toList());
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _c,
            onChanged: _onChanged,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'ابحث باسم المستخدم',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: _q.isEmpty
              ? (widget.whenEmpty ?? const SizedBox.shrink())
              : _loading && _results.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? const Center(
                          child: Text('لا توجد نتائج',
                              style: TextStyle(color: AppTheme.textMuted)))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final u = _results[i];
                            return ListTile(
                              leading: Avatar(
                                  name: u.username, photo: u.photo, radius: 22),
                              title: Text(u.username),
                              subtitle: u.name.isEmpty ? null : Text(u.name),
                              onTap: () {
                                if (widget.onPick != null) {
                                  widget.onPick!(u);
                                } else {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => UserProfilePage(
                                          uid: u.uid, pushed: true)));
                                }
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _posts = Repo.posts
      .orderBy('createdAt', descending: true)
      .limit(60)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استكشاف')),
      body: UserSearchList(
        whenEmpty: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _posts,
          builder: (context, snap) {
            if (snap.hasError) return ErrorView(error: snap.error!);
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final posts = snap.data!.docs.map(PostData.fromDoc).toList();
            if (posts.isEmpty) {
              return const Center(
                child: Text('لا توجد منشورات بعد',
                    style: TextStyle(color: AppTheme.textMuted)),
              );
            }
            return PostsGrid(posts: posts, scroll: true);
          },
        ),
      ),
    );
  }
}

// ═════════════════════════ نشر منشور ═════════════════════════

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _caption = TextEditingController();
  String? _img;
  bool _loading = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final b = await pickImageB64(context,
          maxSize: 1080, quality: 70, maxChars: 700000);
      if (b != null && mounted) setState(() => _img = b);
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    }
  }

  Future<void> _publish() async {
    if (_img == null) {
      toast(context, 'اختر صورة أولاً');
      return;
    }
    setState(() => _loading = true);
    try {
      await Repo.addPost(_img!, _caption.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        toast(context, friendlyError(e));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منشور جديد'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _publish,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('نشر',
                    style: TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pick,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _img == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 56),
                            SizedBox(height: 8),
                            Text('اضغط لاختيار صورة'),
                          ],
                        ),
                      )
                    : B64Image(data: _img!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'اكتب وصفاً...'),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════ الملف الشخصي ═════════════════════════

class UserProfilePage extends StatefulWidget {
  final String uid;
  final bool pushed;
  const UserProfilePage({super.key, required this.uid, this.pushed = false});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  int _tab = 0;
  bool _busy = false;

  bool get _isMe => widget.uid == Repo.uid;

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _user =
      Repo.userRef(widget.uid).snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _posts =
      Repo.posts.where('authorId', isEqualTo: widget.uid).snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _followers =
      Repo.userRef(widget.uid).collection('followers').snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _following =
      Repo.userRef(widget.uid).collection('following').snapshots();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _iFollow = Repo
      .userRef(Repo.uid)
      .collection('following')
      .doc(widget.uid)
      .snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _saved =
      Repo.userRef(Repo.uid).collection('saved').snapshots();

  Widget _count(String label, int n) => Column(
        children: [
          Text('$n',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          Text(label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      );

  Widget _countStream(
      Stream<QuerySnapshot<Map<String, dynamic>>> s, String label) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: s,
      builder: (_, snap) => _count(label, snap.data?.size ?? 0),
    );
  }

  Future<void> _toggleFollow(bool following) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (following) {
        await Repo.unfollow(widget.uid);
      } else {
        await Repo.follow(widget.uid);
      }
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
        context, 'تسجيل الخروج', 'هل تريد تسجيل الخروج؟', 'خروج');
    if (ok) await Repo.auth.signOut();
  }

  Future<void> _deleteAccount() async {
    final c = TextEditingController();
    final pass = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('حذف الحساب نهائياً'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('سيتم حذف حسابك ومنشوراتك ولا يمكن التراجع. أدخل كلمة المرور للتأكيد.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(hintText: 'كلمة المرور'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('حذف', style: TextStyle(color: AppTheme.like)),
          ),
        ],
      ),
    );
    c.dispose();
    if (pass == null || pass.isEmpty) return;
    try {
      await Repo.deleteAccount(pass);
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    }
  }

  Widget _savedGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _saved,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()));
        }
        final ids = snap.data!.docs.map((d) => d.id).toList();
        if (ids.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text('لم تحفظ أي منشور بعد',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
          );
        }
        return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
          future: Future.wait(ids.map((id) => Repo.posts.doc(id).get())),
          builder: (context, fs) {
            if (!fs.hasData) {
              return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()));
            }
            final posts = fs.data!
                .where((d) => d.exists)
                .map(PostData.fromDoc)
                .toList();
            return PostsGrid(posts: posts);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _user,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
              appBar: AppBar(), body: ErrorView(error: snap.error!));
        }
        if (!snap.hasData) return const Splash();
        final data = snap.data!.data();
        if (data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('هذا الحساب غير موجود',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
          );
        }
        final u = UserProfile.fromMap(widget.uid, data);
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: widget.pushed,
            title: Text(u.username),
            actions: [
              if (_isMe) ...[
                IconButton(
                  tooltip: 'الرسائل',
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatsScreen())),
                ),
                PopupMenuButton<String>(
                  color: const Color(0xFF1A1A1A),
                  onSelected: (v) {
                    if (v == 'logout') _logout();
                    if (v == 'delete') _deleteAccount();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
                    PopupMenuItem(value: 'delete', child: Text('حذف الحساب')),
                  ],
                ),
              ] else
                IconButton(
                  tooltip: 'إبلاغ',
                  icon: const Icon(Icons.flag_outlined),
                  onPressed: () => showReportSheet(context,
                      type: 'user', targetId: widget.uid, targetUid: widget.uid),
                ),
            ],
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(name: u.username, photo: u.photo, radius: 40),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _countStream(_posts, 'منشور'),
                              _countStream(_followers, 'متابِع'),
                              _countStream(_following, 'يتابع'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (u.name.isNotEmpty)
                      Text(u.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (u.bio.isNotEmpty) Text(u.bio),
                    const SizedBox(height: 12),
                    if (_isMe)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => EditProfilePage(profile: u))),
                          child: const Text('تعديل الملف الشخصي'),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: _iFollow,
                              builder: (context, fs) {
                                final following = fs.data?.exists ?? false;
                                return following
                                    ? OutlinedButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _toggleFollow(true),
                                        child: const Text('إلغاء المتابعة'),
                                      )
                                    : FilledButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _toggleFollow(false),
                                        child: const Text('متابعة'),
                                      );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ChatScreen(otherUid: widget.uid))),
                              child: const Text('رسالة'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (_isMe)
                Row(
                  children: [
                    Expanded(
                      child: IconButton(
                        onPressed: () => setState(() => _tab = 0),
                        icon: Icon(Icons.grid_on,
                            color: _tab == 0 ? Colors.white : AppTheme.textMuted),
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        onPressed: () => setState(() => _tab = 1),
                        icon: Icon(Icons.bookmark_border,
                            color: _tab == 1 ? Colors.white : AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              const Divider(height: 1, color: AppTheme.border),
              if (_isMe && _tab == 1)
                _savedGrid()
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _posts,
                  builder: (context, ps) {
                    if (ps.hasError) return ErrorView(error: ps.error!);
                    if (!ps.hasData) {
                      return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()));
                    }
                    final posts = ps.data!.docs.map(PostData.fromDoc).toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    if (posts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text('لا توجد منشورات بعد',
                              style: TextStyle(color: AppTheme.textMuted)),
                        ),
                      );
                    }
                    return PostsGrid(posts: posts);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final UserProfile profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _bio = TextEditingController(text: widget.profile.bio);
  final _phone = TextEditingController();
  final _birth = TextEditingController();
  String? _photo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivate();
  }

  Future<void> _loadPrivate() async {
    try {
      final d = await Repo.privateRef(Repo.uid).get();
      final m = d.data();
      if (m != null && mounted) {
        _phone.text = (m['phone'] ?? '') as String;
        _birth.text = (m['birth'] ?? '') as String;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _phone.dispose();
    _birth.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final b = await pickImageB64(context,
          maxSize: 400, quality: 70, maxChars: 100000);
      if (b != null && mounted) setState(() => _photo = b);
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await Repo.updateProfile(
          name: _name.text, bio: _bio.text, photo: _photo);
      await Repo.savePrivate(_phone.text, _birth.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        toast(context, friendlyError(e));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shownPhoto = _photo ?? widget.profile.photo;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('حفظ',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Column(
                children: [
                  Avatar(
                      name: widget.profile.username,
                      photo: shownPhoto,
                      radius: 48),
                  const SizedBox(height: 8),
                  const Text('تغيير الصورة',
                      style: TextStyle(color: AppTheme.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            maxLength: 40,
            decoration: const InputDecoration(hintText: 'الاسم'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bio,
            maxLength: 150,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'نبذة عنك'),
          ),
          const SizedBox(height: 16),
          const Text('معلومات خاصة (لا يراها أحد غيرك)',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(hintText: 'رقم الهاتف'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _birth,
            textDirection: TextDirection.ltr,
            decoration:
                const InputDecoration(hintText: 'تاريخ الميلاد (2008-01-31)'),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════ الرسائل ═════════════════════════

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = Repo.db
        .collection('chats')
        .where('members', arrayContains: Repo.uid)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسائل'),
        actions: [
          IconButton(
            tooltip: 'محادثة جديدة',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('محادثة جديدة')),
                  body: UserSearchList(
                    onPick: (u) => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => ChatScreen(otherUid: u.uid)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(error: snap.error!);
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs.toList()
            ..sort((a, b) => tsToDate(b.data()['lastAt'])
                .compareTo(tsToDate(a.data()['lastAt'])));
          if (docs.isEmpty) {
            return const Center(
              child: Text('لا توجد محادثات بعد',
                  style: TextStyle(color: AppTheme.textMuted)),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final m = docs[i].data();
              final members = List<String>.from(m['members'] as List);
              final other = members.firstWhere((x) => x != Repo.uid,
                  orElse: () => Repo.uid);
              return ChatTile(
                key: ValueKey(docs[i].id),
                chatId: docs[i].id,
                otherUid: other,
                lastCipher: (m['last'] ?? '') as String,
                lastAt: tsToDate(m['lastAt']),
              );
            },
          );
        },
      ),
    );
  }
}

class _Prev {
  final UserProfile? user;
  final String text;
  _Prev(this.user, this.text);
}

class ChatTile extends StatelessWidget {
  final String chatId;
  final String otherUid;
  final String lastCipher;
  final DateTime lastAt;

  const ChatTile({
    super.key,
    required this.chatId,
    required this.otherUid,
    required this.lastCipher,
    required this.lastAt,
  });

  Future<_Prev> _load() async {
    final d = await Repo.userRef(otherUid).get();
    final data = d.data();
    if (data == null) return _Prev(null, '');
    final u = UserProfile.fromMap(otherUid, data);
    if (u.pk.isEmpty || lastCipher.isEmpty) return _Prev(u, '');
    final key = await E2EE.keyFor(chatId, u.pk);
    return _Prev(u, await E2EE.decrypt(key, lastCipher));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Prev>(
      future: _load(),
      builder: (context, s) {
        final p = s.data;
        final u = p?.user;
        return ListTile(
          leading: Avatar(
              name: u?.username ?? '', photo: u?.photo ?? '', radius: 24),
          title: Text(u?.username ?? '...'),
          subtitle: Text(p?.text ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted)),
          trailing: Text(timeAgo(lastAt),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatScreen(otherUid: otherUid))),
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String otherUid;
  const ChatScreen({super.key, required this.otherUid});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _c = TextEditingController();
  UserProfile? _other;
  cg.SecretKey? _key;
  bool _sending = false;

  late final String _chatId = Repo.chatId(Repo.uid, widget.otherUid);
  late final Future<void> _init = _prepare();

  Future<void> _prepare() async {
    final d = await Repo.userRef(widget.otherUid).get();
    final data = d.data();
    if (data == null) throw AppError('المستخدم غير موجود');
    final u = UserProfile.fromMap(widget.otherUid, data);
    if (u.pk.isEmpty) throw AppError('هذا المستخدم لم يفعّل التشفير بعد');
    _other = u;
    _key = await E2EE.keyFor(_chatId, u.pk);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final t = _c.text.trim();
    if (t.isEmpty || _sending || _key == null) return;
    _c.clear();
    try {
      await Repo.sendMessage(
        chatId: _chatId,
        other: widget.otherUid,
        key: _key!,
        type: 'txt',
        value: t,
        preview: t.length > 40 ? t.substring(0, 40) : t,
      );
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    }
  }

  Future<void> _sendImage() async {
    if (_sending || _key == null) return;
    try {
      final b = await pickImageB64(context,
          maxSize: 900, quality: 60, maxChars: 450000);
      if (b == null) return;
      setState(() => _sending = true);
      await Repo.sendMessage(
        chatId: _chatId,
        other: widget.otherUid,
        key: _key!,
        type: 'img',
        value: b,
        preview: '📷 صورة',
      );
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return const Splash();
        if (s.hasError) {
          return Scaffold(
              appBar: AppBar(), body: ErrorView(error: s.error!));
        }
        final other = _other!;
        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      UserProfilePage(uid: other.uid, pushed: true))),
              child: Row(
                children: [
                  Avatar(name: other.username, photo: other.photo, radius: 16),
                  const SizedBox(width: 10),
                  Text(other.username, style: const TextStyle(fontSize: 17)),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: const Color(0xFF111111),
                child: const Text('🔒 الرسائل مشفرة من طرف إلى طرف',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: Repo.db
                      .collection('chats')
                      .doc(_chatId)
                      .collection('messages')
                      .orderBy('at', descending: true)
                      .limit(100)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) return ErrorView(error: snap.error!);
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('ابدأ المحادثة',
                            style: TextStyle(color: AppTheme.textMuted)),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final m = docs[i].data();
                        return _Bubble(
                          key: ValueKey(docs[i].id),
                          cipher: (m['c'] ?? '') as String,
                          mine: m['from'] == Repo.uid,
                          secret: _key!,
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _sending ? null : _sendImage,
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.image_outlined),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _c,
                          onSubmitted: (_) => _sendText(),
                          decoration:
                              const InputDecoration(hintText: 'اكتب رسالة...'),
                        ),
                      ),
                      IconButton(
                        onPressed: _sendText,
                        icon: const Icon(Icons.send_rounded,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  final String cipher;
  final bool mine;
  final cg.SecretKey secret;

  const _Bubble({
    super.key,
    required this.cipher,
    required this.mine,
    required this.secret,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? AppTheme.primary : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<String>(
          future: E2EE.decrypt(secret, cipher),
          builder: (context, s) {
            if (!s.hasData) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            String type = 'txt';
            String value = s.data!;
            try {
              final j = jsonDecode(s.data!) as Map<String, dynamic>;
              type = (j['t'] ?? 'txt') as String;
              value = (j['v'] ?? '') as String;
            } catch (_) {}
            if (type == 'img') {
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(),
                    body: Center(
                      child: InteractiveViewer(
                        child: Image.memory(decodeImg(value)),
                      ),
                    ),
                  ),
                )),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: B64Image(data: value, cacheWidth: 600),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(value, style: const TextStyle(color: Colors.white)),
            );
          },
        ),
      ),
    );
  }
}
