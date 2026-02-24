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

class _PrayerScreenState extends State<PrayerScreen> {
  Map<String, String>? todayPrayers;
  String? nextPrayerName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal('ar'); // Mois et Jours en Arabe
    loadPrayerTimes();
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
        
        // Parse mm-dd format (e.g., 08-11)
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
          };
          break;
        }
      }

      // Special case: if today is Dec 31st, tomorrow is Jan 1st (first line)
      if (foundToday && tomorrowRaw == null && lines.isNotEmpty) {
        for (String line in lines) {
           if (line.trim().isEmpty) continue;
           List<String> columns = line.split(',');
           tomorrowRaw = {"الفجر": columns[1]};
           break;
        }
      }

      if (todayRaw != null) {
        setState(() {
          todayPrayers = todayRaw!.map(
            (key, value) => MapEntry(key, _formatTime(value)),
          );
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
    DateTime todayDate,
    Map<String, String> todayRaw,
    Map<String, String>? tomorrowRaw,
  ) {
    final now = DateTime.now();
    final timeFormat = DateFormat("hh:mm:ss a");

    String? nextName;
    String? nextTime;
    DateTime? nextDateTime;

    // Check today's prayers
    for (var entry in todayRaw.entries) {
      final prayerTime = timeFormat.parse(entry.value);
      final fullPrayerDateTime = DateTime(
        todayDate.year,
        todayDate.month,
        todayDate.day,
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

    // If no more prayers today, take tomorrow's Fajr
    if (nextName == null && tomorrowRaw != null) {
      nextName = "الفجر";
      nextTime = _formatTime(tomorrowRaw["الفجر"]!);
      final prayerTime = timeFormat.parse(tomorrowRaw["الفجر"]!);
      final tomorrow = todayDate.add(const Duration(days: 1));
      nextDateTime = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        prayerTime.hour,
        prayerTime.minute,
        prayerTime.second,
      );
    } else if (nextName == null) {
      // Last resort fallback
      nextName = "الفجر";
      nextTime = _formatTime(todayRaw["الفجر"]!);
      nextDateTime = null;
    }

    setState(() {
      nextPrayerName = nextName;
    });

    String timeLeft = "";
    if (nextDateTime != null) {
      final difference = nextDateTime.difference(now);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      
      if (hours > 0) {
        timeLeft = "متبقي $hours س و $minutes د";
      } else if (minutes > 0) {
        timeLeft = "متبقي $minutes د";
      } else {
        timeLeft = "حان الوقت";
      }
    }

    final h = HijriCalendar.now();
    String hijriStr =
        "${h.getDayName()}، ${_toLatinNumbers(h.hDay)} ${h.getLongMonthName()} ${_toLatinNumbers(h.hYear)}";

    _updateHomeWidget(hijriStr, nextName!, nextTime!, timeLeft);
  }

  Future<void> _updateHomeWidget(
    String hijri,
    String prayerName,
    String prayerTime,
    String timeLeft,
  ) async {
    await HomeWidget.saveWidgetData<String>('id_hijri_date', hijri);
    await HomeWidget.saveWidgetData<String>('id_next_prayer_name', prayerName);
    await HomeWidget.saveWidgetData<String>('id_next_prayer_time', prayerTime);
    await HomeWidget.saveWidgetData<String>('id_time_left', timeLeft);

    await HomeWidget.updateWidget(
      name: 'PrayerWidgetProvider',
      androidName: 'PrayerWidgetProvider',
    );
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

  @override
  Widget build(BuildContext context) {
    var h = HijriCalendar.now();
    String customHijriDate =
        "${h.getDayName()}، "
        "${_toLatinNumbers(h.hDay)} "
        "${h.getLongMonthName()} "
        "${_toLatinNumbers(h.hYear)}";

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white24))
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    // Hijri Date
                    Flexible(
                      flex: 1,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          customHijriDate,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, thickness: 1),
                    
                    if (todayPrayers != null)
                      ...todayPrayers!.entries.map((entry) {
                        bool isNext = entry.key == nextPrayerName;
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
                                      entry.key,
                                      style: TextStyle(
                                        color: isNext ? Colors.white : Colors.white38,
                                        fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.contain,
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isNext ? Colors.greenAccent : Colors.white,
                                      ),
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
