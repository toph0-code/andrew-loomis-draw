import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const SketchStepsApp());
}

class SketchStepsApp extends StatelessWidget {
  const SketchStepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sketch Steps: AI Loomis Draw',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFF6584),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6584),
          secondary: Color(0xFF3F51B5),
          surface: Color(0xFF1E1E1E),
        ),
        cardTheme: const CardTheme(
          color: Color(0xFF1E1E1E),
          elevation: 4,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

String globalApiKey = "";

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

class DefaultReference {
  final String title;
  final String category;
  final String url;
  const DefaultReference({required this.title, required this.category, required this.url});
}

const List<DefaultReference> sampleReferences = [
  DefaultReference(
    title: 'Male Portrait (3/4 View)',
    category: 'Classic',
    url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop',
  ),
  DefaultReference(
    title: 'Female Portrait (Front View)',
    category: 'Anatomy',
    url: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop',
  ),
  DefaultReference(
    title: 'Dramatic Profile',
    category: 'Chiaroscuro',
    url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43E?w=500&auto=format&fit=crop',
  ),
];

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  Uint8List? _activeAiImageBytes;

  void _navigateToWorkspaceWithImage(Uint8List imageBytes) {
    setState(() {
      _activeAiImageBytes = imageBytes;
      _currentIndex = 2; // Jump to Workspace Tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const LearnLoomisScreen(),
      AiReferenceGenerator(onUseImage: _navigateToWorkspaceWithImage),
      WorkspaceScreen(passedAiImage: _activeAiImageBytes),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFFF6584),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Learn Loomis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_outlined),
            activeIcon: Icon(Icons.psychology),
            label: 'AI Generator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.brush_outlined),
            activeIcon: Icon(Icons.brush),
            label: 'Workspace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}

class LearnLoomisScreen extends StatefulWidget {
  const LearnLoomisScreen({super.key});

  @override
  State<LearnLoomisScreen> createState() => _LearnLoomisScreenState();
}

class _LearnLoomisScreenState extends State<LearnLoomisScreen> {
  int _currentStep = 0;
  List<DrawingPoint> _practiceStrokes = [];
  double _brushSize = 4.0;
  Color _brushColor = const Color(0xFFFF6584);

  final List<Map<String, dynamic>> _steps = [
    {
      'title': '1. The Cranium Sphere',
      'instruction': 'Andrew Loomis begins with a perfect sphere. Draw a clean circle representing the fundamental cranium mass.',
      'view': 'front',
    },
    {
      'title': '2. Flattening the Sides',
      'instruction': 'Slice an oval off the side of your sphere. This represents the flat structural plane of the temples.',
      'view': 'threequarter',
    },
    {
      'title': '3. Setup Center & Brow Lines',
      'instruction': 'Draw the facial centerline down the middle, and cross it with the brow line.',
      'view': 'grid',
    },
    {
      'title': '4. Establish the Jaw & Chin',
      'instruction': 'Drop lines from the temple edges down to form the jaw structure.',
      'view': 'jaw',
    },
    {
      'title': '5. Key Features Map',
      'instruction': 'Subdivide the face into thirds: Hairline, Eyebrows, Nose Bottom, and Chin.',
      'view': 'features',
    },
    {
      'title': '6. Structural Final Portrait',
      'instruction': 'Flesh out the portrait contours and construct the facial details using your grid lines.',
      'view': 'full',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loomis Method Guide',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Step ${_currentStep + 1} of ${_steps.length}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _practiceStrokes.clear();
                  });
                },
              )
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF6584).withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _steps[_currentStep]['title'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF6584)),
              ),
              const SizedBox(height: 6),
              Text(
                _steps[_currentStep]['instruction'],
                style: const TextStyle(fontSize: 13, color: Colors.white80, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: LoomisGuidePainter(step: _currentStep, viewType: _steps[_currentStep]['view']),
                    ),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: (details) {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                        setState(() {
                          _practiceStrokes.add(DrawingPoint(
                            offset: localPosition,
                            paint: Paint()
                              ..color = _brushColor
                              ..strokeCap = StrokeCap.round
                              ..strokeWidth = _brushSize
                              ..isAntiAlias = true,
                          ));
                        });
                      },
                      onPanUpdate: (details) {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                        setState(() {
                          _practiceStrokes.add(DrawingPoint(
                            offset: localPosition,
                            paint: Paint()
                              ..color = _brushColor
                              ..strokeCap = StrokeCap.round
                              ..strokeWidth = _brushSize
                              ..isAntiAlias = true,
                          ));
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _practiceStrokes.add(DrawingPoint(
                            offset: Offset.infinite,
                            paint: Paint(),
                          ));
                        });
                      },
                      child: CustomPaint(
                        painter: UserPracticePainter(strokes: _practiceStrokes),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 12,
                    right: 12,
                    child: Text(
                      'PRACTICE CANVAS (DRAW HERE)',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lens, size: 14, color: Colors.white70),
                      const SizedBox(width: 8),
                      Slider(
                        value: _brushSize,
                        min: 1.0,
                        max: 12.0,
                        activeColor: const Color(0xFFFF6584),
                        onChanged: (val) {
                          setState(() {
                            _brushSize = val;
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildColorDot(const Color(0xFFFF6584)),
                      _buildColorDot(Colors.white),
                      _buildColorDot(Colors.cyanAccent),
                      _buildColorDot(Colors.yellowAccent),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _currentStep > 0
                        ? () {
                            setState(() {
                              _currentStep--;
                              _practiceStrokes.clear();
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Previous'),
                  ),
                  ElevatedButton(
                    onPressed: _currentStep < _steps.length - 1
                        ? () {
                            setState(() {
                              _currentStep++;
                              _practiceStrokes.clear();
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6584),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Next Step', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorDot(Color color) {
    bool isSelected = _brushColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _brushColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 2)
              : Border.all(color: Colors.transparent),
        ),
      ),
    );
  }
}

class LoomisGuidePainter extends CustomPainter {
  final int step;
  final String viewType;

  LoomisGuidePainter({required this.step, required this.viewType});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final radius = size.width * 0.28;

    final guidePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final primaryPaint = Paint()
      ..color = const Color(0xFFFF6584)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (step >= 0) {
      canvas.drawCircle(center, radius, (step == 0) ? primaryPaint : guidePaint);
      if (step == 0) {
        canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), guidePaint);
        canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), guidePaint);
      }
    }

    if (step >= 1) {
      final ellipseWidth = radius * 0.6;
      final ellipseHeight = radius * 0.85;
      final ellipseCenter = Offset(center.dx + radius * 0.4, center.dy - radius * 0.1);

      canvas.drawOval(
        Rect.fromCenter(center: ellipseCenter, width: ellipseWidth, height: ellipseHeight),
        (step == 1) ? primaryPaint : guidePaint,
      );

      if (step == 1) {
        canvas.drawLine(
          Offset(ellipseCenter.dx - ellipseWidth / 2, ellipseCenter.dy),
          Offset(ellipseCenter.dx + ellipseWidth / 2, ellipseCenter.dy),
          accentPaint,
        );
        canvas.drawLine(
          Offset(ellipseCenter.dx, ellipseCenter.dy - ellipseHeight / 2),
          Offset(ellipseCenter.dx, ellipseCenter.dy + ellipseHeight / 2),
          accentPaint,
        );
      }
    }

    if (step >= 2) {
      final browY = center.dy - radius * 0.1;
      final centerCurve = Path()
        ..moveTo(center.dx - radius * 0.45, center.dy - radius)
        ..quadraticBezierTo(center.dx - radius * 0.1, center.dy, center.dx - radius * 0.4, center.dy + radius * 1.5);

      canvas.drawPath(centerCurve, (step == 2) ? primaryPaint : guidePaint);

      final browLine = Path()
        ..moveTo(center.dx - radius, browY)
        ..quadraticBezierTo(center.dx, browY + 15, center.dx + radius, browY - 10);
      canvas.drawPath(browLine, (step == 2) ? primaryPaint : guidePaint);
    }

    if (step >= 3) {
      final jawPath = Path()
        ..moveTo(center.dx - radius * 0.45, center.dy + radius * 0.2)
        ..quadraticBezierTo(
          center.dx - radius * 0.4,
          center.dy + radius * 1.3,
          center.dx - radius * 0.1,
          center.dy + radius * 1.45,
        )
        ..quadraticBezierTo(
          center.dx + radius * 0.3,
          center.dy + radius * 0.8,
          center.dx + radius * 0.4,
          center.dy + radius * 0.32,
        );

      canvas.drawPath(jawPath, (step == 3) ? primaryPaint : guidePaint);
    }

    if (step >= 4) {
      final browY = center.dy - radius * 0.1;
      final noseY = center.dy + radius * 0.55;
      final chinY = center.dy + radius * 1.45;
      final hairlineY = center.dy - radius * 0.75;

      final paintLine = (step == 4) ? primaryPaint : guidePaint;
      canvas.drawLine(Offset(center.dx - radius * 0.8, hairlineY), Offset(center.dx + radius * 0.8, hairlineY), paintLine);
      canvas.drawLine(Offset(center.dx - radius * 0.8, browY), Offset(center.dx + radius * 0.8, browY), paintLine);
      canvas.drawLine(Offset(center.dx - radius * 0.8, noseY), Offset(center.dx + radius * 0.8, noseY), paintLine);
      canvas.drawLine(Offset(center.dx - radius * 0.8, chinY), Offset(center.dx + radius * 0.8, chinY), paintLine);

      if (step == 4) {
        _drawLabel(canvas, Offset(center.dx + radius * 0.9, hairlineY), "Hairline", textPainter);
        _drawLabel(canvas, Offset(center.dx + radius * 0.9, browY), "Brow / Eyes", textPainter);
        _drawLabel(canvas, Offset(center.dx + radius * 0.9, noseY), "Nose Bottom", textPainter);
        _drawLabel(canvas, Offset(center.dx + radius * 0.9, chinY), "Chin Line", textPainter);
      }
    }

    if (step >= 5) {
      final headOutline = Path()
        ..moveTo(center.dx - radius * 0.2, center.dy - radius * 1.02)
        ..quadraticBezierTo(center.dx + radius * 0.8, center.dy - radius * 0.9, center.dx + radius * 0.9, center.dy)
        ..lineTo(center.dx + radius * 0.75, center.dy + radius * 0.3)
        ..quadraticBezierTo(center.dx + radius * 0.45, center.dy + radius * 0.9, center.dx - radius * 0.1, center.dy + radius * 1.45)
        ..quadraticBezierTo(center.dx - radius * 0.5, center.dy + radius * 1.1, center.dx - radius * 0.65, center.dy + radius * 0.4)
        ..lineTo(center.dx - radius * 0.8, center.dy - radius * 0.1)
        ..close();

      canvas.drawPath(headOutline, primaryPaint);

      final eyeBrowL = Path()
        ..moveTo(center.dx - radius * 0.4, center.dy - radius * 0.05)
        ..quadraticBezierTo(center.dx - radius * 0.25, center.dy - radius * 0.15, center.dx - radius * 0.15, center.dy - radius * 0.08);
      final eyeBrowR = Path()
        ..moveTo(center.dx + radius * 0.1, center.dy - radius * 0.08)
        ..quadraticBezierTo(center.dx + radius * 0.25, center.dy - radius * 0.15, center.dx + radius * 0.4, center.dy - radius * 0.05);

      canvas.drawPath(eyeBrowL, accentPaint);
      canvas.drawPath(eyeBrowR, accentPaint);

      final noseBlock = Path()
        ..moveTo(center.dx - radius * 0.18, center.dy - radius * 0.05)
        ..lineTo(center.dx - radius * 0.2, center.dy + radius * 0.5)
        ..lineTo(center.dx - radius * 0.05, center.dy + radius * 0.55)
        ..lineTo(center.dx + radius * 0.1, center.dy + radius * 0.5)
        ..lineTo(center.dx, center.dy - radius * 0.05);
      canvas.drawPath(noseBlock, accentPaint);

      final mouthLine = Path()
        ..moveTo(center.dx - radius * 0.25, center.dy + radius * 0.85)
        ..quadraticBezierTo(center.dx - radius * 0.1, center.dy + radius * 0.88, center.dx, center.dy + radius * 0.85);
      canvas.drawPath(mouthLine, accentPaint);
    }
  }

  void _drawLabel(Canvas canvas, Offset offset, String text, TextPainter tp) {
    tp.text = TextSpan(
      text: text,
      style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant LoomisGuidePainter oldDelegate) {
    return oldDelegate.step != step || oldDelegate.viewType != viewType;
  }
}

class UserPracticePainter extends CustomPainter {
  final List<DrawingPoint> strokes;
  UserPracticePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < strokes.length - 1; i++) {
      if (strokes[i].offset != Offset.infinite && strokes[i + 1].offset != Offset.infinite) {
        canvas.drawLine(strokes[i].offset, strokes[i + 1].offset, strokes[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant UserPracticePainter oldDelegate) => true;
}

class AiReferenceGenerator extends StatefulWidget {
  final Function(Uint8List) onUseImage;
  const AiReferenceGenerator({super.key, required this.onUseImage});

  @override
  State<AiReferenceGenerator> createState() => _AiReferenceGeneratorState();
}

class _AiReferenceGeneratorState extends State<AiReferenceGenerator> {
  final TextEditingController _promptController = TextEditingController(
    text: "Charcoal pencil sketch of a 3/4 portrait, highly structured Loomis facial planes, dramatic shadows, white background",
  );
  bool _isLoading = false;
  Uint8List? _generatedImageBytes;
  String? _errorMessage;

  Future<Uint8List?> _generateImageWithBackoff(String prompt) async {
    final String apiKey = globalApiKey;
    if (apiKey.isEmpty) {
      throw Exception("API Key is missing. Please set your Gemini API key in the 'Config' tab!");
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-generate-001:predict?key=$apiKey',
    );

    int maxRetries = 5;
    int delaySeconds = 1;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "instances": [
              {"prompt": prompt}
            ],
            "parameters": {"sampleCount": 1}
          }),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final base64Image = decoded['predictions'][0]['bytesBase64Encoded'];
          return base64Decode(base64Image);
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          await Future.delayed(Duration(seconds: delaySeconds));
          delaySeconds *= 2;
        } else {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['error']['message'] ?? "Unknown API Error");
        }
      } catch (e) {
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
      }
    }
    return null;
  }

  void _triggerGeneration() async {
    if (_promptController.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _generateImageWithBackoff(_promptController.text.trim());
      setState(() {
        _generatedImageBytes = bytes;
        _isLoading = false;
      });
    } catch (err) {
      setState(() {
        _errorMessage = err.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Drawing References',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Generate custom portraits designed to practice tracing and Loomis grids.',
                  style: TextStyle(fontSize: 13, color: Colors.white50),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              TextField(
                controller: _promptController,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  hintText: 'Describe the style, pose, or angle of the face...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6584)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _triggerGeneration,
                  icon: const Icon(Icons.auto_awesome),
                  label: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Generate Art Reference'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6584),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Center(
              child: _isLoading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFFFF6584)),
                        const SizedBox(height: 16),
                        Text(
                          'Imagining drawing structures...',
                          style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                        ),
                      ],
                    )
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.amber, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              if (globalApiKey.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please navigate to Config tab to set your Gemini API key.')),
                                    );
                                  },
                                  child: const Text('Go to Config'),
                                )
                              ]
                            ],
                          ),
                        )
                      : _generatedImageBytes != null
                          ? Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _generatedImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.black, Colors.transparent],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => widget.onUseImage(_generatedImageBytes!),
                                    icon: const Icon(Icons.send),
                                    label: const Text('Use for Tracing Overlay'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6584),
                                    ),
                                  ),
                                )
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_search, color: Colors.grey.shade600, size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  'Your generated reference will appear here.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
            ),
          ),
        ),
      ],
    );
  }
}

class WorkspaceScreen extends StatefulWidget {
  final Uint8List? passedAiImage;
  const WorkspaceScreen({super.key, this.passedAiImage});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  Uint8List? _customImageBytes;
  String? _selectedPresetUrl;
  double _opacity = 0.5;

  Offset _gridPosition = const Offset(0, 0);
  double _gridScale = 1.0;
  double _gridRotation = 0.0;

  String _overlayView = 'none';

  List<DrawingPoint> _sketchLines = [];
  double _brushSize = 3.5;
  Color _brushColor = Colors.white;

  @override
  void initState() {
    super.initState();
    if (widget.passedAiImage != null) {
      _customImageBytes = widget.passedAiImage;
    } else {
      _selectedPresetUrl = sampleReferences[0].url;
    }
  }

  @override
  void didUpdateWidget(covariant WorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.passedAiImage != null && widget.passedAiImage != oldWidget.passedAiImage) {
      setState(() {
        _customImageBytes = widget.passedAiImage;
        _selectedPresetUrl = null;
      });
    }
  }

  Future<void> _pickGalleryImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _customImageBytes = bytes;
        _selectedPresetUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tracing Workspace',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white70),
                    tooltip: 'Load Gallery Photo',
                    onPressed: _pickGalleryImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white70),
                    tooltip: 'Undo Strike',
                    onPressed: () {
                      if (_sketchLines.isNotEmpty) {
                        setState(() {
                          _sketchLines.removeLast();
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    tooltip: 'Clear Canvas',
                    onPressed: () {
                      setState(() {
                        _sketchLines.clear();
                      });
                    },
                  ),
                ],
              )
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: sampleReferences.length,
            itemBuilder: (context, idx) {
              final ref = sampleReferences[idx];
              final isSelected = _selectedPresetUrl == ref.url;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPresetUrl = ref.url;
                    _customImageBytes = null;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF6584) : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade800),
                  ),
                  child: Center(
                    child: Text(
                      ref.title,
                      style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade900),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: _opacity,
                      child: _customImageBytes != null
                          ? Image.memory(_customImageBytes!, fit: BoxFit.contain)
                          : (_selectedPresetUrl != null
                              ? Image.network(
                                  _selectedPresetUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => const Center(
                                    child: Text('Loading Reference Photo...', style: TextStyle(color: Colors.white24)),
                                  ),
                                )
                              : const Center(child: Text('Load a reference picture to begin.'))),
                    ),
                  ),
                  if (_overlayView != 'none')
                    Positioned.fill(
                      child: GestureDetector(
                        onScaleStart: (details) {},
                        onScaleUpdate: (details) {
                          setState(() {
                            _gridPosition += details.focalPointDelta;
                            _gridScale = (_gridScale * details.scale).clamp(0.2, 5.0);
                            _gridRotation = details.rotation;
                          });
                        },
                        child: CustomPaint(
                          painter: MovableLoomisPainter(
                            viewType: _overlayView,
                            offset: _gridPosition,
                            scale: _gridScale,
                            rotation: _gridRotation,
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: (details) {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        Offset localPos = renderBox.globalToLocal(details.globalPosition);
                        setState(() {
                          _sketchLines.add(DrawingPoint(
                            offset: localPos,
                            paint: Paint()
                              ..color = _brushColor
                              ..strokeCap = StrokeCap.round
                              ..strokeWidth = _brushSize,
                          ));
                        });
                      },
                      onPanUpdate: (details) {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        Offset localPos = renderBox.globalToLocal(details.globalPosition);
                        setState(() {
                          _sketchLines.add(DrawingPoint(
                            offset: localPos,
                            paint: Paint()
                              ..color = _brushColor
                              ..strokeCap = StrokeCap.round
                              ..strokeWidth = _brushSize,
                          ));
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _sketchLines.add(DrawingPoint(
                            offset: Offset.infinite,
                            paint: Paint(),
                          ));
                        });
                      },
                      child: CustomPaint(
                        painter: UserPracticePainter(strokes: _sketchLines),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Loomis Guide:', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildOverlaySelector('None', 'none'),
                      _buildOverlaySelector('Front', 'front'),
                      _buildOverlaySelector('3/4', 'threequarter'),
                      _buildOverlaySelector('Profile', 'side'),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.opacity, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  const Text('Pic Opacity:', style: TextStyle(fontSize: 11, color: Colors.white50)),
                  Expanded(
                    child: Slider(
                      value: _opacity,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFFFF6584),
                      onChanged: (val) {
                        setState(() {
                          _opacity = val;
                        });
                      },
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.brush, size: 16, color: Colors.white70),
                      const SizedBox(width: 8),
                      const Text('Size:', style: TextStyle(fontSize: 11, color: Colors.white50)),
                      SizedBox(
                        width: 120,
                        child: Slider(
                          value: _brushSize,
                          min: 1.0,
                          max: 15.0,
                          activeColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              _brushSize = val;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      _buildBrushColorOption(Colors.white),
                      _buildBrushColorOption(const Color(0xFFFF6584)),
                      _buildBrushColorOption(Colors.blueAccent),
                      _buildBrushColorOption(Colors.greenAccent),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverlaySelector(String label, String code) {
    bool isSelected = _overlayView == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _overlayView = code;
          _gridPosition = const Offset(150, 200);
          _gridScale = 1.0;
          _gridRotation = 0.0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6584) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBrushColorOption(Color color) {
    bool isSelected = _brushColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _brushColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: const Color(0xFFFF6584), width: 2) : null,
        ),
      ),
    );
  }
}

class MovableLoomisPainter extends CustomPainter {
  final String viewType;
  final Offset offset;
  final double scale;
  final double rotation;

  MovableLoomisPainter({
    required this.viewType,
    required this.offset,
    required this.scale,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    canvas.rotate(rotation);

    final double radius = 80;
    final center = const Offset(0, 0);

    final gridPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (viewType == 'front') {
      canvas.drawCircle(center, radius, gridPaint);
      canvas.drawLine(Offset(-radius, 0), Offset(radius, 0), gridPaint);
      canvas.drawLine(Offset(0, -radius), Offset(0, radius * 1.6), gridPaint);
      canvas.drawLine(Offset(-radius * 0.7, -radius), Offset(-radius * 0.7, radius), axisPaint);
      canvas.drawLine(Offset(radius * 0.7, -radius), Offset(radius * 0.7, radius), axisPaint);
      canvas.drawLine(Offset(-radius * 0.7, -radius * 0.6), Offset(radius * 0.7, -radius * 0.6), gridPaint);
      canvas.drawLine(Offset(-radius * 0.7, radius * 0.6), Offset(radius * 0.7, radius * 0.6), gridPaint);
      canvas.drawLine(Offset(-radius * 0.3, radius * 1.5), Offset(radius * 0.3, radius * 1.5), gridPaint);
      canvas.drawLine(Offset(-radius * 0.7, radius * 0.6), Offset(-radius * 0.3, radius * 1.5), gridPaint);
      canvas.drawLine(Offset(radius * 0.7, radius * 0.6), Offset(radius * 0.3, radius * 1.5), gridPaint);
    } else if (viewType == 'threequarter') {
      canvas.drawCircle(center, radius, gridPaint);
      final sideEllipseCenter = Offset(radius * 0.3, -radius * 0.1);
      canvas.drawOval(
        Rect.fromCenter(center: sideEllipseCenter, width: radius * 0.6, height: radius * 0.85),
        gridPaint,
      );
      final centerCurve = Path()
        ..moveTo(-radius * 0.45, -radius)
        ..quadraticBezierTo(-radius * 0.1, 0, -radius * 0.4, radius * 1.5);
      canvas.drawPath(centerCurve, gridPaint);
      final jawPath = Path()
        ..moveTo(-radius * 0.45, radius * 0.2)
        ..quadraticBezierTo(-radius * 0.4, radius * 1.3, -radius * 0.1, radius * 1.5)
        ..quadraticBezierTo(radius * 0.25, radius * 0.8, radius * 0.35, radius * 0.3);
      canvas.drawPath(jawPath, gridPaint);
    } else if (viewType == 'side') {
      canvas.drawCircle(center, radius, gridPaint);
      canvas.drawCircle(Offset.zero, radius * 0.7, gridPaint);
      canvas.drawLine(Offset(-radius, 0), Offset(radius, 0), gridPaint);
      canvas.drawLine(Offset(0, -radius), Offset(0, radius), gridPaint);
      final jaw = Path()
        ..moveTo(0, 0)
        ..lineTo(0, radius * 0.6)
        ..lineTo(-radius * 0.8, radius * 1.4)
        ..quadraticBezierTo(-radius * 1.1, radius * 0.7, -radius, 0);
      canvas.drawPath(jaw, gridPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MovableLoomisPainter oldDelegate) {
    return oldDelegate.viewType != viewType ||
        oldDelegate.offset != offset ||
        oldDelegate.scale != scale ||
        oldDelegate.rotation != rotation;
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = globalApiKey;
  }

  void _saveKey() {
    globalApiKey = _apiKeyController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gemini API configuration key saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Engine Setup',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure your API keys directly to enable the Gemini Image Generation engines.',
            style: TextStyle(fontSize: 13, color: Colors.white50),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.key, color: Color(0xFFFF6584)),
                      SizedBox(width: 8),
                      Text(
                        'Gemini API Key',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'To generate custom drawing references on-demand, input your Gemini API Key here. Leave empty to use offline modes and built-in sketch presets.',
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'AIzaSy...',
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6584),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Save API Key', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'About Loomis Draw MVP',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'This application utilizes Andrew Loomis's structured spatial-planning mechanics. By translating organic forms (the head) into structural geometries, artists gain complete mastery over perspective, lighting, and anatomical positioning.',
            style: TextStyle(fontSize: 12, color: Colors.white38, height: 1.5),
          ),
        ],
      ),
    );
  }
}
