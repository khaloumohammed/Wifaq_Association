import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final lastError = ValueNotifier<String?>(null);

  void reportError(Object error, StackTrace stack) {
    final msg = '$error\n\n$stack';
    lastError.value = msg;
    if (kDebugMode) {
      print(msg);
    }
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reportError(details.exception, details.stack ?? StackTrace.current);
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    reportError(error, stack);
    return true;
  };

  runApp(MyApp(lastError: lastError));
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatDate(DateTime date) =>
    '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';

String _formatDateTime(DateTime date) =>
    '${_formatDate(date)} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

String _timestamp(DateTime date) =>
    '${date.year}${_twoDigits(date.month)}${_twoDigits(date.day)}_${_twoDigits(date.hour)}${_twoDigits(date.minute)}${_twoDigits(date.second)}';

const String kAppsScriptUrl = String.fromEnvironment('APPS_SCRIPT_URL');
const String kAppsScriptApiKey = String.fromEnvironment('APPS_SCRIPT_API_KEY');

const List<String> kDefaultAssociationObjectives = [
  'ترسيخ ثقافة التضامن وروح العمل التضامني',
  'المساهمة في العمل الجماعي',
  'الإهتمام بالشأن الثقافي بكل أبعاه وفق أهداف الجمعية',
  'النهوض بالرياضة والمحافظة على البيئة',
  'التعاون مع المصالح العمومية والجمعيات التي لها نفس الأهداف',
];

const List<(String, String)> kDefaultExecutiveMembers = [
  ('عبد العزيز عاشوري', 'الرئيس'),
  ('مليكة الرابحي', 'النائبة الأولى للرئيس'),
  ('عبد الحفيظ بنساسي', 'النائب الثاني للرئيس'),
  ('بوعرفة شرفي', 'أمين المال'),
  ('محمد لمسلك', 'نائب أمين المال'),
  ('محمد بولحروزي', 'الكاتب العام'),
  ('صالحة الحدادي', 'نائبة الكاتب العام'),
  ('المكي قاسمي', 'مستشار 1'),
  ('محمد الداودي', 'مستشار 2'),
];

const List<(String, String)> kDefaultAchievements = [
  ('2025', 'قافلة تضامنية لفائدة 120 أسرة في المجال القروي.'),
  ('2024', 'برنامج محو الأمية الرقمية لفائدة الشباب.'),
  ('2023', 'تأهيل فضاء تربوي للأطفال وتنظيم أنشطة أسبوعية.'),
  ('2022', 'إطلاق مبادرة "مدرستي أجمل" لتحسين المحيط المدرسي.'),
];

const List<String> kAchievementStatuses = ['done', 'preparing', 'upcoming'];
const Map<String, String> kAchievementStatusLabels = {
  'done': 'الإنجازات المنجزة',
  'preparing': 'الإنجازات قيد التحضير',
  'upcoming': 'الإنجازات القادمة',
};

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.lastError});

  final ValueNotifier<String?> lastError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'جمعية وفاق لزاري للتنمية',
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: ValueListenableBuilder<String?>(
                valueListenable: lastError,
                builder: (context, value, _) {
                  if (value == null || value.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B0A0A).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.8)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Erreur (copie/colle-moi ce message)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 140),
                            child: SingleChildScrollView(
                              child: Text(
                                value,
                                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: value));
                                },
                                child: const Text('Copier', style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => lastError.value = null,
                                child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C8A7B),
          primary: const Color(0xFF0C8A7B),
          secondary: const Color(0xFFE9733A),
          surface: const Color(0xFFF8FBFA),
        ),
      ),
      home: const WifaqApp(),
    );
  }
}

class WifaqApp extends StatelessWidget {
  const WifaqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0C8A7B),
        primary: const Color(0xFF0C8A7B),
        secondary: const Color(0xFFE9733A),
        surface: const Color(0xFFF8FBFA),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'جمعية وفاق لزاري للتنمية',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: base.copyWith(
        textTheme: GoogleFonts.tajawalTextTheme(base.textTheme),
        scaffoldBackgroundColor: const Color(0xFFF6FBF8),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.tajawal(
            color: const Color(0xFF12322D),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF12322D)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.92),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      home: const PostSplashAnimationScreen(),
    );
  }
}

class PostSplashAnimationScreen extends StatefulWidget {
  const PostSplashAnimationScreen({super.key});

  @override
  State<PostSplashAnimationScreen> createState() => _PostSplashAnimationScreenState();
}

class _PostSplashAnimationScreenState extends State<PostSplashAnimationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pulse = 0.92 + (math.sin(t * math.pi * 3) * 0.06);
          final spin = t * math.pi * 2;
          final tilt = math.sin(t * math.pi * 2) * 0.045;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF0A7D70), Color(0xFF12A88F), Color(0xFFE77A45)],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.22 + (0.12 * math.sin(t * math.pi * 2)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0.55 - (t * 0.6), -0.35 + (t * 0.25)),
                          radius: 1.05,
                          colors: [
                            Colors.white.withValues(alpha: 0.32),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 100 - (t * 30),
                right: -40 + (t * 20),
                child: _blob(180, const Color(0x55FFFFFF)),
              ),
              Positioned(
                bottom: 120 - (t * 20),
                left: -50 + (t * 20),
                child: _blob(220, const Color(0x44FFFFFF)),
              ),
              ...List.generate(10, (i) {
                final dx = (i * 37.0) % 340;
                final dy = 90 + ((i * 91.0) % 520);
                final driftX = math.sin((t * math.pi * 2) + i) * 18;
                final driftY = math.cos((t * math.pi * 2) + i) * 22;
                return Positioned(
                  left: 14 + dx + driftX,
                  top: dy + driftY,
                  child: _particle(6 + (i % 4), 0.16 + ((i % 3) * 0.06)),
                );
              }),
              Center(
                child: Transform.scale(
                  scale: pulse,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(tilt * 0.45)
                      ..rotateY(tilt),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (index) {
                          final waveT = ((t + (index * 0.2)) % 1.0);
                          final ringSize = 230 + (waveT * 90);
                          return IgnorePointer(
                            child: Container(
                              width: ringSize,
                              height: ringSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: (1 - waveT) * 0.22),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          );
                        }),
                        Transform.rotate(
                          angle: spin,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.white.withValues(alpha: 0.65),
                                  Colors.white.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 220,
                          height: 220,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset('assets/logo.png', fit: BoxFit.cover),
                                Align(
                                  alignment: Alignment(-1.2 + (t * 2.4), 0),
                                  child: Container(
                                    width: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withValues(alpha: 0.36),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: IgnorePointer(
                  child: Container(
                    width: 310,
                    height: 310,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15 + (0.08 * t)),
                          blurRadius: 48,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 90,
                right: 0,
                left: 0,
                child: Column(
                  children: [
                    Transform.translate(
                      offset: Offset(0, 18 * (1 - t)),
                      child: Opacity(
                        opacity: (t * 1.3).clamp(0, 1),
                        child: const Text(
                          'جمعية وفاق لزاري للتنمية',
                          style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Transform.translate(
                      offset: Offset(0, 24 * (1 - t)),
                      child: Opacity(
                        opacity: (t * 1.15).clamp(0, 1),
                        child: Text(
                          'يد في يد من أجل غد أفضل',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: LinearProgressIndicator(
                          value: t,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.26),
                          valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.95)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.42),
      ),
    );
  }

  Widget _particle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class RegistrationActionsController {
  Future<void> Function()? exportExcel;
  VoidCallback? scrollToForm;
  VoidCallback? scrollToList;
}

class _AdminLoginDialog extends StatefulWidget {
  const _AdminLoginDialog();

  @override
  State<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<_AdminLoginDialog> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _obscureCode = true;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final okEmail = _emailCtrl.text.trim() == 'association@wifaq.lazaret';
    final okCode = _codeCtrl.text.trim() == 'wifaqadmin';
    if (!okEmail || !okCode) {
      setState(() => _errorText = 'بيانات الدخول غير صحيحة');
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ولوج الإدارة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _codeCtrl,
            obscureText: _obscureCode,
            decoration: InputDecoration(
              labelText: 'رمز الولوج',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureCode = !_obscureCode),
                icon: Icon(_obscureCode ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: _obscureCode ? 'إظهار الرمز' : 'إخفاء الرمز',
              ),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorText!,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('دخول'),
        ),
      ],
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _registrationController = RegistrationActionsController();

  int _currentIndex = 0;
  final int _pagesReloadToken = 0;
  bool _isAdminAuthenticated = false;
  List<String> _objectives = kDefaultAssociationObjectives;

  final _titles = const [
    'جمعية وفاق لزاري للتنمية',
    'المكتب التنفيذي',
    'النظام والأهداف',
    'الإنجازات',
    'الانخراط',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await RegistrationRepository.instance.seedExecutiveMembersIfEmpty();
    await RegistrationRepository.instance.seedAchievementsIfEmpty();
    final objectives = await RegistrationRepository.instance.getObjectives();
    if (!mounted) return;
    setState(() {
      _objectives = objectives;
    });
  }

  Future<void> _showAdminLoginDialog() async {
    final didLogin = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _AdminLoginDialog(),
    );

    if (didLogin == true && mounted) {
      setState(() => _isAdminAuthenticated = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول كإدارة')),
      );
    }
  }

  Future<void> _showManifestationDialog() async {
    final titleCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? photoPath;
    XFile? photoFile;
    final picker = ImagePicker();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: const Text('إضافة تظاهرة مع صورة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'عنوان التظاهرة'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: detailsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'تفاصيل'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'التاريخ: ${_formatDate(selectedDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: selectedDate,
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: const Text('اختيار'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (picked == null) return;
                      setModalState(() {
                        photoPath = picked.path;
                        photoFile = picked;
                      });
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('إرفاق صورة'),
                  ),
                  if (photoPath != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: (kIsWeb && photoFile != null)
                            ? FutureBuilder<Uint8List>(
                                future: photoFile!.readAsBytes(),
                                builder: (context, snap) {
                                  if (snap.connectionState != ConnectionState.done) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final data = snap.data;
                                  if (data == null || data.isEmpty) {
                                    return const Center(child: Text('الصورة غير متاحة'));
                                  }
                                  return Image.memory(
                                    data,
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : (photoPath!.startsWith('http://') ||
                                    photoPath!.startsWith('https://') ||
                                    photoPath!.startsWith('blob:') ||
                                    kIsWeb)
                                ? Image.network(
                                    photoPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(child: Text('الصورة غير متاحة')),
                                  )
                                : Image.file(
                                    File(photoPath!),
                                    fit: BoxFit.cover,
                                  ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إدخال عنوان التظاهرة')),
                    );
                    return;
                  }
                  await RegistrationRepository.instance.insertManifestation(
                    Manifestation(
                      title: titleCtrl.text.trim(),
                      details: detailsCtrl.text.trim(),
                      date: selectedDate,
                      photoPath: photoPath ?? '',
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ التظاهرة بنجاح')),
                    );
                  }
                  if (!mounted) return;
                  Navigator.of(this.context).pop();
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );

    titleCtrl.dispose();
    detailsCtrl.dispose();
  }

  Future<void> _showEditObjectivesDialog() async {
    final ctrl = TextEditingController(text: _objectives.join('\n'));
    String? errorText;
    final didSave = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('تعديل أهداف الجمعية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'ضع كل هدف في سطر',
                  alignLabelWithHint: true,
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final parsed = ctrl.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                if (parsed.isEmpty) {
                  setModalState(() => errorText = 'الرجاء إدخال هدف واحد على الأقل');
                  return;
                }
                await RegistrationRepository.instance.saveObjectives(parsed);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();

    if (didSave == true) {
      final objectives = await RegistrationRepository.instance.getObjectives();
      if (!mounted) return;
      setState(() => _objectives = objectives);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث أهداف الجمعية')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(key: ValueKey('home_$_pagesReloadToken')),
      ExecutivePage(
        key: ValueKey('exec_$_pagesReloadToken'),
        isAdmin: _isAdminAuthenticated,
      ),
      StatuteGoalsPage(
        key: ValueKey('goals_$_pagesReloadToken'),
        objectives: _objectives,
        isAdmin: _isAdminAuthenticated,
        onEditObjectives: _showEditObjectivesDialog,
      ),
      AchievementsPage(
        key: ValueKey('achv_$_pagesReloadToken'),
        isAdmin: _isAdminAuthenticated,
      ),
      RegistrationPage(
        key: ValueKey('reg_$_pagesReloadToken'),
        controller: _registrationController,
        isAdmin: _isAdminAuthenticated,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            tooltip: _isAdminAuthenticated ? 'حساب الإدارة' : 'تسجيل دخول الإدارة',
            onPressed: () {
              if (_isAdminAuthenticated) {
                _scaffoldKey.currentState?.openDrawer();
                return;
              }
              _showAdminLoginDialog();
            },
            icon: Icon(
              _isAdminAuthenticated ? Icons.verified_user_outlined : Icons.account_circle_outlined,
            ),
          ),
        ],
      ),
      drawer: _isAdminAuthenticated
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('لوحة الإدارة'),
                      subtitle: const Text('association@wifaq.lazaret'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.list_alt_outlined),
                      title: const Text('لائحة طلبات الانخراط'),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 4);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _registrationController.scrollToList?.call();
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      title: const Text('إضافة طلب انخراط'),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 4);
                        _registrationController.scrollToForm?.call();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.table_view_outlined),
                      title: const Text('تصدير لائحة الانخراط'),
                      onTap: () {
                        Navigator.pop(context);
                        _registrationController.exportExcel?.call();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.add_photo_alternate_outlined),
                      title: const Text('إضافة صورة لتظاهرة'),
                      onTap: () {
                        Navigator.pop(context);
                        _showManifestationDialog();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('تسجيل الخروج'),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _isAdminAuthenticated = false);
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          const Positioned.fill(child: PlasmaBackground()),
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'المكتب'),
          NavigationDestination(icon: Icon(Icons.description_outlined), label: 'النظام'),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            label: 'الإنجازات',
          ),
          NavigationDestination(icon: Icon(Icons.app_registration), label: 'الانخراط'),
        ],
      ),
    );
  }
}

class PlasmaBackground extends StatelessWidget {
  const PlasmaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlasmaPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _PlasmaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFEAF8F4), Color(0xFFFDF3EA)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    final blobPaint1 = Paint()..color = const Color(0xFF8BD7C7).withValues(alpha: 0.24);
    final blobPaint2 = Paint()..color = const Color(0xFFF8B486).withValues(alpha: 0.22);
    final blobPaint3 = Paint()..color = const Color(0xFF3BB6A2).withValues(alpha: 0.12);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.2, size.height * 0.18),
        width: size.width * 0.85,
        height: size.height * 0.25,
      ),
      blobPaint1,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.85, size.height * 0.42),
        width: size.width * 0.75,
        height: size.height * 0.2,
      ),
      blobPaint2,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.88),
        width: size.width * 1.05,
        height: size.height * 0.2,
      ),
      blobPaint3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'يد في يد من أجل غد أفضل',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10),
              Text(
                'تطبيق جمعية وفاق لزاري للتنمية يعرّف برسالتنا ويتيح لك الانخراط بسهولة في مبادراتنا.',
                style: TextStyle(fontSize: 17, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _StatsRow(),
        const SizedBox(height: 14),
        const _SectionIntro(
          title: 'عن الجمعية',
          content:
              'جمعية مدنية تعمل على تمكين الشباب، دعم الأسر، وتعزيز التضامن المحلي عبر برامج اجتماعية وتربوية مستمرة.',
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatCard(value: '4', label: 'مبادرة')),
        SizedBox(width: 10),
        Expanded(child: _StatCard(value: '150', label: 'مستفيد')),
        SizedBox(width: 10),
        Expanded(child: _StatCard(value: '25', label: 'متطوع')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0C8A7B),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class ExecutivePage extends StatefulWidget {
  const ExecutivePage({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  @override
  State<ExecutivePage> createState() => _ExecutivePageState();
}

class _ExecutivePageState extends State<ExecutivePage> {
  final _imagePicker = ImagePicker();
  late Future<List<ExecutiveMember>> _membersFuture;
  int _reloadToken = 0;
  bool _syncingCloud = false;

  void _showFullScreenImage(String path) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      path,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'تعذر عرض الصورة',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMembers();
  }

  Future<List<ExecutiveMember>> _loadMembers() => RegistrationRepository.instance.getExecutiveMembers();

  Future<void> _refresh() async {
    setState(() {
      _reloadToken++;
      _membersFuture = _loadMembers();
    });
  }

  Future<void> _showMemberDialog({ExecutiveMember? member, required int orderIndex}) async {
    final formResult = await showDialog<_ExecutiveMemberFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _ExecutiveMemberDialog(
        imagePicker: _imagePicker,
        initialName: member?.name ?? '',
        initialRole: member?.role ?? '',
        initialPhotoPath: member?.photoPath ?? '',
        title: member == null ? 'إضافة عضو للمكتب التنفيذي' : 'تعديل عضو المكتب التنفيذي',
      ),
    );
    if (formResult == null) return;
    
    try {
      if (kIsWeb && formResult.photoFile != null) {
        CloudSyncService.instance._tempWebPhotoFile = formResult.photoFile;
      }
      if (member == null) {
        await RegistrationRepository.instance.insertExecutiveMember(
          ExecutiveMember(
            name: formResult.name,
            role: formResult.role,
            orderIndex: orderIndex,
            photoPath: formResult.photoPath,
          ),
        );
      } else {
        await RegistrationRepository.instance.updateExecutiveMember(
          member.copyWith(
            name: formResult.name,
            role: formResult.role,
            photoPath: formResult.photoPath,
          ),
        );
      }
      
      if (!mounted) return;
      
      // Clear cloud sync queue
      await CloudSyncService.instance.flushSync();
      await _refresh();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ العضو بنجاح'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (kIsWeb) {
        CloudSyncService.instance._tempWebPhotoFile = null;
      }
    }
  }

  Future<void> _deleteMember(ExecutiveMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف عضو'),
        content: Text('هل تريد حذف "${member.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await RegistrationRepository.instance.deleteExecutiveMember(member.id);
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _saveToCloud() async {
    if (_syncingCloud) return;
    setState(() => _syncingCloud = true);
    await _refresh();
    if (!mounted) return;
    setState(() => _syncingCloud = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يتم الحفظ مباشرة في Google Sheets')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (widget.isAdmin) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _syncingCloud ? null : _saveToCloud,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(_syncingCloud ? 'جاري الحفظ...' : 'حفظ السحابة'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final members = await RegistrationRepository.instance.getExecutiveMembers();
                      if (!mounted) return;
                      await _showMemberDialog(orderIndex: members.length + 1);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('خطأ: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('إضافة عضو'),
                ),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          FutureBuilder<List<ExecutiveMember>>(
            key: ValueKey(_reloadToken),
            future: _membersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              }
              final members = snapshot.data ?? const [];
              if (members.isEmpty) {
                return const _GlassCard(
                  child: Text('لا توجد بيانات للمكتب التنفيذي', style: TextStyle(fontSize: 16)),
                );
              }
              return Column(
                children: List.generate(members.length, (index) {
                  final item = members[index];
                  final normalizedPhotoUrl = (() {
                    final raw = item.photoPath.trim();
                    if (raw.isEmpty) return '';
                    String? id;
                    if (raw.contains('drive.google.com/uc?') && raw.contains('id=')) {
                      id = Uri.tryParse(raw)?.queryParameters['id'];
                    } else if (raw.contains('drive.google.com/open') && raw.contains('id=')) {
                      id = Uri.tryParse(raw)?.queryParameters['id'];
                    } else if (raw.contains('drive.google.com/thumbnail') && raw.contains('id=')) {
                      id = Uri.tryParse(raw)?.queryParameters['id'];
                    } else if (raw.contains('drive.google.com/file/d/')) {
                      final match = RegExp(r'drive\\.google\\.com/file/d/([^/]+)').firstMatch(raw);
                      id = match?.group(1);
                    }
                    if (id != null && id.isNotEmpty) {
                      return 'https://lh3.googleusercontent.com/d/$id=w400';
                    }
                    return raw;
                  })();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GlassCard(
                      child: Row(
                        children: [
                          normalizedPhotoUrl.isNotEmpty
                              ? InkWell(
                                  onTap: () => _showFullScreenImage(normalizedPhotoUrl),
                                  borderRadius: BorderRadius.circular(14),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      normalizedPhotoUrl,
                                      key: ValueKey('exec-${item.id}-$normalizedPhotoUrl'),
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => CircleAvatar(
                                        radius: 24,
                                        backgroundColor: const Color(0xFF0C8A7B).withValues(alpha: 0.14),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Color(0xFF0C8A7B),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF0C8A7B).withValues(alpha: 0.14),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF0C8A7B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(item.role, style: const TextStyle(fontSize: 16, color: Color(0xFF2C4D48))),
                                if (widget.isAdmin) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: index == 0
                                            ? null
                                            : () async {
                                                await RegistrationRepository.instance.moveExecutiveMember(
                                                  item.id ?? -1,
                                                  up: true,
                                                );
                                                if (!mounted) return;
                                                await _refresh();
                                              },
                                        icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                                        label: const Text('أعلى'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: index == members.length - 1
                                            ? null
                                            : () async {
                                                await RegistrationRepository.instance.moveExecutiveMember(
                                                  item.id ?? -1,
                                                  up: false,
                                                );
                                                if (!mounted) return;
                                                await _refresh();
                                              },
                                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                        label: const Text('أسفل'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _showMemberDialog(member: item, orderIndex: item.orderIndex),
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        label: const Text('تعديل'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _deleteMember(item),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade700,
                                        ),
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        label: const Text('حذف'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExecutiveMemberFormResult {
  const _ExecutiveMemberFormResult({
    required this.name,
    required this.role,
    required this.photoPath,
    this.photoFile,
  });

  final String name;
  final String role;
  final String photoPath;
  final XFile? photoFile;
}

class _ExecutiveMemberDialog extends StatefulWidget {
  const _ExecutiveMemberDialog({
    required this.imagePicker,
    required this.initialName,
    required this.initialRole,
    required this.initialPhotoPath,
    required this.title,
  });

  final ImagePicker imagePicker;
  final String initialName;
  final String initialRole;
  final String initialPhotoPath;
  final String title;

  @override
  State<_ExecutiveMemberDialog> createState() => _ExecutiveMemberDialogState();
}

class _ExecutiveMemberDialogState extends State<_ExecutiveMemberDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _roleCtrl;
  late String _photoPath;
  XFile? _photoFile;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _roleCtrl = TextEditingController(text: widget.initialRole);
    _photoPath = widget.initialPhotoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await widget.imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _photoPath = picked.path;
      _photoFile = picked;
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final role = _roleCtrl.text.trim();
    if (name.isEmpty || role.isEmpty) {
      setState(() => _errorText = 'الرجاء إدخال الاسم والصفة');
      return;
    }
    Navigator.of(context).pop(
      _ExecutiveMemberFormResult(
        name: name,
        role: role,
        photoPath: _photoPath,
        photoFile: _photoFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _roleCtrl,
                decoration: const InputDecoration(labelText: 'الصفة'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_photoPath.isEmpty ? 'استيراد صورة' : 'تغيير الصورة'),
              ),
              if (_photoPath.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _photoPath = '';
                    _photoFile = null;
                  }),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف الصورة'),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 280,
                    height: 130,
                    child: (kIsWeb && _photoFile != null)
                        ? FutureBuilder<Uint8List>(
                            future: _photoFile!.readAsBytes(),
                            builder: (context, snap) {
                              if (snap.connectionState != ConnectionState.done) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final data = snap.data;
                              if (data == null || data.isEmpty) {
                                return const Center(child: Text('الصورة غير متاحة'));
                              }
                              return Image.memory(
                                data,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : (_photoPath.startsWith('http://') ||
                                _photoPath.startsWith('https://') ||
                                _photoPath.startsWith('blob:') ||
                                kIsWeb)
                            ? Image.network(
                                _photoPath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Text('الصورة غير متاحة')),
                              )
                            : Image.file(
                                File(_photoPath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Text('الصورة غير متاحة')),
                              ),
                  ),
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _AchievementPhotosViewerDialog extends StatefulWidget {
  const _AchievementPhotosViewerDialog({
    required this.achievement,
    required this.initialIndex,
    required this.isAdmin,
  });

  final Achievement achievement;
  final int initialIndex;
  final bool isAdmin;

  @override
  State<_AchievementPhotosViewerDialog> createState() => _AchievementPhotosViewerDialogState();
}

class _AchievementPhotosViewerDialogState extends State<_AchievementPhotosViewerDialog> {
  late final PageController _pageController;
  late List<AchievementPhoto> _photos;
  late int _currentIndex;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _photos = List<AchievementPhoto>.from(widget.achievement.photos);
    _currentIndex = widget.initialIndex.clamp(0, _photos.isEmpty ? 0 : _photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteCurrentPhoto() async {
    if (!widget.isAdmin || _photos.isEmpty || _deleting) return;
    final photo = _photos[_currentIndex];
    if (photo.id == null || widget.achievement.id == null) return;
    setState(() => _deleting = true);
    await RegistrationRepository.instance.deleteAchievementPhoto(
      achievementId: widget.achievement.id!,
      photoId: photo.id!,
    );
    if (!mounted) return;
    final newPhotos = List<AchievementPhoto>.from(_photos)..removeAt(_currentIndex);
    setState(() {
      _photos = newPhotos;
      if (_photos.isEmpty) {
        _currentIndex = 0;
      } else if (_currentIndex >= _photos.length) {
        _currentIndex = _photos.length - 1;
      }
      _deleting = false;
    });
    if (_photos.isEmpty) {
      Navigator.of(context).pop(true);
      return;
    }
    _pageController.jumpToPage(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: _photos.isEmpty
                  ? const Center(
                      child: Text('لا توجد صور', style: TextStyle(color: Colors.white)),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _photos.length,
                      onPageChanged: (value) => setState(() => _currentIndex = value),
                      itemBuilder: (context, index) {
                        final photo = _photos[index];
                        return InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4,
                          child: Center(
                            child: Image.network(
                              photo.path,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.white,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => const Text(
                                'تعذر عرض الصورة',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            if (widget.isAdmin)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: _deleting ? null : _deleteCurrentPhoto,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AchievementFormResult {
  const _AchievementFormResult({
    required this.year,
    required this.description,
  });

  final String year;
  final String description;
}

class _AchievementEditorDialog extends StatefulWidget {
  const _AchievementEditorDialog({
    required this.title,
    required this.initialYear,
    required this.initialDescription,
  });

  final String title;
  final String initialYear;
  final String initialDescription;

  @override
  State<_AchievementEditorDialog> createState() => _AchievementEditorDialogState();
}

class _AchievementEditorDialogState extends State<_AchievementEditorDialog> {
  late final TextEditingController _yearCtrl;
  late final TextEditingController _descCtrl;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _yearCtrl = TextEditingController(text: widget.initialYear);
    _descCtrl = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final year = _yearCtrl.text.trim();
    final description = _descCtrl.text.trim();
    if (year.isEmpty || description.isEmpty) {
      setState(() => _errorText = 'الرجاء إدخال السنة والوصف');
      return;
    }
    Navigator.of(context).pop(
      _AchievementFormResult(
        year: year,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السنة'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'وصف الإنجاز'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class StatuteGoalsPage extends StatelessWidget {
  const StatuteGoalsPage({
    super.key,
    required this.objectives,
    required this.isAdmin,
    required this.onEditObjectives,
  });

  final List<String> objectives;
  final bool isAdmin;
  final Future<void> Function() onEditObjectives;

  @override
  Widget build(BuildContext context) {
    final objectivesText = List.generate(
      objectives.length,
      (i) => '${i + 1}) ${objectives[i]}',
    ).join('\n');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        const _SectionIntro(
          title: 'النظام الأساسي',
          content:
              'تشتغل الجمعية وفق مبادئ الشفافية، التطوع، المساواة، واحترام القوانين المنظمة للعمل الجمعوي، مع اعتماد حكامة تشاركية في اتخاذ القرار.',
        ),
        const SizedBox(height: 10),
        _SectionIntro(
          title: 'الأهداف',
          content: objectivesText,
        ),
        if (isAdmin) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onEditObjectives,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل الأهداف'),
            ),
          ),
        ],
      ],
    );
  }
}

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _imagePicker = ImagePicker();
  String _currentStatus = kAchievementStatuses.first;
  late Future<List<Achievement>> _itemsFuture;
  int _reloadToken = 0;
  bool _syncingCloud = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<List<Achievement>> _loadItems() =>
      RegistrationRepository.instance.getAchievements(status: _currentStatus);

  Future<void> _refresh() async {
    setState(() {
      _reloadToken++;
      _itemsFuture = _loadItems();
    });
  }

  Future<void> _showAchievementDialog({Achievement? item}) async {
    final formResult = await showDialog<_AchievementFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _AchievementEditorDialog(
        title: item == null ? 'إضافة إنجاز' : 'تعديل إنجاز',
        initialYear: item?.year ?? '',
        initialDescription: item?.description ?? '',
      ),
    );

    if (formResult != null) {
      if (item == null) {
        await RegistrationRepository.instance.insertAchievement(
          Achievement(
            year: formResult.year,
            description: formResult.description,
            status: _currentStatus,
            orderIndex: 0,
          ),
        );
      } else {
        await RegistrationRepository.instance.updateAchievement(
          item.copyWith(
            year: formResult.year,
            description: formResult.description,
            status: _currentStatus,
          ),
        );
      }
      if (mounted) {
        await _refresh();
      }
    }
  }

  Future<void> _deleteAchievement(Achievement item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الإنجاز'),
        content: const Text('هل تريد حذف هذا الإنجاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await RegistrationRepository.instance.deleteAchievement(item.id);
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _addAchievementPhotos(Achievement item) async {
    if (item.id == null) return;
    final picked = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    final paths = picked.map((e) => e.path).toList();
    await RegistrationRepository.instance.addAchievementPhotos(
      item.id!,
      paths,
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openAchievementPhotosViewer(Achievement item, int initialIndex) async {
    final didChange = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _AchievementPhotosViewerDialog(
        achievement: item,
        initialIndex: initialIndex,
        isAdmin: widget.isAdmin,
      ),
    );
    if (didChange == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _saveToCloud() async {
    if (_syncingCloud) return;
    setState(() => _syncingCloud = true);
    await _refresh();
    if (!mounted) return;
    setState(() => _syncingCloud = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يتم الحفظ مباشرة في Google Sheets')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: kAchievementStatuses.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TabBar(
              isScrollable: true,
              onTap: (index) {
                _currentStatus = kAchievementStatuses[index];
                _refresh();
              },
              tabs: kAchievementStatuses
                  .map((s) => Tab(text: kAchievementStatusLabels[s] ?? s))
                  .toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  if (widget.isAdmin) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _syncingCloud ? null : _saveToCloud,
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: Text(_syncingCloud ? 'جاري الحفظ...' : 'حفظ السحابة'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showAchievementDialog(),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('إضافة إنجاز'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('تحديث'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  FutureBuilder<List<Achievement>>(
                    key: ValueKey('${_reloadToken}_$_currentStatus'),
                    future: _itemsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                      }
                      final items = snapshot.data ?? const [];
                      if (items.isEmpty) {
                        return const _GlassCard(
                          child: Text('لا توجد إنجازات بعد', style: TextStyle(fontSize: 16)),
                        );
                      }
                      return Column(
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GlassCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F6F2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      item.year,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                                          if (item.photos.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              height: 150,
                                              child: PageView.builder(
                                                itemCount: item.photos.length,
                                                controller: PageController(viewportFraction: 0.92),
                                                itemBuilder: (context, photoIndex) {
                                                  final photo = item.photos[photoIndex];
                                                  return Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(12),
                                                      onTap: () => _openAchievementPhotosViewer(item, photoIndex),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: Image.network(
                                                          photo.path,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Container(
                                                              color: const Color(0xFFEAF2F0),
                                                              alignment: Alignment.center,
                                                              child: const CircularProgressIndicator(),
                                                            );
                                                          },
                                                          errorBuilder: (_, __, ___) => Container(
                                                            color: const Color(0xFFEAF2F0),
                                                            alignment: Alignment.center,
                                                            child: const Text('تعذر عرض الصورة'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                          if (widget.isAdmin) ...[
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: index == 0
                                                      ? null
                                                      : () async {
                                                          await RegistrationRepository.instance.moveAchievement(
                                                            item.id ?? -1,
                                                            status: _currentStatus,
                                                            up: true,
                                                          );
                                                          if (!mounted) return;
                                                          await _refresh();
                                                        },
                                                  icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                                                  label: const Text('أعلى'),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: index == items.length - 1
                                                      ? null
                                                      : () async {
                                                          await RegistrationRepository.instance.moveAchievement(
                                                            item.id ?? -1,
                                                            status: _currentStatus,
                                                            up: false,
                                                          );
                                                          if (!mounted) return;
                                                          await _refresh();
                                                        },
                                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                                  label: const Text('أسفل'),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () => _addAchievementPhotos(item),
                                                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                                                  label: const Text('صور تذكارية'),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () => _showAchievementDialog(item: item),
                                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                                  label: const Text('تعديل'),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () => _deleteAchievement(item),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red.shade700,
                                                  ),
                                                  icon: const Icon(Icons.delete_outline, size: 18),
                                                  label: const Text('حذف'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    },
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

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({
    super.key,
    required this.controller,
    required this.isAdmin,
  });

  final RegistrationActionsController controller;
  final bool isAdmin;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _listSectionKey = GlobalKey();
  final _listScrollCtrl = ScrollController();
  final _imagePicker = ImagePicker();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedPhotoPath;
  XFile? _selectedPhotoFile; // Store XFile for web platform
  bool _wantsMembershipCard = false;
  List<MemberRegistration> _cachedItems = const [];

  bool _saving = false;
  bool _exporting = false;
  late Future<List<MemberRegistration>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
    widget.controller.exportExcel = _exportExcel;
    widget.controller.scrollToForm = _scrollToForm;
    widget.controller.scrollToList = _scrollToList;
  }

  Future<List<MemberRegistration>> _loadItems() async {
    final rows = await RegistrationRepository.instance.getAll();
    _cachedItems = rows;
    return rows;
  }

  Future<void> _refresh() async {
    setState(() => _itemsFuture = _loadItems());
  }

  void _scrollToForm() {
    if (!_listScrollCtrl.hasClients) return;
    _listScrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToList() {
    final listContext = _listSectionKey.currentContext;
    if (listContext == null) return;
    Scrollable.ensureVisible(
      listContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _pickMembershipPhoto() async {
    if (kDebugMode) {
      print('[Registration] Opening image picker');
    }
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) {
      if (kDebugMode) {
        print('[Registration] No image selected');
      }
      return;
    }
    if (kDebugMode) {
      print('[Registration] Image selected: ${picked.path}');
      print('[Registration] Image name: ${picked.name}');
    }
    setState(() {
      _selectedPhotoPath = picked.path;
      _selectedPhotoFile = picked; // Store XFile for web
    });
  }

  Future<void> _editMember(MemberRegistration entry) async {
    final fullNameCtrl = TextEditingController(text: entry.fullName);
    final phoneCtrl = TextEditingController(text: entry.phone);
    final emailCtrl = TextEditingController(text: entry.email);
    final cityCtrl = TextEditingController(text: entry.city);
    final notesCtrl = TextEditingController(text: entry.notes);
    String photoPath = entry.photoPath;
    bool wantsCard = entry.wantsMembershipCard;
    String? errorText;

    final didSave = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('تعديل بيانات العضو'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: 'المدينة'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: wantsCard,
                  onChanged: (v) => setModalState(() => wantsCard = v ?? false),
                  title: const Text('طلب بطاقة الانخراط'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (picked == null) return;
                    setModalState(() => photoPath = picked.path);
                  },
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(photoPath.isEmpty ? 'إضافة صورة' : 'تغيير الصورة'),
                ),
                if (photoPath.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => setModalState(() => photoPath = ''),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('حذف الصورة'),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (photoPath.startsWith('http://') || photoPath.startsWith('https://') || photoPath.startsWith('blob:') || kIsWeb)
                        ? Image.network(
                            photoPath,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 120,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Text('الصورة غير متاحة'),
                          )
                        : Image.file(
                            File(photoPath),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Text('الصورة غير متاحة'),
                          ),
                  ),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final fullName = fullNameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final city = cityCtrl.text.trim();
                final notes = notesCtrl.text.trim();
                if (fullName.length < 4 || phone.length < 8 || city.isEmpty) {
                  setModalState(() => errorText = 'الرجاء إدخال بيانات صحيحة');
                  return;
                }
                final okEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
                if (!okEmail) {
                  setModalState(() => errorText = 'بريد إلكتروني غير صالح');
                  return;
                }
                await RegistrationRepository.instance.update(
                  entry.copyWith(
                    fullName: fullName,
                    phone: phone,
                    email: email,
                    city: city,
                    notes: notes,
                    photoPath: photoPath,
                    wantsMembershipCard: wantsCard,
                  ),
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );

    fullNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    cityCtrl.dispose();
    notesCtrl.dispose();

    if (didSave == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث بيانات العضو')),
      );
      await _refresh();
    }
  }

  Future<void> _deleteMember(MemberRegistration entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف العضو'),
        content: Text('هل تريد حذف "${entry.fullName}" من لائحة الأعضاء؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final old = _cachedItems;
    final updated = old.where((e) => e.id != entry.id).toList();
    setState(() {
      _cachedItems = updated;
      _itemsFuture = Future.value(updated);
    });
    await RegistrationRepository.instance.delete(entry.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف العضو')),
    );
    await _refresh();
  }

  Future<void> _submit() async {
    if (kDebugMode) {
      print('[Registration] Submit button clicked');
    }
    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print('[Registration] Form validation failed');
      }
      return;
    }
    if (kDebugMode) {
      print('[Registration] Form validated, starting submission');
      print('[Registration] Photo path: $_selectedPhotoPath');
    }
    setState(() => _saving = true);
    try {
      // Store XFile temporarily for web platform
      if (kIsWeb && _selectedPhotoFile != null) {
        CloudSyncService.instance._tempWebPhotoFile = _selectedPhotoFile;
      }
      
      await RegistrationRepository.instance.insert(
        MemberRegistration(
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          photoPath: _selectedPhotoPath ?? '',
          wantsMembershipCard: _wantsMembershipCard,
          createdAt: DateTime.now(),
        ),
      );
      
      // Clear temporary XFile
      if (kIsWeb) {
        CloudSyncService.instance._tempWebPhotoFile = null;
      }
      if (kDebugMode) {
        print('[Registration] Member inserted successfully');
      }
      _fullNameCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      _cityCtrl.clear();
      _notesCtrl.clear();
      _selectedPhotoPath = null;
      _selectedPhotoFile = null;
      _wantsMembershipCard = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل طلب الانخراط بنجاح')),
        );
      }
      await _refresh();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final records = await RegistrationRepository.instance.getAll();
      if (records.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد بيانات للتصدير حالياً')),
          );
        }
        return;
      }

      final excel = ex.Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? 'Inscriptions';
      final sheet = excel[sheetName];
      sheet.appendRow([
        ex.TextCellValue('الاسم الكامل'),
        ex.TextCellValue('الهاتف'),
        ex.TextCellValue('البريد الإلكتروني'),
        ex.TextCellValue('المدينة'),
        ex.TextCellValue('ملاحظات'),
        ex.TextCellValue('طلب بطاقة الانخراط'),
        ex.TextCellValue('مسار الصورة'),
        ex.TextCellValue('تاريخ التسجيل'),
      ]);

      for (final entry in records) {
        sheet.appendRow([
          ex.TextCellValue(entry.fullName),
          ex.TextCellValue(entry.phone),
          ex.TextCellValue(entry.email),
          ex.TextCellValue(entry.city),
          ex.TextCellValue(entry.notes),
          ex.TextCellValue(entry.wantsMembershipCard ? 'نعم' : 'لا'),
          ex.TextCellValue(entry.photoPath),
          ex.TextCellValue(_formatDateTime(entry.createdAt)),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('فشل إنشاء ملف Excel');
      }

      final dir = await getTemporaryDirectory();
      final timestamp = _timestamp(DateTime.now());
      final filePath = p.join(dir.path, 'wifaq_inscriptions_$timestamp.xlsx');
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'تصدير استمارات الانخراط - جمعية وفاق لزاري للتنمية',
          subject: 'Inscriptions Wifaq',
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التصدير: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.exportExcel = null;
    widget.controller.scrollToForm = null;
    widget.controller.scrollToList = null;
    _listScrollCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _listScrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('استمارة الانخراط', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _field(
                    controller: _fullNameCtrl,
                    label: 'الاسم الكامل',
                    validator: (value) => (value == null || value.trim().length < 4)
                        ? 'الرجاء إدخال الاسم الكامل'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: _phoneCtrl,
                    label: 'رقم الهاتف',
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value == null || value.trim().length < 8)
                        ? 'رقم الهاتف غير صالح'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: _emailCtrl,
                    label: 'البريد الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = (value ?? '').trim();
                      if (email.isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
                      return ok ? null : 'بريد إلكتروني غير صالح';
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: _cityCtrl,
                    label: 'المدينة',
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'الرجاء إدخال المدينة' : null,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: _notesCtrl,
                    label: 'ملاحظات (اختياري)',
                    maxLines: 3,
                    validator: (_) => null,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _wantsMembershipCard,
                    onChanged: (value) => setState(() => _wantsMembershipCard = value ?? false),
                    title: const Text('أرغب في طلب بطاقة الانخراط'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickMembershipPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(_selectedPhotoPath == null ? 'استيراد صورة' : 'تغيير الصورة'),
                  ),
                  if (_selectedPhotoPath != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(
                              _selectedPhotoPath!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 150,
                                child: Center(child: Text('تعذر عرض الصورة')),
                              ),
                            )
                          : Image.file(
                              File(_selectedPhotoPath!),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_alt),
                    label: Text(_saving ? 'جاري الحفظ...' : 'تسجيل الانخراط'),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 12),
            Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : _exportExcel,
                  icon: const Icon(Icons.table_view),
                  label: Text(_exporting ? 'جاري التصدير...' : 'تصدير إلى Excel'),
                ),
              ),
            ],
            ),
            const SizedBox(height: 10),
            Container(
            key: _listSectionKey,
            alignment: Alignment.centerRight,
            child: const Text(
              'لائحة طلبات الانخراط',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            ),
            const SizedBox(height: 8),
            Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _scrollToForm,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('إضافة'),
              ),
              OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
              ),
              OutlinedButton.icon(
                onPressed: _exporting ? null : _exportExcel,
                icon: const Icon(Icons.download_outlined),
                label: const Text('تصدير'),
              ),
            ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<MemberRegistration>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return const _GlassCard(
                  child: Text('لا توجد طلبات انخراط بعد', style: TextStyle(fontSize: 16)),
                );
              }

              return Column(
                children: items
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _GlassCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              (() {
                                final raw = entry.photoPath.trim();
                                if (raw.isEmpty) {
                                  return Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C8A7B).withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      entry.fullName.isNotEmpty ? entry.fullName[0] : '?',
                                      style: const TextStyle(
                                        color: Color(0xFF0C8A7B),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                }

                                String? id;
                                if (raw.contains('drive.google.com/uc?') && raw.contains('id=')) {
                                  id = Uri.tryParse(raw)?.queryParameters['id'];
                                } else if (raw.contains('drive.google.com/open') && raw.contains('id=')) {
                                  id = Uri.tryParse(raw)?.queryParameters['id'];
                                } else if (raw.contains('drive.google.com/thumbnail') && raw.contains('id=')) {
                                  id = Uri.tryParse(raw)?.queryParameters['id'];
                                } else if (raw.contains('drive.google.com/file/d/')) {
                                  final match = RegExp(r'drive\\.google\\.com/file/d/([^/]+)').firstMatch(raw);
                                  id = match?.group(1);
                                }

                                // Prefer direct image CDN URL (more reliable for Image.network on web)
                                // Falls back to thumbnail URL if we can't extract an id.
                                final normalizedPhotoUrl = (id != null && id.isNotEmpty)
                                    ? 'https://lh3.googleusercontent.com/d/$id=w200'
                                    : raw;

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    normalizedPhotoUrl,
                                    key: ValueKey('reg-${entry.id}-$normalizedPhotoUrl'),
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C8A7B).withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        entry.fullName.isNotEmpty ? entry.fullName[0] : '?',
                                        style: const TextStyle(
                                          color: Color(0xFF0C8A7B),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              })(),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.fullName,
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${entry.phone} - ${entry.city}',
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF35514C)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.email,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF35514C)),
                                    ),
                                    if (entry.notes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.notes,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.wantsMembershipCard
                                          ? 'طلب بطاقة الانخراط: نعم'
                                          : 'طلب بطاقة الانخراط: لا',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF35514C)),
                                    ),
                                    if (entry.photoPath.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: (() {
                                          final raw = entry.photoPath.trim();
                                          if (raw.isEmpty) {
                                            return const SizedBox.shrink();
                                          }

                                          String normalized = raw;
                                          String? id;
                                          if (raw.contains('drive.google.com/uc?') && raw.contains('id=')) {
                                            id = Uri.tryParse(raw)?.queryParameters['id'];
                                          } else if (raw.contains('drive.google.com/open') && raw.contains('id=')) {
                                            id = Uri.tryParse(raw)?.queryParameters['id'];
                                          } else if (raw.contains('drive.google.com/thumbnail') && raw.contains('id=')) {
                                            id = Uri.tryParse(raw)?.queryParameters['id'];
                                          } else if (raw.contains('drive.google.com/file/d/')) {
                                            final match = RegExp(r'drive\\.google\\.com/file/d/([^/]+)').firstMatch(raw);
                                            id = match?.group(1);
                                          }
                                          if (id != null && id.isNotEmpty) {
                                            normalized = 'https://lh3.googleusercontent.com/d/$id=w1000';
                                          }

                                          final isNetworkOrWeb = kIsWeb ||
                                              normalized.startsWith('http://') ||
                                              normalized.startsWith('https://') ||
                                              normalized.startsWith('blob:');

                                          return isNetworkOrWeb
                                              ? Image.network(
                                                  normalized,
                                                  height: 110,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Text(
                                                    'الصورة غير متاحة',
                                                    style: TextStyle(fontSize: 13),
                                                  ),
                                                )
                                              : Image.file(
                                                  File(normalized),
                                                  height: 110,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Text(
                                                    'الصورة غير متاحة على هذا الجهاز',
                                                    style: TextStyle(fontSize: 13),
                                                  ),
                                                );
                                        })(),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _editMember(entry),
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          label: const Text('تعديل'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _deleteMember(entry),
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red.shade700,
                                          ),
                                          label: const Text('حذف'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            ),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.6)),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFDFEFE), Color(0xFFF6FEFB)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C8A7B).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class MemberRegistration {
  const MemberRegistration({
    this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.notes,
    required this.photoPath,
    required this.wantsMembershipCard,
    required this.createdAt,
  });

  final int? id;
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String notes;
  final String photoPath;
  final bool wantsMembershipCard;
  final DateTime createdAt;

  MemberRegistration copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? email,
    String? city,
    String? notes,
    String? photoPath,
    bool? wantsMembershipCard,
    DateTime? createdAt,
  }) {
    return MemberRegistration(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      wantsMembershipCard: wantsMembershipCard ?? this.wantsMembershipCard,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'city': city,
        'notes': notes,
        'photoPath': photoPath,
        'wantsMembershipCard': wantsMembershipCard ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MemberRegistration.fromMap(Map<String, Object?> map) => MemberRegistration(
        id: map['id'] as int?,
        fullName: map['fullName'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String? ?? '',
        city: map['city'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        photoPath: map['photoPath'] as String? ?? '',
        wantsMembershipCard: (map['wantsMembershipCard'] as int? ?? 0) == 1,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class Manifestation {
  const Manifestation({
    this.id,
    required this.title,
    required this.details,
    required this.date,
    required this.photoPath,
  });

  final int? id;
  final String title;
  final String details;
  final DateTime date;
  final String photoPath;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'details': details,
        'date': date.toIso8601String(),
        'photoPath': photoPath,
      };

  factory Manifestation.fromMap(Map<String, Object?> map) => Manifestation(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        details: map['details'] as String? ?? '',
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        photoPath: map['photoPath'] as String? ?? '',
      );
}

class ExecutiveMember {
  const ExecutiveMember({
    this.id,
    required this.name,
    required this.role,
    required this.orderIndex,
    required this.photoPath,
  });

  final int? id;
  final String name;
  final String role;
  final int orderIndex;
  final String photoPath;

  ExecutiveMember copyWith({
    int? id,
    String? name,
    String? role,
    int? orderIndex,
    String? photoPath,
  }) {
    return ExecutiveMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      orderIndex: orderIndex ?? this.orderIndex,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'orderIndex': orderIndex,
        'photoPath': photoPath,
      };

  factory ExecutiveMember.fromMap(Map<String, Object?> map) => ExecutiveMember(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        role: map['role'] as String? ?? '',
        orderIndex: map['orderIndex'] as int? ?? 0,
        photoPath: map['photoPath'] as String? ?? '',
      );
}

class Achievement {
  const Achievement({
    this.id,
    required this.year,
    required this.description,
    required this.status,
    required this.orderIndex,
    this.photos = const [],
  });

  final int? id;
  final String year;
  final String description;
  final String status;
  final int orderIndex;
  final List<AchievementPhoto> photos;

  Achievement copyWith({
    int? id,
    String? year,
    String? description,
    String? status,
    int? orderIndex,
    List<AchievementPhoto>? photos,
  }) {
    return Achievement(
      id: id ?? this.id,
      year: year ?? this.year,
      description: description ?? this.description,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
      photos: photos ?? this.photos,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'year': year,
        'description': description,
        'status': status,
        'orderIndex': orderIndex,
      };

  factory Achievement.fromMap(Map<String, Object?> map) => Achievement(
        id: map['id'] as int?,
        year: map['year'] as String? ?? '',
        description: map['description'] as String? ?? '',
        status: map['status'] as String? ?? 'done',
        orderIndex: map['orderIndex'] as int? ?? 0,
      );
}

class AchievementPhoto {
  const AchievementPhoto({
    this.id,
    required this.achievementId,
    required this.path,
    required this.orderIndex,
  });

  final int? id;
  final int achievementId;
  final String path;
  final int orderIndex;

  Map<String, Object?> toMap() => {
        'id': id,
        'achievementId': achievementId,
        'path': path,
        'orderIndex': orderIndex,
      };

  factory AchievementPhoto.fromMap(Map<String, Object?> map) => AchievementPhoto(
        id: map['id'] as int?,
        achievementId: map['achievementId'] as int? ?? 0,
        path: map['path'] as String? ?? '',
        orderIndex: map['orderIndex'] as int? ?? 0,
      );
}

class RegistrationRepository {
  RegistrationRepository._();

  static final RegistrationRepository instance = RegistrationRepository._();

  Future<void> seedExecutiveMembersIfEmpty() async {
    final members = await CloudSyncService.instance.fetchExecutiveMembers();
    if (members.isNotEmpty) return;
    for (var i = 0; i < kDefaultExecutiveMembers.length; i++) {
      final m = kDefaultExecutiveMembers[i];
      await CloudSyncService.instance.insertExecutiveMember(
        ExecutiveMember(
          name: m.$1,
          role: m.$2,
          orderIndex: i + 1,
          photoPath: '',
        ),
      );
    }
  }

  Future<void> seedAchievementsIfEmpty() async {
    final items = await CloudSyncService.instance.fetchAchievements();
    if (items.isNotEmpty) return;
    for (var i = 0; i < kDefaultAchievements.length; i++) {
      final a = kDefaultAchievements[i];
      await CloudSyncService.instance.insertAchievement(
        Achievement(
          year: a.$1,
          description: a.$2,
          status: 'done',
          orderIndex: i + 1,
        ),
      );
    }
  }

  Future<int> insert(MemberRegistration registration) async {
    final id = await CloudSyncService.instance.insertRegistration(registration);
    await CloudSyncService.instance.flushSync();
    return id;
  }

  Future<int> update(MemberRegistration registration) async {
    final result = await CloudSyncService.instance.updateRegistration(registration);
    await CloudSyncService.instance.flushSync();
    return result;
  }

  Future<int> delete(int? id) async {
    if (id == null) return 0;
    return CloudSyncService.instance.deleteRegistration(id);
  }

  Future<List<MemberRegistration>> getAll() async {
    return CloudSyncService.instance.fetchRegistrations();
  }

  Future<List<String>> getObjectives() async {
    final objectives = await CloudSyncService.instance.fetchObjectives();
    return objectives.isEmpty ? kDefaultAssociationObjectives : objectives;
  }

  Future<void> saveObjectives(List<String> objectives, {Object? dbOverride}) async {
    await CloudSyncService.instance.saveObjectives(objectives);
  }

  Future<List<ExecutiveMember>> getExecutiveMembers() async {
    return CloudSyncService.instance.fetchExecutiveMembers();
  }

  Future<int> insertExecutiveMember(ExecutiveMember member) async {
    return CloudSyncService.instance.insertExecutiveMember(member);
  }

  Future<int> updateExecutiveMember(ExecutiveMember member) async {
    return CloudSyncService.instance.updateExecutiveMember(member);
  }

  Future<int> deleteExecutiveMember(int? id) async {
    if (id == null) return 0;
    return CloudSyncService.instance.deleteExecutiveMember(id);
  }

  Future<List<Achievement>> getAchievements({required String status}) async {
    return CloudSyncService.instance.fetchAchievements(status: status);
  }

  Future<List<Achievement>> getAllAchievements() async {
    return CloudSyncService.instance.fetchAchievements();
  }

  Future<List<AchievementPhoto>> getAllAchievementPhotos() async {
    final all = await CloudSyncService.instance.fetchAchievements();
    return all.expand((a) => a.photos).toList();
  }

  Future<int> insertAchievement(Achievement item) async {
    return CloudSyncService.instance.insertAchievement(item);
  }

  Future<int> updateAchievement(Achievement item) async {
    return CloudSyncService.instance.updateAchievement(item);
  }

  Future<int> deleteAchievement(int? id) async {
    if (id == null) return 0;
    return CloudSyncService.instance.deleteAchievement(id);
  }

  Future<void> addAchievementPhotos(int achievementId, List<String> paths) async {
    await CloudSyncService.instance.addAchievementPhotos(achievementId, paths);
  }

  Future<int> deleteAchievementPhoto({
    required int achievementId,
    required int photoId,
  }) async {
    return CloudSyncService.instance.deleteAchievementPhoto(
      achievementId: achievementId,
      photoId: photoId,
    );
  }

  Future<void> moveExecutiveMember(int memberId, {required bool up}) async {
    await CloudSyncService.instance.moveExecutiveMember(memberId, up: up);
  }

  Future<void> moveAchievement(int achievementId, {required String status, required bool up}) async {
    await CloudSyncService.instance.moveAchievement(
      achievementId,
      status: status,
      up: up,
    );
  }

  Future<int> insertManifestation(Manifestation manifestation) async {
    return CloudSyncService.instance.insertManifestation(manifestation);
  }

  Future<List<Manifestation>> getManifestations() async {
    return CloudSyncService.instance.fetchManifestations();
  }

  Future<void> replaceWithCloudSnapshot({
    required List<String> objectives,
    required List<ExecutiveMember> executiveMembers,
    required List<MemberRegistration> registrations,
    required List<Achievement> achievements,
    required List<AchievementPhoto> achievementPhotos,
    required List<Manifestation> manifestations,
  }) async {
    // No-op: Data is cloud-based, no local SQLite storage to replace
  }
}

// Optimized Cloud Sync with batch operations, caching, and retry logic
enum _SyncOperation { insert, update, delete, upsert }

class _QueuedOperation {
  final _SyncOperation operation;
  final String entity;
  final Map<String, dynamic> data;
  final String? id;

  _QueuedOperation({
    required this.operation,
    required this.entity,
    required this.data,
    this.id,
  });
}

class CloudSyncService {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

  // Optimization: Caching
  final Map<String, List<Map<String, dynamic>>> _entityCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(seconds: 30);

  // Optimization: Batch queue for operations
  final List<_QueuedOperation> _operationQueue = [];
  bool _isSyncing = false;
  
  // Debounce timer
  Future<void>? _pendingSync;

  // Optimization: Persistent photo upload cache
  final Map<String, Map<String, String>> _photoCache = {};
  
  // Temporary storage for XFile on web platform
  XFile? _tempWebPhotoFile;

  Uri _buildUri(Map<String, String> query) => Uri.parse(kAppsScriptUrl).replace(queryParameters: query);

  bool get _configured => kAppsScriptUrl.trim().isNotEmpty && kAppsScriptApiKey.trim().isNotEmpty;
  bool get isConfigured => _configured;

  // Optimization: Retry logic with exponential backoff
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
    throw Exception('Operation failed after $maxAttempts attempts');
  }

  Future<Map<String, dynamic>> _postJson(Map<String, dynamic> payload) async {
    return _retryOperation(
      () async {
        if (!_configured) {
          throw Exception(
            'Cloud not configured. Pass these to flutter run:\n'
            '--dart-define=APPS_SCRIPT_URL="your_url"\n'
            '--dart-define=APPS_SCRIPT_API_KEY="your_key"\n'
            'IMPORTANT: Use the /dev URL, not /exec URL for POST requests'
          );
        }
        
        final targetUrl = Uri.parse(kAppsScriptUrl);
        // Web browsers enforce CORS and will send a preflight OPTIONS request
        // for non-simple requests (e.g. application/json or custom headers).
        // Google Apps Script web apps do not reliably support those preflights.
        // To avoid preflight on web, send a "simple" request.
        final headers = kIsWeb
            ? <String, String>{
                'Content-Type': 'text/plain; charset=utf-8',
              }
            : <String, String>{
                'Content-Type': 'application/json',
                'Follow-Redirects': 'false',
              };
        final response = await http.post(
          targetUrl,
          headers: headers,
          body: jsonEncode(payload),
        );
        
        // Log the response for debugging
        if (kDebugMode) {
          print('[CloudSync] POST HTTP ${response.statusCode} to ${targetUrl.host}');
          if (response.body.isNotEmpty) {
            print('[CloudSync] Response: ${response.body.substring(0, math.min(200, response.body.length))}');
          }
        }
        
        // Google Apps Script returns 302 for successful POST to /exec URLs
        // Follow the redirect to get the actual response with data
        if (response.statusCode == 302 || response.statusCode == 301) {
          final location = response.headers['location'];
          if (location != null && location.isNotEmpty) {
            if (kDebugMode) {
              print('[CloudSync] Following redirect to: $location');
            }
            try {
              final redirectResponse = await http.get(Uri.parse(location));
              if (kDebugMode) {
                print('[CloudSync] Redirect response: ${redirectResponse.statusCode}');
                if (redirectResponse.body.isNotEmpty) {
                  print('[CloudSync] Redirect body: ${redirectResponse.body.substring(0, math.min(500, redirectResponse.body.length))}');
                }
              }
              if (redirectResponse.statusCode == 200 && redirectResponse.body.isNotEmpty) {
                try {
                  final decoded = jsonDecode(redirectResponse.body) as Map<String, dynamic>;
                  return decoded;
                } catch (e) {
                  if (kDebugMode) {
                    print('[CloudSync] Failed to parse redirect response as JSON: $e');
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('[CloudSync] Failed to follow redirect: $e');
              }
            }
          }
          // Fallback if redirect fails
          return {'ok': true};
        }
        
        // Accept 2xx as success
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            'HTTP ${response.statusCode}\n'
            'URL: $targetUrl\n'
            'Body: ${response.body.substring(0, math.min(300, response.body.length))}'
          );
        }
        
        // Parse response body
        if (response.body.isEmpty) {
          return {'ok': true}; // Empty 2xx response is success
        }
        
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          
          // Check if explicitly marked as error
          if (decoded['ok'] == false) {
            throw Exception(decoded['error']?.toString() ?? 'Cloud error');
          }
          
          // Return the response (ok field is optional)
          return decoded;
        } on FormatException {
          // Not JSON - treat 2xx as success anyway
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return {'ok': true};
          }
          rethrow;
        }
      },
    );
  }

  // Optimization: Clear expired caches
  void _invalidateCache(String entity) {
    _entityCache.remove(entity);
    _cacheTimestamps.remove(entity);
  }

  bool _isCacheValid(String entity) {
    final timestamp = _cacheTimestamps[entity];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  Future<List<Map<String, dynamic>>> _listEntity(String entity) async {
    // Optimization: Return cached data if valid
    if (_isCacheValid(entity)) {
      return _entityCache[entity] ?? [];
    }

    return _retryOperation(
      () async {
        if (!_configured) {
          throw Exception(
            'Cloud not configured. This endpoint requires:\n'
            '--dart-define=APPS_SCRIPT_URL="your_url"\n'
            '--dart-define=APPS_SCRIPT_API_KEY="your_key"'
          );
        }
        final response = await http.get(_buildUri({'action': 'list', 'entity': entity}));
        
        // Log response
        if (kDebugMode) {
          print('[CloudSync] List $entity: HTTP ${response.statusCode}');
        }
        
        // Accept 2xx and 3xx as success
        if (response.statusCode < 200 || response.statusCode >= 400) {
          throw Exception(
            'HTTP ${response.statusCode}: Failed to list $entity\n'
            'Response: ${response.body.substring(0, math.min(200, response.body.length))}'
          );
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Invalid response');
        }
        if (decoded['ok'] != true) {
          throw Exception(decoded['error']?.toString() ?? 'Cloud error');
        }
        final data = decoded['data'];
        if (data is! List) {
          return const [];
        }
        final result = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        
        // Cache the result
        _entityCache[entity] = result;
        _cacheTimestamps[entity] = DateTime.now();
        
        return result;
      },
    );
  }

  Future<Map<String, String>> _uploadPhotoIfNeeded({
    required String localPath,
    required String entity,
    required Map<String, Map<String, String>> cache,
  }) async {
    final path = localPath.trim();
    if (path.isEmpty) {
      return const {'file_id': '', 'url': ''};
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Skip blob URLs from web - they're already uploaded or being displayed
      if (!path.startsWith('blob:')) {
        return {'file_id': '', 'url': path};
      }
    }
    
    // Optimization: Check persistent cache first
    var cached = _photoCache[path];
    if (cached != null) {
      cache[path] = cached;
      return cached;
    }
    
    // Optimization: Check session cache
    cached = cache[path];
    if (cached != null) return cached;
    
    // Read file bytes - different approach for web vs mobile
    late final Uint8List bytes;
    
    if (kIsWeb && _tempWebPhotoFile != null) {
      // On web, use temporary XFile to read bytes directly
      try {
        bytes = await _tempWebPhotoFile!.readAsBytes();
        if (kDebugMode) {
          print('[CloudSync] Read ${bytes.length} bytes from XFile on web');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[CloudSync] Error reading XFile on web: $e');
        }
        return const {'file_id': '', 'url': ''};
      }
    } else if (kIsWeb) {
      // On web, we must not use dart:io File APIs. If we don't have an XFile,
      // we cannot read bytes safely.
      if (kDebugMode) {
        print('[CloudSync] Missing XFile for web upload; skipping photo upload');
      }
      return const {'file_id': '', 'url': ''};
    } else {
      // On mobile, path is a file path
      final file = File(path);
      if (!await file.exists()) {
        return const {'file_id': '', 'url': ''};
      }
      bytes = await file.readAsBytes();
    }
    final ext = p.extension(path).toLowerCase();
    final mimeType = switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    
    final response = await _retryOperation(
      () => _postJson({
        'apiKey': kAppsScriptApiKey,
        'action': 'uploadImage',
        'entity': entity,
        'fileName': p.basename(path),
        'mimeType': mimeType,
        'base64': base64Encode(bytes),
      }),
      maxAttempts: 3,
    );
    
    // Handle null or missing 'data' field
    if (response == null || response['data'] == null) {
      if (kDebugMode) {
        print('[CloudSync] Photo upload response missing data: $response');
      }
      return const {'file_id': '', 'url': ''};
    }
    
    try {
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};
      
      final result = {
        'file_id': data['file_id']?.toString() ?? '',
        'url': data['url']?.toString() ?? '',
      };
      
      // Optimization: Cache both in session and persistent caches
      cache[path] = result;
      _photoCache[path] = result;
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[CloudSync] Error parsing photo response: $e');
      }
      return const {'file_id': '', 'url': ''};
    }
  }

  // Optimization: Queue operations and batch them
  Future<void> _queueOperation({
    required _SyncOperation operation,
    required String entity,
    required Map<String, dynamic> data,
    String? id,
  }) async {
    _operationQueue.add(_QueuedOperation(
      operation: operation,
      entity: entity,
      data: data,
      id: id,
    ));
    
    // Debounce: Process queue after a short delay
    _pendingSync?.ignore();
    _pendingSync = Future.delayed(const Duration(milliseconds: 500), _processSyncQueue);
  }

  // Optimization: Process batch operations
  Future<void> _processSyncQueue() async {
    if (_isSyncing || _operationQueue.isEmpty) return;
    
    _isSyncing = true;
    try {
      // Group operations by type for efficiency
      final toProcess = List<_QueuedOperation>.from(_operationQueue);
      _operationQueue.clear();
      
      // Group by action type
      final upserts = <String, List<Map<String, dynamic>>>{};
      final deletes = <String, List<String>>{};
      
      for (final op in toProcess) {
        if (op.operation == _SyncOperation.upsert || op.operation == _SyncOperation.insert || op.operation == _SyncOperation.update) {
          upserts.putIfAbsent(op.entity, () => []).add(op.data);
        } else if (op.operation == _SyncOperation.delete) {
          deletes.putIfAbsent(op.entity, () => []).add(op.id ?? '');
        }
      }
      
      // Send batch upserts
      for (final entity in upserts.keys) {
        final data = upserts[entity]!;
        await _postJson({
          'apiKey': kAppsScriptApiKey,
          'action': 'batchUpsert',
          'entity': entity,
          'actor': 'app',
          'data': data, // List of items
        }).catchError((e) {
          // If batch fails, fall back to individual upserts
          return Future.wait(data.map((item) => _postJson({
            'apiKey': kAppsScriptApiKey,
            'action': 'upsert',
            'entity': entity,
            'actor': 'app',
            'data': item,
          }))).then((_) => const {} as Map<String, dynamic>);
        });
        
        // Invalidate cache for this entity
        _invalidateCache(entity);
      }
      
      // Send batch deletes
      for (final entity in deletes.keys) {
        final ids = deletes[entity]!.where((id) => id.isNotEmpty).toList();
        if (ids.isNotEmpty) {
          await _postJson({
            'apiKey': kAppsScriptApiKey,
            'action': 'batchDelete',
            'entity': entity,
            'actor': 'app',
            'ids': ids, // List of IDs
          }).catchError((e) {
            // If batch fails, fall back to individual deletes
            return Future.wait(ids.map((id) => _postJson({
              'apiKey': kAppsScriptApiKey,
              'action': 'delete',
              'entity': entity,
              'actor': 'app',
              'id': id,
            }))).then((_) => const {} as Map<String, dynamic>);
          });
          
          // Invalidate cache for this entity
          _invalidateCache(entity);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _upsertEntity(String entity, Map<String, dynamic> data) async {
    // Optimization: Queue operation for batch processing
    await _queueOperation(
      operation: _SyncOperation.upsert,
      entity: entity,
      data: data,
      id: data['id']?.toString(),
    );
    
    // Wait for queue to process
    if (_pendingSync != null) {
      await _pendingSync!;
    }
  }

  Future<void> _deleteEntity(String entity, String id) async {
    // Optimization: Queue operation for batch processing
    await _queueOperation(
      operation: _SyncOperation.delete,
      entity: entity,
      data: {},
      id: id,
    );
    
    // Wait for queue to process
    if (_pendingSync != null) {
      await _pendingSync!;
    }
  }

  int _newId() => DateTime.now().microsecondsSinceEpoch;

  /// Force immediate synchronization of queued operations
  Future<void> flushSync() async {
    await _pendingSync;
    await _processSyncQueue();
  }

  /// Clear all caches
  void clearCache() {
    _entityCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear photo upload cache
  void clearPhotoCache() {
    _photoCache.clear();
  }

  /// Get sync queue status
  Map<String, dynamic> getSyncStatus() {
    return {
      'queuedOperations': _operationQueue.length,
      'isSyncing': _isSyncing,
      'cacheSize': _entityCache.keys.length,
      'photoCacheSize': _photoCache.keys.length,
    };
  }

  Future<List<String>> fetchObjectives() async {
    final rows = await _listEntity('objectives');
    rows.sort((a, b) => (_toInt(a['order_index']) ?? 0).compareTo(_toInt(b['order_index']) ?? 0));
    return rows
        .where((e) => !_toBool(e['is_deleted']))
        .map((e) => e['text']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> saveObjectives(List<String> objectives) async {
    final currentRows = await _listEntity('objectives');
    final currentIds = currentRows
        .where((e) => !_toBool(e['is_deleted']))
        .map((e) => e['id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    for (var i = 0; i < objectives.length; i++) {
      await _upsertEntity('objectives', {
        'id': 'objective_${i + 1}',
        'text': objectives[i],
        'order_index': i + 1,
        'is_deleted': false,
      });
    }
    final wanted = {for (var i = 0; i < objectives.length; i++) 'objective_${i + 1}'};
    for (final id in currentIds) {
      if (!wanted.contains(id)) {
        await _deleteEntity('objectives', id);
      }
    }
  }

  Future<List<MemberRegistration>> fetchRegistrations() async {
    final rows = await _listEntity('registrations');
    final items = rows
        .where((e) => !_toBool(e['is_deleted']))
        .map(
          (e) => MemberRegistration(
            id: _toInt(e['id']),
            fullName: e['full_name']?.toString() ?? '',
            phone: e['phone']?.toString() ?? '',
            email: e['email']?.toString() ?? '',
            city: e['city']?.toString() ?? '',
            notes: e['notes']?.toString() ?? '',
            photoPath: e['photo_url']?.toString() ?? '',
            wantsMembershipCard: _toBool(e['wants_membership_card']),
            createdAt: DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now(),
          ),
        )
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<int> insertRegistration(MemberRegistration row) async {
    final id = row.id ?? _newId();
    final photo = await _uploadPhotoIfNeeded(
      localPath: row.photoPath,
      entity: 'registrations',
      cache: {},
    );
    await _upsertEntity('registrations', {
      'id': id.toString(),
      'full_name': row.fullName,
      'phone': row.phone,
      'email': row.email,
      'city': row.city,
      'notes': row.notes,
      'wants_membership_card': row.wantsMembershipCard,
      'photo_drive_file_id': photo['file_id'] ?? '',
      'photo_url': photo['url'] ?? '',
      'created_at': row.createdAt.toIso8601String(),
      'is_deleted': false,
    });
    return id;
  }

  Future<int> updateRegistration(MemberRegistration row) async {
    final id = row.id ?? _newId();
    final photo = await _uploadPhotoIfNeeded(
      localPath: row.photoPath,
      entity: 'registrations',
      cache: {},
    );
    await _upsertEntity('registrations', {
      'id': id.toString(),
      'full_name': row.fullName,
      'phone': row.phone,
      'email': row.email,
      'city': row.city,
      'notes': row.notes,
      'wants_membership_card': row.wantsMembershipCard,
      'photo_drive_file_id': photo['file_id'] ?? '',
      'photo_url': photo['url'] ?? '',
      'created_at': row.createdAt.toIso8601String(),
      'is_deleted': false,
    });
    return 1;
  }

  Future<int> deleteRegistration(int id) async {
    await _deleteEntity('registrations', id.toString());
    return 1;
  }

  Future<List<ExecutiveMember>> fetchExecutiveMembers() async {
    final rows = await _listEntity('executive_members');
    final items = rows
        .where((e) => !_toBool(e['is_deleted']))
        .map(
          (e) => ExecutiveMember(
            id: _toInt(e['id']),
            name: e['name']?.toString() ?? '',
            role: e['role']?.toString() ?? '',
            orderIndex: _toInt(e['order_index']) ?? 0,
            photoPath: e['photo_url']?.toString() ?? '',
          ),
        )
        .toList();
    items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return items;
  }

  Future<int> insertExecutiveMember(ExecutiveMember row) async {
    final id = row.id ?? _newId();
    final photo = await _uploadPhotoIfNeeded(
      localPath: row.photoPath,
      entity: 'executive_members',
      cache: {},
    );
    final data = {
      'id': id.toString(),
      'name': row.name,
      'role': row.role,
      'order_index': row.orderIndex,
      'photo_drive_file_id': photo['file_id'] ?? '',
      'photo_url': photo['url'] ?? '',
      'is_deleted': false,
    };
    await _upsertEntity('executive_members', data);
    return id;
  }

  Future<int> updateExecutiveMember(ExecutiveMember row) async {
    final id = row.id ?? _newId();
    final photo = await _uploadPhotoIfNeeded(
      localPath: row.photoPath,
      entity: 'executive_members',
      cache: {},
    );
    await _upsertEntity('executive_members', {
      'id': id.toString(),
      'name': row.name,
      'role': row.role,
      'order_index': row.orderIndex,
      'photo_drive_file_id': photo['file_id'] ?? '',
      'photo_url': photo['url'] ?? '',
      'is_deleted': false,
    });
    return 1;
  }

  Future<int> deleteExecutiveMember(int id) async {
    await _deleteEntity('executive_members', id.toString());
    return 1;
  }

  Future<void> moveExecutiveMember(int memberId, {required bool up}) async {
    final members = await fetchExecutiveMembers();
    final index = members.indexWhere((m) => m.id == memberId);
    if (index == -1) return;
    final targetIndex = up ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= members.length) return;
    final current = members[index];
    final target = members[targetIndex];
    await _upsertEntity('executive_members', {
      'id': (current.id ?? _newId()).toString(),
      'name': current.name,
      'role': current.role,
      'order_index': target.orderIndex,
      'photo_url': current.photoPath,
      'is_deleted': false,
    });
    await _upsertEntity('executive_members', {
      'id': (target.id ?? _newId()).toString(),
      'name': target.name,
      'role': target.role,
      'order_index': current.orderIndex,
      'photo_url': target.photoPath,
      'is_deleted': false,
    });
  }

  Future<List<Achievement>> fetchAchievements({String? status}) async {
    final rows = await _listEntity('achievements');
    final photosRows = await _listEntity('achievement_photos');
    final photoMap = <int, List<AchievementPhoto>>{};
    for (final row in photosRows) {
      if (_toBool(row['is_deleted'])) continue;
      final aid = _toInt(row['achievement_id']) ?? 0;
      if (aid == 0) continue;
      photoMap.putIfAbsent(aid, () => []).add(
            AchievementPhoto(
              id: _toInt(row['id']),
              achievementId: aid,
              path: row['photo_url']?.toString() ?? '',
              orderIndex: _toInt(row['order_index']) ?? 0,
            ),
          );
    }
    final items = rows
        .where((e) => !_toBool(e['is_deleted']))
        .map(
          (e) => Achievement(
            id: _toInt(e['id']),
            year: e['year']?.toString() ?? '',
            description: e['description']?.toString() ?? '',
            status: e['status']?.toString() ?? 'done',
            orderIndex: _toInt(e['order_index']) ?? 0,
            photos: photoMap[_toInt(e['id']) ?? -1] ?? const [],
          ),
        )
        .where((a) => status == null || a.status == status)
        .toList();
    items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return items;
  }

  Future<int> insertAchievement(Achievement row) async {
    final id = row.id ?? _newId();
    final current = await fetchAchievements(status: row.status);
    final maxOrder = current.fold<int>(0, (m, e) => e.orderIndex > m ? e.orderIndex : m);
    await _upsertEntity('achievements', {
      'id': id.toString(),
      'year': row.year,
      'description': row.description,
      'status': row.status,
      'order_index': maxOrder + 1,
      'is_deleted': false,
    });
    return id;
  }

  Future<int> updateAchievement(Achievement row) async {
    final id = row.id ?? _newId();
    await _upsertEntity('achievements', {
      'id': id.toString(),
      'year': row.year,
      'description': row.description,
      'status': row.status,
      'order_index': row.orderIndex,
      'is_deleted': false,
    });
    return 1;
  }

  Future<int> deleteAchievement(int id) async {
    await _deleteEntity('achievements', id.toString());
    return 1;
  }

  Future<void> addAchievementPhotos(int achievementId, List<String> paths) async {
    if (paths.isEmpty) return;
    final all = await _listEntity('achievement_photos');
    var maxOrder = 0;
    for (final row in all) {
      if (_toBool(row['is_deleted'])) continue;
      if ((_toInt(row['achievement_id']) ?? -1) != achievementId) continue;
      final order = _toInt(row['order_index']) ?? 0;
      if (order > maxOrder) maxOrder = order;
    }
    for (final path in paths) {
      final photo = await _uploadPhotoIfNeeded(
        localPath: path,
        entity: 'achievement_photos',
        cache: {},
      );
      maxOrder += 1;
      await _upsertEntity('achievement_photos', {
        'id': _newId().toString(),
        'achievement_id': achievementId.toString(),
        'photo_drive_file_id': photo['file_id'] ?? '',
        'photo_url': photo['url'] ?? '',
        'order_index': maxOrder,
        'is_deleted': false,
      });
    }
  }

  Future<int> deleteAchievementPhoto({required int achievementId, required int photoId}) async {
    await _deleteEntity('achievement_photos', photoId.toString());
    return 1;
  }

  Future<void> moveAchievement(int achievementId, {required String status, required bool up}) async {
    final items = await fetchAchievements(status: status);
    final index = items.indexWhere((m) => m.id == achievementId);
    if (index == -1) return;
    final targetIndex = up ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= items.length) return;
    final current = items[index];
    final target = items[targetIndex];
    await _upsertEntity('achievements', {
      'id': (current.id ?? _newId()).toString(),
      'year': current.year,
      'description': current.description,
      'status': current.status,
      'order_index': target.orderIndex,
      'is_deleted': false,
    });
    await _upsertEntity('achievements', {
      'id': (target.id ?? _newId()).toString(),
      'year': target.year,
      'description': target.description,
      'status': target.status,
      'order_index': current.orderIndex,
      'is_deleted': false,
    });
  }

  Future<int> insertManifestation(Manifestation row) async {
    final id = row.id ?? _newId();
    final photo = await _uploadPhotoIfNeeded(
      localPath: row.photoPath,
      entity: 'manifestations',
      cache: {},
    );
    await _upsertEntity('manifestations', {
      'id': id.toString(),
      'title': row.title,
      'details': row.details,
      'date': _formatDate(row.date),
      'photo_drive_file_id': photo['file_id'] ?? '',
      'photo_url': photo['url'] ?? '',
      'is_deleted': false,
    });
    return id;
  }

  Future<List<Manifestation>> fetchManifestations() async {
    final rows = await _listEntity('manifestations');
    final items = rows
        .where((e) => !_toBool(e['is_deleted']))
        .map(
          (e) => Manifestation(
            id: _toInt(e['id']),
            title: e['title']?.toString() ?? '',
            details: e['details']?.toString() ?? '',
            date: DateTime.tryParse(e['date']?.toString() ?? '') ?? DateTime.now(),
            photoPath: e['photo_url']?.toString() ?? '',
          ),
        )
        .toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> pushLocalToCloud() async {
    if (!_configured) {
      throw Exception(
        'Cloud sync not configured!\n\n'
        'To use cloud sync, launch with:\n'
        'flutter run \\\n'
        '  --dart-define=APPS_SCRIPT_URL="https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec" \\\n'
        '  --dart-define=APPS_SCRIPT_API_KEY="YOUR_API_KEY"'
      );
    }
    final repo = RegistrationRepository.instance;
    final objectives = await repo.getObjectives();
    final registrations = await repo.getAll();
    final executive = await repo.getExecutiveMembers();
    final achievements = await repo.getAllAchievements();
    final achievementPhotos = await repo.getAllAchievementPhotos();
    final manifestations = await repo.getManifestations();

    final photoUploadCache = <String, Map<String, String>>{};

    // Optimization: Queue all operations without awaiting, then flush once at the end
    for (var i = 0; i < objectives.length; i++) {
      _queueOperation(
        operation: _SyncOperation.upsert,
        entity: 'objectives',
        data: {
          'id': 'objective_${i + 1}',
          'text': objectives[i],
          'order_index': i + 1,
          'is_deleted': false,
        },
        id: 'objective_${i + 1}',
      );
    }

    for (final row in registrations) {
      final photo = await _uploadPhotoIfNeeded(
        localPath: row.photoPath,
        entity: 'registrations',
        cache: photoUploadCache,
      );
      _queueOperation(
        operation: _SyncOperation.upsert,
        entity: 'registrations',
        data: {
          'id': (row.id ?? 0).toString(),
          'full_name': row.fullName,
          'phone': row.phone,
          'email': row.email,
          'city': row.city,
          'notes': row.notes,
          'wants_membership_card': row.wantsMembershipCard,
          'photo_drive_file_id': photo['file_id'] ?? '',
          'photo_url': photo['url'] ?? '',
          'created_at': row.createdAt.toIso8601String(),
          'is_deleted': false,
        },
        id: (row.id ?? 0).toString(),
      );
    }

    for (final row in executive) {
      final photo = await _uploadPhotoIfNeeded(
        localPath: row.photoPath,
        entity: 'executive_members',
        cache: photoUploadCache,
      );
      _queueOperation(
        operation: _SyncOperation.upsert,
        entity: 'executive_members',
        data: {
          'id': (row.id ?? 0).toString(),
          'name': row.name,
          'role': row.role,
          'order_index': row.orderIndex,
          'photo_drive_file_id': photo['file_id'] ?? '',
          'photo_url': photo['url'] ?? '',
          'is_deleted': false,
        },
        id: (row.id ?? 0).toString(),
      );
    }

    for (final row in achievements) {
      _queueOperation(
        operation: _SyncOperation.upsert,
        entity: 'achievements',
        data: {
          'id': (row.id ?? 0).toString(),
          'year': row.year,
          'description': row.description,
          'status': row.status,
          'order_index': row.orderIndex,
          'is_deleted': false,
        },
        id: (row.id ?? 0).toString(),
      );
    }

    for (final row in achievementPhotos) {
      final photo = await _uploadPhotoIfNeeded(
        localPath: row.path,
        entity: 'achievement_photos',
        cache: photoUploadCache,
      );
      _queueOperation(
        operation: _SyncOperation.upsert,
        entity: 'achievement_photos',
        data: {
          'id': (row.id ?? 0).toString(),
          'achievement_id': row.achievementId.toString(),
          'photo_drive_file_id': photo['file_id'] ?? '',
          'photo_url': photo['url'] ?? '',
          'order_index': row.orderIndex,
          'is_deleted': false,
        },
        id: (row.id ?? 0).toString(),
      );
    }

    for (final row in manifestations) {
      final photo = await _uploadPhotoIfNeeded(
        localPath: row.photoPath,
        entity: 'manifestations',
        cache: photoUploadCache,
      );
      _queueOperation(
        operation: _SyncOperation.upsert,
        entity: 'manifestations',
        data: {
          'id': (row.id ?? 0).toString(),
          'title': row.title,
          'details': row.details,
          'date': _formatDate(row.date),
          'photo_drive_file_id': photo['file_id'] ?? '',
          'photo_url': photo['url'] ?? '',
          'is_deleted': false,
        },
        id: (row.id ?? 0).toString(),
      );
    }

    // Optimization: Flush all queued operations in one batch
    await flushSync();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    final raw = value?.toString().toLowerCase().trim() ?? '';
    return raw == 'true' || raw == '1';
  }

  Future<void> pullCloudToLocal() async {
    if (!_configured) {
      throw Exception(
        'Cloud sync not configured!\n\n'
        'To use cloud sync, launch with:\n'
        'flutter run \\\n'
        '  --dart-define=APPS_SCRIPT_URL="https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec" \\\n'
        '  --dart-define=APPS_SCRIPT_API_KEY="YOUR_API_KEY"'
      );
    }

    final objectivesRows = await _listEntity('objectives');
    final registrationsRows = await _listEntity('registrations');
    final executiveRows = await _listEntity('executive_members');
    final achievementsRows = await _listEntity('achievements');
    final achievementPhotosRows = await _listEntity('achievement_photos');
    final manifestationsRows = await _listEntity('manifestations');

    objectivesRows.sort((a, b) => (_toInt(a['order_index']) ?? 0).compareTo(_toInt(b['order_index']) ?? 0));
    final objectives = objectivesRows
        .where((e) => !_toBool(e['is_deleted']))
        .map((e) => e['text']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final registrations = registrationsRows
        .where((e) => !_toBool(e['is_deleted']))
        .map(
          (e) => MemberRegistration(
            id: _toInt(e['id']),
            fullName: e['full_name']?.toString() ?? '',
            phone: e['phone']?.toString() ?? '',
            email: e['email']?.toString() ?? '',
            city: e['city']?.toString() ?? '',
            notes: e['notes']?.toString() ?? '',
            photoPath: e['photo_url']?.toString() ?? '',
            wantsMembershipCard: _toBool(e['wants_membership_card']),
            createdAt: DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now(),
          ),
        )
        .toList();

    final executive = executiveRows
        .where((e) => !_toBool(e['is_deleted']))
        .map(
          (e) => ExecutiveMember(
            id: _toInt(e['id']),
            name: e['name']?.toString() ?? '',
            role: e['role']?.toString() ?? '',
            orderIndex: _toInt(e['order_index']) ?? 0,
            photoPath: e['photo_url']?.toString() ?? '',
          ),
        )
        .toList();
    executive.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final cloudAchievementToLocalId = <String, int>{};
    final achievements = <Achievement>[];
    for (var i = 0; i < achievementsRows.length; i++) {
      final e = achievementsRows[i];
      if (_toBool(e['is_deleted'])) continue;
      final cloudId = e['id']?.toString() ?? 'achv_${i + 1}';
      final parsedId = _toInt(cloudId);
      final localId = parsedId ?? (-1000000 - i);
      final created = Achievement(
        id: localId,
        year: e['year']?.toString() ?? '',
        description: e['description']?.toString() ?? '',
        status: e['status']?.toString().trim().isNotEmpty == true ? e['status'].toString() : 'done',
        orderIndex: _toInt(e['order_index']) ?? (i + 1),
      );
      achievements.add(created);
      cloudAchievementToLocalId[cloudId] = localId;
    }

    final achievementPhotos = <AchievementPhoto>[];
    for (var i = 0; i < achievementPhotosRows.length; i++) {
      final e = achievementPhotosRows[i];
      if (_toBool(e['is_deleted'])) continue;
      final cloudAchievementId = e['achievement_id']?.toString() ?? '';
      final localAchievementId = _toInt(cloudAchievementId) ?? cloudAchievementToLocalId[cloudAchievementId];
      if (localAchievementId == null) continue;
      achievementPhotos.add(
        AchievementPhoto(
          id: _toInt(e['id']),
          achievementId: localAchievementId,
          path: e['photo_url']?.toString() ?? '',
          orderIndex: _toInt(e['order_index']) ?? (i + 1),
        ),
      );
    }

    final manifestations = manifestationsRows
        .where((e) => !_toBool(e['is_deleted']))
        .map(
          (e) => Manifestation(
            id: _toInt(e['id']),
            title: e['title']?.toString() ?? '',
            details: e['details']?.toString() ?? '',
            date: DateTime.tryParse(e['date']?.toString() ?? '') ?? DateTime.now(),
            photoPath: e['photo_url']?.toString() ?? '',
          ),
        )
        .toList();

    await RegistrationRepository.instance.replaceWithCloudSnapshot(
      objectives: objectives.isEmpty ? kDefaultAssociationObjectives : objectives,
      executiveMembers: executive,
      registrations: registrations,
      achievements: achievements,
      achievementPhotos: achievementPhotos,
      manifestations: manifestations,
    );
  }
}
