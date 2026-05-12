import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/calibration_provider.dart';

class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  double _sliderValue = 300.0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final currentDpi = ref.read(calibrationProvider);
      if (currentDpi != null) {
        _sliderValue = currentDpi * (85.6 / 25.4);
      } else {
        _sliderValue = MediaQuery.of(context).size.width * 0.8;
      }
      _initialized = true;
    }
  }

  void _saveCalibration() {
    double dpi = _sliderValue / (85.6 / 25.4);
    ref.read(calibrationProvider.notifier).saveCalibration(dpi);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ المعايرة بنجاح', textAlign: TextAlign.center),
        backgroundColor: Colors.green,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    // The physical aspect ratio of a credit card is roughly 85.6 / 53.98 ≈ 1.585
    final double cardHeight = _sliderValue / (85.6 / 53.98);

    return Scaffold(
      appBar: AppBar(
        title: const Text('معايرة الشاشة (Screen Calibration)'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'لضمان دقة الفحص الطبي، يرجى وضع بطاقة بنكية (Credit/ID Card) على الشاشة وضبط الشريط بالأسفل حتى يتطابق حجم المربع مع البطاقة الحقيقية.',
                style: theme.textTheme.titleMedium?.copyWith(
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: Center(
                  child: Container(
                    width: _sliderValue,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.primary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 48,
                            color: cs.onPrimaryContainer.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'طابق بطاقتك هنا',
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 8,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 32),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      min: 150.0,
                      max: MediaQuery.of(context).size.width,
                      onChanged: (val) {
                        setState(() {
                          _sliderValue = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saveCalibration,
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'حفظ المعايرة (Save)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
