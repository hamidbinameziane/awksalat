import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hijri/hijri_calendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' hide TextDirection;

void main() => runApp(const SalatApp());

class SalatApp extends StatelessWidget {
  const SalatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: PrayerScreen(),
      ),
    );
  }
}

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen>
    with WidgetsBindingObserver {
  Map<String, String>? todayPrayers;
  Map<String, String>? tomorrowPrayers;
  String? nextPrayerName;
  DateTime? nextPrayerDateTime;
  bool isLoading = true;
  Timer? _fluidTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HijriCalendar.setLocal('ar'); // Mois et Jours en Arabe
    loadPrayerTimes();
    _startFluidTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fluidTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        loadPrayerTimes();
        _startFluidTimer();
      });
    } else if (state == AppLifecycleState.paused) {
      _fluidTimer?.cancel();
    }
  }

  void _startFluidTimer() {
    _fluidTimer?.cancel();
    _fluidTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> loadPrayerTimes() async {
    try {
      final now = DateTime.now();
      final String csvData = await rootBundle.loadString('assets/horaires.csv');
      final List<String> lines = csvData.split('\n');

      Map<String, String>? todayRaw;
      Map<String, String>? tomorrowRaw;
      bool foundToday = false;

      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        List<String> columns = line.split(',');

        List<String> dateParts = columns[0].split('-');
        if (dateParts.length != 2) continue;

        int month = int.parse(dateParts[0]);
        int day = int.parse(dateParts[1]);

        if (!foundToday && month == now.month && day == now.day) {
          foundToday = true;
          todayRaw = {
            "الفجر": columns[1],
            "الشروق": columns[2],
            "الظهر": columns[3],
            "العصر": columns[4],
            "المغرب": columns[5],
            "العشاء": columns[6],
          };
        } else if (foundToday) {
          tomorrowRaw = {
            "الفجر": columns[1],
            "الشروق": columns[2],
            "الظهر": columns[3],
            "العصر": columns[4],
            "المغرب": columns[5],
            "العشاء": columns[6],
          };
          break;
        }
      }

      if (foundToday && tomorrowRaw == null && lines.isNotEmpty) {
        for (String line in lines) {
          if (line.trim().isEmpty) continue;
          List<String> columns = line.split(',');
          tomorrowRaw = {
            "الفجر": columns[1],
            "الشروق": columns[2],
            "الظهر": columns[3],
            "العصر": columns[4],
            "المغرب": columns[5],
            "العشاء": columns[6],
          };
          break;
        }
      }

      if (todayRaw != null && tomorrowRaw != null) {
        setState(() {
          todayPrayers = todayRaw;
          tomorrowPrayers = tomorrowRaw;
          isLoading = false;
        });

        _calculateAndUpdateWidget(now, todayRaw, tomorrowRaw);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Erreur: $e");
      setState(() => isLoading = false);
    }
  }

  void _calculateAndUpdateWidget(
    DateTime now,
    Map<String, String> todayRaw,
    Map<String, String> tomorrowRaw,
  ) {
    final timeFormat = DateFormat("hh:mm:ss a");

    String? nextName;
    String? nextTime;
    DateTime? nextDateTime;

    for (var entry in todayRaw.entries) {
      final prayerTime = timeFormat.parse(entry.value);
      final fullPrayerDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        prayerTime.hour,
        prayerTime.minute,
        prayerTime.second,
      );

      if (fullPrayerDateTime.isAfter(now)) {
        nextName = entry.key;
        nextTime = _formatTime(entry.value);
        nextDateTime = fullPrayerDateTime;
        break;
      }
    }

    if (nextName == null) {
      nextName = "الفجر";
      nextTime = _formatTime(tomorrowRaw["الفجر"]!);
      final prayerTime = timeFormat.parse(tomorrowRaw["الفجر"]!);
      final tomorrow = now.add(const Duration(days: 1));
      nextDateTime = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        prayerTime.hour,
        prayerTime.minute,
        prayerTime.second,
      );
    }

    if (nextName != nextPrayerName && mounted) {
      setState(() {
        nextPrayerName = nextName;
        nextPrayerDateTime = nextDateTime;
      });
    } else {
      nextPrayerDateTime = nextDateTime;
    }

    final h = HijriCalendar.now();
    String hijriStr =
        "${h.getDayName()}، ${_toLatinNumbers(h.hDay)} ${h.getLongMonthName()} ${_toLatinNumbers(h.hYear)}";

    _updateHomeWidget(hijriStr, nextName!, nextTime!);
  }

  Future<void> _updateHomeWidget(
    String hijri,
    String prayerName,
    String prayerTime,
  ) async {
    try {
      await HomeWidget.saveWidgetData<String>('id_hijri_date', hijri);
      await HomeWidget.saveWidgetData<String>(
        'id_next_prayer_name',
        prayerName,
      );
      await HomeWidget.saveWidgetData<String>(
        'id_next_prayer_time',
        prayerTime,
      );

      final result = await HomeWidget.updateWidget(
        androidName: 'PrayerWidgetProvider',
      );
      debugPrint("Widget update result: $result");
    } catch (e) {
      debugPrint("Error updating widget: $e");
    }
  }

  String _formatTime(String time) {
    return time
        .replaceAll(':00 ', ' ')
        .replaceAll('AM', 'ص')
        .replaceAll('PM', 'م')
        .trim();
  }

  String _toLatinNumbers(dynamic input) {
    String str = input.toString();
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < arabic.length; i++) {
      str = str.replaceAll(arabic[i], english[i]);
    }
    return str;
  }

  String _getCountdownText() {
    if (nextPrayerDateTime == null) return "";
    final now = DateTime.now();
    final diff = nextPrayerDateTime!.difference(now);
    if (diff.isNegative) return "حان الوقت";
    
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    
    return "متبقي ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    var h = HijriCalendar.now();
    String customHijriDate =
        "${h.getDayName()}، "
        "${_toLatinNumbers(h.hDay)} "
        "${h.getLongMonthName()} "
        "${_toLatinNumbers(h.hYear)}";

    final now = DateTime.now();
    final timeFormat = DateFormat("hh:mm:ss a");

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white24),
              )
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Flexible(
                      flex: 1,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          customHijriDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white10, thickness: 1),

                    if (todayPrayers != null && tomorrowPrayers != null)
                      ...todayPrayers!.entries.map((entry) {
                        final prayerName = entry.key;
                        final todayTimeRaw = entry.value;
                        final tomorrowTimeRaw = tomorrowPrayers![prayerName]!;

                        final prayerTime = timeFormat.parse(todayTimeRaw);
                        final fullPrayerDateTimeToday = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          prayerTime.hour,
                          prayerTime.minute,
                          prayerTime.second,
                        );

                        final bool hasPassed =
                            now.isAfter(fullPrayerDateTimeToday);
                        final String displayTime = hasPassed
                            ? "${_formatTime(tomorrowTimeRaw)} (غداً)"
                            : _formatTime(todayTimeRaw);
                        final bool isNext = prayerName == nextPrayerName;

                        return Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    alignment: Alignment.centerRight,
                                    fit: BoxFit.contain,
                                    child: Text(
                                      prayerName,
                                      style: TextStyle(
                                        color: isNext
                                            ? Colors.white
                                            : Colors.white38,
                                        fontWeight: isNext
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.contain,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          displayTime,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isNext
                                                ? Colors.greenAccent
                                                : Colors.white,
                                          ),
                                        ),
                                        if (isNext)
                                          Text(
                                            _getCountdownText(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
      ),
    );
  }
}
