import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SocialApp());
}

// ───────────────────────── الثيم ─────────────────────────

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

  static const List<IconData> icons = [
    Icons.landscape_rounded,
    Icons.local_cafe_rounded,
    Icons.pets_rounded,
    Icons.wb_sunny_rounded,
    Icons.flight_rounded,
    Icons.music_note_rounded,
    Icons.restaurant_rounded,
    Icons.sports_soccer_rounded,
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

// ───────────────────────── النماذج ─────────────────────────

class Comment {
  final String author;
  final String text;
  Comment(this.author, this.text);
}

class Post {
  final String id;
  final String author;
  final String caption;
  final int palette;
  final int icon;
  final DateTime createdAt;
  int likes;
  bool liked;
  bool saved;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.author,
    required this.caption,
    required this.palette,
    required this.icon,
    required this.createdAt,
    this.likes = 0,
    this.liked = false,
    this.saved = false,
    List<Comment>? comments,
  }) : comments = comments ?? [];
}

class ChatMessage {
  final String text;
  final bool mine;
  final DateTime time;
  ChatMessage({required this.text, required this.mine, required this.time});
}

class Chat {
  final String name;
  final List<ChatMessage> messages;
  Chat({required this.name, List<ChatMessage>? messages})
      : messages = messages ?? [];
}

// ───────────────────────── حالة التطبيق ─────────────────────────

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();

  AppState._() {
    _seed();
  }

  String userName = '';
  String bio = 'مرحباً بكم في صفحتي ✨';
  int followers = 340;
  int following = 120;

  final List<Post> posts = [];
  final List<Chat> chats = [];
  final List<String> storyUsers = ['سارة', 'علي', 'نور', 'ليث', 'هدى'];
  final Set<String> viewedStories = {};

  bool get loggedIn => userName.isNotEmpty;

  void _seed() {
    final now = DateTime.now();
    posts.addAll([
      Post(
        id: '1',
        author: 'سارة',
        caption: 'غروب اليوم كان خيالي 🌅',
        palette: 3,
        icon: 3,
        createdAt: now.subtract(const Duration(minutes: 25)),
        likes: 128,
        comments: [Comment('علي', 'تجنن!'), Comment('نور', 'وين هذا المكان؟')],
      ),
      Post(
        id: '2',
        author: 'علي',
        caption: 'قهوة الصباح ☕ لا يبدأ اليوم إلا بها',
        palette: 5,
        icon: 1,
        createdAt: now.subtract(const Duration(hours: 4)),
        likes: 64,
        comments: [Comment('سارة', 'أنا بعد 😍')],
      ),
      Post(
        id: '3',
        author: 'نور',
        caption: 'رحلة نهاية الأسبوع ✈️',
        palette: 4,
        icon: 4,
        createdAt: now.subtract(const Duration(days: 1)),
        likes: 203,
      ),
      Post(
        id: '4',
        author: 'ليث',
        caption: 'صديقي الجديد 🐶',
        palette: 2,
        icon: 2,
        createdAt: now.subtract(const Duration(days: 2)),
        likes: 311,
        comments: [Comment('هدى', 'كيوووت')],
      ),
    ]);

    chats.addAll([
      Chat(name: 'سارة', messages: [
        ChatMessage(
            text: 'هلا! شفت ستوريي؟',
            mine: false,
            time: now.subtract(const Duration(hours: 1))),
      ]),
      Chat(name: 'علي', messages: [
        ChatMessage(
            text: 'تعال نطلع اليوم',
            mine: false,
            time: now.subtract(const Duration(hours: 5))),
      ]),
      Chat(name: 'نور'),
    ]);
  }

  void login(String name) {
    userName = name.trim();
    notifyListeners();
  }

  void logout() {
    userName = '';
    notifyListeners();
  }

  void setBio(String value) {
    bio = value.trim();
    notifyListeners();
  }

  void markViewed(String name) {
    viewedStories.add(name);
    notifyListeners();
  }

  void addPost(String caption, int palette, int icon) {
    posts.insert(
      0,
      Post(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        author: userName,
        caption: caption.trim(),
        palette: palette,
        icon: icon,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void deletePost(Post post) {
    posts.remove(post);
    notifyListeners();
  }

  void toggleLike(Post post) {
    post.liked = !post.liked;
    post.likes += post.liked ? 1 : -1;
    notifyListeners();
  }

  void toggleSave(Post post) {
    post.saved = !post.saved;
    notifyListeners();
  }

  void addComment(Post post, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    post.comments.add(Comment(userName, t));
    notifyListeners();
  }

  void sendMessage(Chat chat, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    chat.messages.add(ChatMessage(text: t, mine: true, time: DateTime.now()));
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      chat.messages.add(
          ChatMessage(text: 'تمام 👍', mine: false, time: DateTime.now()));
      notifyListeners();
    });
  }
}

// ───────────────────────── أدوات مساعدة ─────────────────────────

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays == 1) return 'أمس';
  return 'منذ ${diff.inDays} يوم';
}

int hashName(String s) => s.codeUnits.fold<int>(0, (a, b) => a + b);

class Avatar extends StatelessWidget {
  final String name;
  final double radius;

  const Avatar({super.key, required this.name, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
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

/// حلقة القصة الملونة حول الصورة
class StoryRing extends StatelessWidget {
  final Widget child;
  final bool seen;
  final bool show;

  const StoryRing(
      {super.key, required this.child, this.seen = false, this.show = true});

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: seen ? null : AppTheme.storyGradient,
        border: seen ? Border.all(color: AppTheme.textMuted, width: 1.5) : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: child,
      ),
    );
  }
}

/// مربع "صورة" ملون (بديل مؤقت للصور الحقيقية)
class PostImage extends StatelessWidget {
  final Post post;
  final double iconSize;

  const PostImage({super.key, required this.post, this.iconSize = 90});

  @override
  Widget build(BuildContext context) {
    final colors =
        AppTheme.palettes[post.palette % AppTheme.palettes.length];
    final icon = AppTheme.icons[post.icon % AppTheme.icons.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Center(
        child: Icon(icon, size: iconSize, color: Colors.white70),
      ),
    );
  }
}

// ───────────────────────── التطبيق ─────────────────────────

class SocialApp extends StatelessWidget {
  const SocialApp({super.key});

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
      home: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) => AppState.instance.loggedIn
            ? const MainShell()
            : const LoginPage(),
      ),
    );
  }
}

// ───────────────────────── تسجيل الدخول ─────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسم المستخدم أولاً')),
      );
      return;
    }
    AppState.instance.login(name);
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
                ShaderMask(
                  shaderCallback: (r) =>
                      AppTheme.storyGradient.createShader(r),
                  child: const Text(
                    'SocialApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('شارك لحظاتك مع أصدقائك',
                    style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 32),
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(hintText: 'اسم المستخدم'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('تسجيل الدخول',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── الإطار الرئيسي ─────────────────────────

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
        children: const [
          FeedPage(),
          ExplorePage(),
          SizedBox.shrink(),
          ProfilePage(),
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

// ───────────────────────── الرئيسية + القصص ─────────────────────────

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: ShaderMask(
          shaderCallback: (r) => AppTheme.storyGradient.createShader(r),
          child: const Text(
            'SocialApp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لا توجد إشعارات جديدة')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatsScreen()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final posts = AppState.instance.posts;
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: posts.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) return const StoriesBar();
              return PostCard(post: posts[i - 1]);
            },
          );
        },
      ),
    );
  }
}

class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Container(
      height: 108,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        children: [
          _item(
            context,
            name: 'قصتك',
            avatarName: state.userName,
            isMine: true,
            seen: false,
          ),
          ...state.storyUsers.map(
            (u) => _item(
              context,
              name: u,
              avatarName: u,
              seen: state.viewedStories.contains(u),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String name,
    required String avatarName,
    bool isMine = false,
    required bool seen,
  }) {
    return GestureDetector(
      onTap: () {
        if (isMine) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('إضافة قصة قريباً')),
          );
          return;
        }
        AppState.instance.markViewed(name);
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: true,
            pageBuilder: (_, __, ___) => StoryViewer(name: name),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  StoryRing(
                    show: !isMine,
                    seen: seen,
                    child: Avatar(name: avatarName, radius: 29),
                  ),
                  if (isMine)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Icon(Icons.add,
                            size: 18, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryViewer extends StatefulWidget {
  final String name;

  const StoryViewer({super.key, required this.name});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          Navigator.of(context).pop();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idx = hashName(widget.name);
    final colors = AppTheme.palettes[idx % AppTheme.palettes.length];
    final icon = AppTheme.icons[idx % AppTheme.icons.length];
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _c.value,
                        minHeight: 3,
                        backgroundColor: Colors.white30,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Avatar(name: widget.name, radius: 18),
                      const SizedBox(width: 10),
                      Text(widget.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(Icons.close_rounded, color: Colors.white),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(icon, size: 130, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── بطاقة المنشور ─────────────────────────

class PostCard extends StatefulWidget {
  final Post post;
  final bool inDetail;

  const PostCard({super.key, required this.post, this.inDetail = false});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _heart = false;

  void _doubleTapLike() {
    if (!widget.post.liked) AppState.instance.toggleLike(widget.post);
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
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: CommentsSheet(post: widget.post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final post = widget.post;
    final mine = post.author == state.userName;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الرأس
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
              child: Row(
                children: [
                  StoryRing(
                    show: state.storyUsers.contains(post.author),
                    seen: state.viewedStories.contains(post.author),
                    child: Avatar(name: post.author, radius: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(post.author,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (mine)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      color: const Color(0xFF262626),
                      onSelected: (v) {
                        if (v == 'delete') {
                          state.deletePost(post);
                          if (widget.inDetail) Navigator.of(context).pop();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.more_vert_rounded,
                          color: AppTheme.textMuted),
                    ),
                ],
              ),
            ),

            // الصورة
            GestureDetector(
              onDoubleTap: _doubleTapLike,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PostImage(post: post),
                    Center(
                      child: AnimatedOpacity(
                        opacity: _heart ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedScale(
                          scale: _heart ? 1.0 : 0.4,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(Icons.favorite_rounded,
                              color: Colors.white, size: 110),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // الأزرار
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => state.toggleLike(post),
                    icon: Icon(
                      post.liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: post.liked ? AppTheme.like : Colors.white,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: _openComments,
                    icon: const Icon(Icons.mode_comment_outlined, size: 26),
                  ),
                  IconButton(
                    onPressed: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                            content: Text('تم نسخ رابط المنشور'))),
                    icon: const Icon(Icons.send_outlined, size: 26),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => state.toggleSave(post),
                    icon: Icon(
                      post.saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // الإعجابات والوصف
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${post.likes} إعجاب',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.4),
                        children: [
                          TextSpan(
                              text: '${post.author} ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          TextSpan(text: post.caption),
                        ],
                      ),
                    ),
                  ],
                  if (post.comments.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openComments,
                      child: Text(
                        'عرض كل ${post.comments.length} تعليق',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(timeAgo(post.createdAt),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11)),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final Post post;

  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    AppState.instance.addComment(widget.post, _controller.text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.post.comments;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, MediaQuery.of(context).viewInsets.bottom + 14),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('التعليقات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(color: AppTheme.border),
            Expanded(
              child: comments.isEmpty
                  ? const Center(
                      child: Text('لا توجد تعليقات بعد',
                          style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Avatar(name: c.author, radius: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.4),
                                    children: [
                                      TextSpan(
                                          text: '${c.author}  ',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      TextSpan(text: c.text),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Avatar(name: AppState.instance.userName, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration:
                        const InputDecoration(hintText: 'أضف تعليقاً...'),
                  ),
                ),
                TextButton(
                  onPressed: _send,
                  child: const Text('نشر',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── الاستكشاف ─────────────────────────

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (v) => setState(() => _query = v.trim()),
          decoration: const InputDecoration(
            hintText: 'بحث',
            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final all = AppState.instance.posts;
          final posts = _query.isEmpty
              ? all
              : all
                  .where((p) =>
                      p.caption.contains(_query) || p.author.contains(_query))
                  .toList();
          if (posts.isEmpty) {
            return const Center(
              child: Text('لا توجد نتائج',
                  style: TextStyle(color: AppTheme.textMuted)),
            );
          }
          return PostsGrid(posts: posts);
        },
      ),
    );
  }
}

class PostsGrid extends StatelessWidget {
  final List<Post> posts;
  final bool shrink;

  const PostsGrid({super.key, required this.posts, this.shrink = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final p = posts[i];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PostDetailPage(post: p)),
          ),
          child: PostImage(post: p, iconSize: 40),
        );
      },
    );
  }
}

class PostDetailPage extends StatelessWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المنشور')),
      body: ListView(children: [PostCard(post: post, inDetail: true)]),
    );
  }
}

// ───────────────────────── إنشاء منشور ─────────────────────────

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _caption = TextEditingController();
  int _palette = 0;
  int _icon = 0;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = Post(
      id: 'preview',
      author: '',
      caption: '',
      palette: _palette,
      icon: _icon,
      createdAt: DateTime.now(),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('منشور جديد'),
        actions: [
          TextButton(
            onPressed: () {
              AppState.instance.addPost(_caption.text, _palette, _icon);
              Navigator.of(context).pop(true);
            },
            child: const Text('مشاركة',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: PostImage(post: preview, iconSize: 120),
            ),
          ),
          const SizedBox(height: 16),
          const Text('اللون',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppTheme.palettes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _palette = i),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: AppTheme.palettes[i]),
                    border: Border.all(
                      color: _palette == i ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('الرمز',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppTheme.icons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _icon = i),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _icon == i ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(AppTheme.icons[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'اكتب وصفاً...'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── الملف الشخصي ─────────────────────────

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _stat(String label, int value) {
    return Column(
      children: [
        Text('$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      ],
    );
  }

  void _editBio(BuildContext context) {
    final controller = TextEditingController(text: AppState.instance.bio);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('تعديل النبذة'),
          content: TextField(controller: controller, maxLines: 3),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            TextButton(
              onPressed: () {
                AppState.instance.setBio(controller.text);
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final mine =
            state.posts.where((p) => p.author == state.userName).toList();
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: Text(state.userName),
            actions: [
              IconButton(
                tooltip: 'تسجيل الخروج',
                icon: const Icon(Icons.logout_rounded),
                onPressed: state.logout,
              ),
            ],
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    StoryRing(
                      child: Avatar(name: state.userName, radius: 40),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stat('منشور', mine.length),
                          _stat('متابِع', state.followers),
                          _stat('يتابع', state.following),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.userName,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(state.bio),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _editBio(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.surfaceAlt,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('تعديل الملف الشخصي'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.border),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Icon(Icons.grid_on_rounded),
              ),
              if (mine.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('لا توجد منشورات بعد',
                        style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else
                PostsGrid(posts: mine, shrink: true),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── الرسائل ─────────────────────────

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppState.instance.userName)),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final chats = AppState.instance.chats;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (_, i) {
              final chat = chats[i];
              final last = chat.messages.isEmpty ? null : chat.messages.last;
              return ListTile(
                leading: Avatar(name: chat.name, radius: 26),
                title: Text(chat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  last?.text ?? 'ابدأ المحادثة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                trailing: last == null
                    ? null
                    : Text(timeAgo(last.time),
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChatPage(chat: chat)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final Chat chat;

  const ChatPage({super.key, required this.chat});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    AppState.instance.sendMessage(widget.chat, _controller.text);
    _controller.clear();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(name: widget.chat.name, radius: 16),
            const SizedBox(width: 10),
            Text(widget.chat.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: AppState.instance,
              builder: (context, _) {
                final msgs = widget.chat.messages;
                if (msgs.isEmpty) {
                  return const Center(
                    child: Text('لا توجد رسائل بعد',
                        style: TextStyle(color: AppTheme.textMuted)),
                  );
                }
                _scrollToEnd();
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    return Align(
                      alignment: m.mine
                          ? AlignmentDirectional.centerStart
                          : AlignmentDirectional.centerEnd,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color:
                              m.mine ? AppTheme.primary : AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(m.text,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(),
                      ),
                    ),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
         ), 
          );
  }
}
