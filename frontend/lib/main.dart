import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:html' as html;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TtoTtoYakApp());
}

class TtoTtoYakApp extends StatelessWidget {
  const TtoTtoYakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '또또약 (Tto-Tto-Yak)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        fontFamily: 'sans-serif',
      ),
      home: const MainDeviceFrame(),
    );
  }
}

// 뫼비우스 루프 벡터 로고
class TtoTtoYakLogo extends StatelessWidget {
  final double width;
  final double height;
  final bool withText;
  const TtoTtoYakLogo({super.key, this.width = 54, this.height = 32, this.withText = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(painter: _MebiusLogoPainter()),
        ),
        if (withText) ...[
          const SizedBox(height: 16),
          const Text(
            "또또약",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Color(0xFF0F766E),
            ),
          ),
        ]
      ],
    );
  }
}

class _MebiusLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = h * 0.44;
    final leftCenter = Offset(w * 0.35, h * 0.5);
    final rightCenter = Offset(w * 0.65, h * 0.5);

    final basePaint = Paint()..color = const Color(0xFF0F766E)..style = PaintingStyle.fill;
    canvas.drawCircle(leftCenter, r, basePaint);
    canvas.drawCircle(rightCenter, r, basePaint);

    final trackPath = Path()
      ..moveTo(leftCenter.dx, leftCenter.dy - r)
      ..lineTo(rightCenter.dx, rightCenter.dy + r)
      ..lineTo(rightCenter.dx, rightCenter.dy - r)
      ..lineTo(leftCenter.dx, leftCenter.dy + r)
      ..close();
    canvas.drawPath(trackPath, basePaint);

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.32
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(leftCenter, r * 0.55, strokePaint);
    canvas.drawCircle(rightCenter, r * 0.55, strokePaint);

    final goldPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawCircle(Offset(w * 0.35, h * 0.5), r * 0.22, goldPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.5), r * 0.22, goldPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.5), r * 0.22, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 메인 프레임 & 라우터
class MainDeviceFrame extends StatefulWidget {
  const MainDeviceFrame({super.key});

  @override
  State<MainDeviceFrame> createState() => _MainDeviceFrameState();
}

class _MainDeviceFrameState extends State<MainDeviceFrame> {
  bool _isSplash = true;
  double _progress = 0.0;
  Timer? _timer;

  bool _isConsentApproved = false;
  int _selectedTab = 0; // 0: 일정, 1: AI 건강체크, 2: 처방전, 3: 커뮤니티, 4: 설정
  final List<int> _navStack = [0];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 25), (t) {
      setState(() {
        _progress += 0.04;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _isSplash = false;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index == 1 && !_isConsentApproved) {
      _showConsentModal(targetTab: 1);
      return;
    }
    if (_selectedTab == index) return;
    setState(() {
      _navStack.add(index);
      _selectedTab = index;
    });
  }

  void _popBack() {
    if (_navStack.length > 1) {
      setState(() {
        _navStack.removeLast();
        _selectedTab = _navStack.last;
      });
    }
  }

  void _showConsentModal({required int targetTab}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF0F766E), size: 26),
            SizedBox(width: 8),
            Text("AI 건강체크 생체정보 동의", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "또또약 AI 건강체크는 안면 468개 랜드마크(좌우 비대칭·단차 분석)와 rPPG 혈류 심박수 측정을 결합해 안면 신경 이상과 바이탈을 동시 진단합니다.",
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
              child: const Text(
                "• 수집: 좌우 눈/코/입 단차, 실시간 심박수\n• 원칙: 영상 미저장 (연산 직후 즉시 파기)",
                style: TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.bold, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("거부", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _isConsentApproved = true;
                _selectedTab = targetTab;
                _navStack.add(targetTab);
              });
              Navigator.pop(ctx);
            },
            child: const Text("동의하고 시작", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Container(
          width: 430,
          height: 880,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 28, offset: const Offset(0, 14))
            ],
          ),
          child: _isSplash ? _buildSplashScreen() : _buildMainAppScaffold(),
        ),
      ),
    );
  }

  Widget _buildSplashScreen() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          const TtoTtoYakLogo(width: 160, height: 100, withText: true),
          const Spacer(flex: 2),
          const Text("loading...", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 12),
          Container(
            width: 180,
            height: 8,
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Container(decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(8))),
            ),
          ),
          const Spacer(flex: 1),
          Container(width: 120, height: 4, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMainAppScaffold() {
    return Column(
      children: [
        _buildCleanAppBar(),
        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              ScheduleTabScreen(onStartHealthCheck: () => _navigateToTab(1)),
              const AIHealthCheckTabScreen(),
              const OcrPrescriptionTabScreen(),
              const CareCommunityTabScreen(),
              SettingsTabScreen(
                isConsent: _isConsentApproved,
                onConsentToggle: (val) => setState(() => _isConsentApproved = val),
              ),
            ],
          ),
        ),
        _buildCleanNotchedDock(),
      ],
    );
  }

  Widget _buildCleanAppBar() {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
              onPressed: _popBack,
            ),
          ),
          const TtoTtoYakLogo(width: 50, height: 30),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                _selectedTab == 4 ? Icons.settings : Icons.account_circle_outlined,
                size: 26,
                color: const Color(0xFF0F766E),
              ),
              onPressed: () => _navigateToTab(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanNotchedDock() {
    return Container(
      color: Colors.white,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 60,
            color: const Color(0xFF0D5E56),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _dockItem(0, "일정", Icons.calendar_month_outlined, Icons.calendar_month)),
                // [이름 변경] 바이탈 -> AI 건강체크
                Expanded(child: _dockItem(1, "AI 건강체크", Icons.health_and_safety_outlined, Icons.health_and_safety)),
                const SizedBox(width: 72),
                Expanded(child: _dockItem(2, "처방전", Icons.document_scanner_outlined, Icons.document_scanner)),
                Expanded(child: _dockItem(3, "커뮤니티", Icons.groups_outlined, Icons.groups)),
                Expanded(child: _dockItem(4, "설정", Icons.settings_outlined, Icons.settings)),
              ],
            ),
          ),
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: () => _navigateToTab(0),
              child: Container(
                width: 68,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5E56),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, -2))
                  ],
                ),
                alignment: Alignment.center,
                child: const TtoTtoYakLogo(width: 44, height: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dockItem(int index, String label, IconData unselected, IconData selected) {
    final active = _selectedTab == index;
    return InkWell(
      onTap: () => _navigateToTab(index),
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? selected : unselected, color: active ? Colors.white : const Color(0xFF99F6E4), size: 19),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.white : const Color(0xFF99F6E4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// [Screen 1] 스케줄: 캘린더 & 복약 토글 & "AI 건강체크 시작"
class ScheduleTabScreen extends StatefulWidget {
  final VoidCallback onStartHealthCheck;
  const ScheduleTabScreen({super.key, required this.onStartHealthCheck});

  @override
  State<ScheduleTabScreen> createState() => _ScheduleTabScreenState();
}

class _ScheduleTabScreenState extends State<ScheduleTabScreen> {
  bool _isMonthView = false;
  int _selectedDay = 4;

  final Map<int, List<Map<String, dynamic>>> _dayRecords = {
    4: [
      {"time": "08:30 AM", "title": "아침 혈압약 / 항응고제", "isDone": true},
      {"time": "10:00 AM", "title": "위점막 보호제", "isDone": true},
      {"time": "12:00 PM", "title": "점심 당뇨약", "isDone": true},
      {"time": "02:00 PM", "title": "관절 영양제", "isDone": true},
      {"time": "03:00 PM", "title": "오후 비타민 D", "isDone": false},
    ],
  };

  List<Map<String, dynamic>> _getCurrentList() {
    return _dayRecords[_selectedDay] ??= [
      {"time": "08:30 AM", "title": "아침 정기약", "isDone": false},
      {"time": "12:00 PM", "title": "점심 정기약", "isDone": false},
      {"time": "06:30 PM", "title": "저녁 정기약", "isDone": false},
    ];
  }

  void _toggleMedication(int index) {
    setState(() {
      final list = _getCurrentList();
      list[index]["isDone"] = !list[index]["isDone"];
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _getCurrentList();
    final doneCount = list.where((e) => e["isDone"] == true).length;
    final totalCount = list.length;
    final compliance = totalCount > 0 ? ((doneCount / totalCount) * 100).toInt() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("2026년 10월 ($_selectedDay일)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("주간", style: TextStyle(fontSize: 11)),
                    selected: !_isMonthView,
                    selectedColor: const Color(0xFF0F766E),
                    labelStyle: TextStyle(color: !_isMonthView ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold),
                    onSelected: (val) => setState(() => _isMonthView = false),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text("월간", style: TextStyle(fontSize: 11)),
                    selected: _isMonthView,
                    selectedColor: const Color(0xFF0F766E),
                    labelStyle: TextStyle(color: _isMonthView ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold),
                    onSelected: (val) => setState(() => _isMonthView = true),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          _isMonthView ? _buildMonthCalendar() : _buildWeekCalendar(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("DAILY MEDICATION SCHEDULE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text("$_selectedDay일 완료 현황: $doneCount / $totalCount 건", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.health_and_safety, color: Colors.white, size: 14),
                      label: const Text("AI 건강체크", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: widget.onStartHealthCheck,
                    )
                  ],
                ),
                const Divider(height: 18),
                ...List.generate(list.length, (i) {
                  final item = list[i];
                  return _buildMedicationActionRow(
                    time: item["time"],
                    title: item["title"],
                    isDone: item["isDone"],
                    onTapToggle: () => _toggleMedication(i),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Compliance Score: $compliance% (실시간 반영)", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: compliance / 100.0,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final days = ["일", "월", "화", "수", "목", "금", "토"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final dayNum = 4 + i;
        final isSelected = _selectedDay == dayNum;
        return GestureDetector(
          onTap: () => setState(() => _selectedDay = dayNum),
          child: Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0F766E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Text(days[i], style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("$dayNum", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : const Color(0xFF0F172A))),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthCalendar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.1),
        itemCount: 31,
        itemBuilder: (ctx, idx) {
          final day = idx + 1;
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Text(
                "$day",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicationActionRow({
    required String time,
    required String title,
    required bool isDone,
    required VoidCallback onTapToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            ],
          ),
          InkWell(
            onTap: onTapToggle,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: isDone ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                  const SizedBox(width: 4),
                  Text(
                    isDone ? "복약 완료" : "복약하기",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDone ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// [Screen 2] AI 안면 & 바이탈 종합 건강체크
class AIHealthCheckTabScreen extends StatefulWidget {
  const AIHealthCheckTabScreen({super.key});

  @override
  State<AIHealthCheckTabScreen> createState() => _AIHealthCheckTabScreenState();
}

class _AIHealthCheckTabScreenState extends State<AIHealthCheckTabScreen> {
  double _heartRate = 72.0;
  double _depthDelta = 28.76;
  double _eyeTilt = 1.24;
  double _mouthDelta = 2.15;
  double _asymmetryScore = 5.8;
  Timer? _animTimer;
  double _phase = 0.0;

  @override
  void initState() {
    super.initState();
    _animTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _phase += 0.15;
        _heartRate = 72.0 + 1.6 * sin(_phase);
        _depthDelta = 28.76 + 0.3 * cos(_phase * 0.8);
        _eyeTilt = 1.24 + 0.15 * sin(_phase * 0.5);
        _mouthDelta = 2.15 + 0.2 * cos(_phase * 0.7);
      });
    });
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AI 건강체크 (안면 단차 & 바이탈)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text("안면 신경 이상(단차) + 혈류 심박수 실시간 분석", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                child: const Text("동의완료", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
              )
            ],
          ),
          const SizedBox(height: 8),

          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: const Size(260, 220), painter: _FaceLandmarkMeshPainter(phase: _phase)),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
                    child: const Text("AI Live Scan @ 30FPS", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 60,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("심박수 (rPPG):", style: TextStyle(color: Colors.white70, fontSize: 9)),
                        Text("${_heartRate.toStringAsFixed(1)} BPM", style: const TextStyle(color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 60,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("코 3D 단차 (Depth)", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text("+${_depthDelta.toStringAsFixed(2)} mm", style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF0F766E).withOpacity(0.85), borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      "좌우 안면 비대칭도: ${_asymmetryScore.toStringAsFixed(1)}% (정상 균형)",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _asymTile("눈꼬리 편차", "${_eyeTilt.toStringAsFixed(2)} mm"),
                _asymTile("코 3D 단차", "${_depthDelta.toStringAsFixed(2)} mm"),
                _asymTile("입꼬리 비대칭", "${_mouthDelta.toStringAsFixed(2)} %"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text("주간 건강 트렌드", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          _trendLineCard("Heart Rate", ["120", "100", "80"], ["72.8", "73.0", "72.7"], [92, 98, 88, 110, 102, 90, 105], const Color(0xFF0F766E)),
        ],
      ),
    );
  }

  Widget _asymTile(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _trendLineCard(String title, List<String> yLabels, List<String> rightValues, List<double> points, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Row(
                children: rightValues.map((v) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(v, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: v == "72.7" ? Colors.redAccent : const Color(0xFF0F766E))),
                )).toList(),
              )
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: yLabels.map((l) => Text(l, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)))).toList(),
                ),
                const SizedBox(width: 6),
                Expanded(child: CustomPaint(painter: _SimpleLinePainter(points: points, color: color))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceLandmarkMeshPainter extends CustomPainter {
  final double phase;
  _FaceLandmarkMeshPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final axisPaint = Paint()..color = Colors.tealAccent.withOpacity(0.3)..strokeWidth = 1;
    canvas.drawLine(Offset(cx, cy - 70), Offset(cx, cy + 70), axisPaint);

    final faceOval = Paint()..color = Colors.white.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 130, height: 170), faceOval);

    final dotPaint = Paint()..color = Colors.tealAccent;
    final alertDotPaint = Paint()..color = const Color(0xFFD97706);

    final eyeY = cy - 18;
    canvas.drawCircle(Offset(cx - 32, eyeY), 2.5, dotPaint);
    canvas.drawCircle(Offset(cx + 32, eyeY), 2.5, dotPaint);
    canvas.drawLine(Offset(cx - 36, eyeY), Offset(cx + 36, eyeY), Paint()..color = Colors.white24);

    final noseTipY = cy + 8;
    canvas.drawCircle(Offset(cx, noseTipY), 3.5, alertDotPaint);

    final mouthY = cy + 38;
    canvas.drawCircle(Offset(cx - 24, mouthY), 3, alertDotPaint);
    canvas.drawCircle(Offset(cx + 24, mouthY), 3, alertDotPaint);
    canvas.drawLine(Offset(cx - 28, mouthY), Offset(cx + 28, mouthY), Paint()..color = Colors.white24);
  }

  @override
  bool shouldRepaint(covariant _FaceLandmarkMeshPainter oldDelegate) => true;
}

class _SimpleLinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _SimpleLinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final minVal = points.reduce(min) - 5;
    final maxVal = points.reduce(max) + 5;
    final range = maxVal - minVal;

    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    final dx = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = size.height - ((points[i] - minVal) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SimpleLinePainter oldDelegate) => false;
}

// [Screen 3] 처방전 OCR
class OcrPrescriptionTabScreen extends StatefulWidget {
  const OcrPrescriptionTabScreen({super.key});

  @override
  State<OcrPrescriptionTabScreen> createState() => _OcrPrescriptionTabScreenState();
}

class _OcrPrescriptionTabScreenState extends State<OcrPrescriptionTabScreen> {
  bool _isProcessing = false;
  bool _isSynced = false;
  Uint8List? _uploadedImageBytes;

  final TextEditingController _hospitalController = TextEditingController(text: "Seoul Medical");
  final TextEditingController _medsController = TextEditingController(text: "Drug A (10mg), Drug B (5mg)");
  final TextEditingController _dosageController = TextEditingController(text: "1일 2회 (아침/저녁 식후)");

  void _pickAndCapturePrescription() {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.setAttribute('capture', 'environment');
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          setState(() => _uploadedImageBytes = reader.result as Uint8List);
          _sendImageToBackendOCR(_uploadedImageBytes!, file.name);
        });
      }
    });
  }

  Future<void> _sendImageToBackendOCR(Uint8List bytes, String filename) async {
    setState(() => _isProcessing = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/api/v1/ocr-prescription-upload'));
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: MediaType('image', 'jpeg')));
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      setState(() {
        _hospitalController.text = data["hospital"] ?? "Seoul Medical";
        _medsController.text = data["meds"] ?? "Drug A (10mg), Drug B (5mg)";
        _dosageController.text = data["dosage"] ?? "1일 2회 식후";
        _isProcessing = false;
        _isSynced = true;
      });
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 900));
      setState(() {
        _hospitalController.text = "연세 서울 내과의원";
        _medsController.text = "노바스크정 (5mg), 다이아벡스 (500mg)";
        _dosageController.text = "1일 2회 (아침/저녁 식후 30분)";
        _isProcessing = false;
        _isSynced = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("OCR PRESCRIPTION INPUT", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text("실물 처방전/약봉지 카메라 촬영 및 비전 인식", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                label: const Text("처방전 촬영", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: _pickAndCapturePrescription,
              )
            ],
          ),
          const SizedBox(height: 12),
          if (_uploadedImageBytes != null) ...[
            Container(
              height: 140,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F766E), width: 2),
                image: DecorationImage(image: MemoryImage(_uploadedImageBytes!), fit: BoxFit.cover),
              ),
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                child: const Text("촬영 원본 업로드됨", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Rx", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'serif')),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("처 방 전", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text("발행번호: 2026-Rx-901\n처방약국: Seoul Medical Pharmacy", style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 18),
                _ocrInputField("병원명 (Hospital):", _hospitalController),
                const SizedBox(height: 8),
                _ocrInputField("처방약 (Meds):", _medsController),
                const SizedBox(height: 8),
                _ocrInputField("복용법 (Dosage):", _dosageController),
                const SizedBox(height: 12),
                SizedBox(
                  width: 160,
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: EdgeInsets.zero,
                    ),
                    icon: _isProcessing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.qr_code_scanner, size: 16),
                    label: Text(_isProcessing ? "AI 비전 인식 중..." : "카메라로 다시 스캔", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _isProcessing ? null : _pickAndCapturePrescription,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFE6F7F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFA7F3D0))),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF0F766E), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isSynced ? "Meds Database: 3 new meds added\n인식된 처방 약물이 복약 스케줄표에 자동 적재되었습니다." : "Meds Database: 카메라로 처방전을 촬영하면\n처방약과 복약 일정이 자동 등록됩니다.",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ocrInputField(String label, TextEditingController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFDE68A))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
          TextField(controller: controller, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF78350F)), decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 2))),
        ],
      ),
    );
  }
}

// [Screen 4 & 5] Care Community & Settings
class CareCommunityTabScreen extends StatelessWidget {
  const CareCommunityTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("CARE COMMUNITY (돌봄 연계망)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const Text("담당 사회복지사 및 가족 보호자 실시간 안심 채널", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
        _buildCareTile("김영희 사회복지사", "송파 실버 안심 복지센터", "최근 모니터링: 오늘 08:35", true),
        _buildCareTile("이민수 (장남)", "보호자 긴급 연락망 (앱 푸시 연동)", "최근 확인: 어제 19:20", false),
        _buildCareTile("관할 119 안전센터", "원스톱 비상 출동 프로토콜", "긴급 출동 대기 상태", false, isEmergency: true),
      ],
    );
  }

  Widget _buildCareTile(String name, String sub, String time, bool onDuty, {bool isEmergency = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isEmergency ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isEmergency ? Colors.redAccent : (onDuty ? const Color(0xFF0F766E) : const Color(0xFF64748B)),
            child: Icon(isEmergency ? Icons.emergency : Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isEmergency ? Colors.redAccent : const Color(0xFF0F172A))),
                Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(time, style: TextStyle(fontSize: 10, color: isEmergency ? Colors.red.shade700 : const Color(0xFF94A3B8))),
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.phone, color: isEmergency ? Colors.redAccent : const Color(0xFF0F766E), size: 22), onPressed: () {}),
        ],
      ),
    );
  }
}

class SettingsTabScreen extends StatelessWidget {
  final bool isConsent;
  final ValueChanged<bool> onConsentToggle;
  const SettingsTabScreen({super.key, required this.isConsent, required this.onConsentToggle});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("SETTINGS & SECURITY", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const Text("시니어 친화 설정 및 생체 데이터 보호 옵션", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            children: [
              SwitchListTile(
                value: isConsent,
                onChanged: onConsentToggle,
                title: const Text("안면 생체 정보 처리 동의", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text("단차 및 rPPG 측정 허용 상태", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                activeColor: const Color(0xFF0F766E),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text("음성 피드백 (TTS 한국어 안내)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text("시각 저하 어르신을 위한 음성 가이드 우선 출력", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                activeColor: const Color(0xFF0F766E),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text("안면 비대칭 감지 시 SOS 전파", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text("눈/입꼬리 비정상 편차 시 보호자 자동 알림", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                activeColor: const Color(0xFF0F766E),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
