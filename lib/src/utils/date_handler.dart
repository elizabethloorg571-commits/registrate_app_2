import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:running_app/extensions/string_extensions.dart';
import 'package:running_app/src/presentation/ui/home/views/competitions_view.dart';
import 'package:running_app/src/utils/navigator_key.dart';

enum DateSeparator { slash, dash, dot, none }

String daySuffix(int day) {
  switch (day) {
    case 1:
    case 21:
    case 31:
      return 'st';
    case 2:
    case 22:
      return 'nd';
    case 3:
    case 23:
      return 'rd';
    default:
      return 'th';
  }
}

String monthInText(int month, String lang) {
  switch (month) {
    case 1:
      return lang == 'es' ? 'Enero' : 'January';
    case 2:
      return lang == 'es' ? 'Febrero' : 'February';
    case 3:
      return lang == 'es' ? 'Marzo' : 'March';
    case 4:
      return lang == 'es' ? 'Abril' : 'April';
    case 5:
      return lang == 'es' ? 'Mayo' : 'May';
    case 6:
      return lang == 'es' ? 'Junio' : 'June';
    case 7:
      return lang == 'es' ? 'Julio' : 'July';
    case 8:
      return lang == 'es' ? 'Agosto' : 'August';
    case 9:
      return lang == 'es' ? 'Septiembre' : 'September';
    case 10:
      return lang == 'es' ? 'Octubre' : 'October';
    case 11:
      return lang == 'es' ? 'Noviembre' : 'November';
    case 12:
      return lang == 'es' ? 'Diciembre' : 'December';
    default:
      return '';
  }
}

String monthInTextMin(int? month) {
  switch (month) {
    case 1:
      return 'ENE';
    case 2:
      return 'FEB';
    case 3:
      return 'MAR';
    case 4:
      return 'ABR';
    case 5:
      return 'MAY';
    case 6:
      return 'JUN';
    case 7:
      return 'JUL';
    case 8:
      return 'AGO';
    case 9:
      return 'SEP';
    case 10:
      return 'OCT';
    case 11:
      return 'NOV';
    case 12:
      return 'DIC';
    default:
      return '';
  }
}

int daysInMonth(int year, int month) {
  if (month == DateTime.february) {
    final bool isLeapYear =
        (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
    return isLeapYear ? 29 : 28;
  }
  const List<int> daysInMonth = <int>[
    31,
    -1,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];
  return daysInMonth[month - 1];
}

int monthsToDays(int months) {
  int days = 0;
  for (int i = 0; i < months; i++) {
    days += daysInMonth(DateTime.now().year, i + 1);
  }
  return days;
}

String fixedTicketDateTime(DateTime? date, {TimeOfDay? time}) {
  if (date == null) {
    return '';
  }
  return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} - ${time?.hour.toString().padLeft(2, '0') ?? date.hour.toString().padLeft(2, '0')}:${time?.minute.toString().padLeft(2, '0') ?? date.minute.toString().padLeft(2, '0')} ${hourAmOrPm((time?.hour ?? date.hour).toString().padLeft(2, '0'))}";
}

String fixedDateTimeMonth(DateTime? date) {
  if (date == null) {
    return '';
  }
  return "${date.monthName(navigatorKey.currentContext!)} ${date.year.toString()}";
}

String fixedDateTime(DateTime? date, {String separator = '-'}) {
  if (date == null) {
    return '';
  }
  return "${date.day.toString().padLeft(2, '0')}$separator${date.month.toString().padLeft(2, '0')}$separator${date.year.toString()} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
}

String fixedDateTimeNoSeconds(DateTime? date) {
  if (date == null) {
    return '';
  }
  return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString()} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
}

String fixedDateTimeBasic(
  DateTime? date, {
  DateSeparator separator = DateSeparator.dash,
}) {
  if (date == null) {
    return '';
  }
  switch (separator) {
    case DateSeparator.slash:
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}";
    case DateSeparator.dash:
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString()}";
    case DateSeparator.dot:
      return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString()}";
    case DateSeparator.none:
      return "${date.day.toString().padLeft(2, '0')}${date.month.toString().padLeft(2, '0')}${date.year.toString()}";
  }
}

String fixedDateTimeBasicVariation(DateTime? date) {
  if (date == null) {
    return '';
  }
  return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
}

String fixedTimeMin(DateTime? date) {
  if (date == null) {
    return '';
  }
  return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${hourAmOrPm(date.hour.toString().padLeft(2, '0'))}";
}

String fixedTimeMinFromTimeOfDay(TimeOfDay? time) {
  if (time == null) {
    return '';
  }
  return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${hourAmOrPm(time.hour.toString().padLeft(2, '0'))}";
}

String fixedDateTimeMin(DateTime? date, {String separator = '/'}) {
  if (date == null) {
    return '';
  }
  return "${date.day.toString().padLeft(2, '0')}$separator${monthInTextMin(date.month)}";
}

String fixedDateTimeBasicInversed(DateTime? date) {
  if (date == null) {
    return '';
  }
  return "${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

String toHours(double seconds) {
  if (seconds > 0) {
    return (seconds / 3600).toStringAsFixed(2);
  }
  return '0.00';
}

String fixedDateTimeDayAndMonth(DateTime? date) {
  if (date == null) {
    return '';
  }
  return "${date.day.toString().padLeft(2, '0')} de ${monthInText(date.month, "es")}";
}

String monthNumberToString(int month) {
  switch (month) {
    case 1:
      return '01';
    case 2:
      return '02';
    case 3:
      return '03';
    case 4:
      return '04';
    case 5:
      return '05';
    case 6:
      return '06';
    case 7:
      return '07';
    case 8:
      return '08';
    case 9:
      return '09';
    default:
      return month.toString();
  }
}

String dayNumberToDayString(int day) {
  switch (day) {
    case 1:
      return 'Lunes';
    case 2:
      return 'Martes';
    case 3:
      return 'Miércoles';
    case 4:
      return 'Jueves';
    case 5:
      return 'Viernes';
    case 6:
      return 'Sábado';
    case 7:
      return 'Domingo';
    default:
      return '';
  }
}

DateTime parseCustomBasicDate(String date, {String separator = '/'}) {
  try {
    final List<String> dateParts = date.split(separator);
    return DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return DateTime.now();
  }
}

String hourAmOrPm(String hour) {
  final hourSplit = hour.split(":");
  final int hourInt = int.parse(hourSplit[0]);

  if (hourInt >= 12) {
    return "PM";
  } else {
    return "AM";
  }
}

String parsedReadableDate(
  String date, {
  bool separed = false,
  bool showYear = true,
  String separator = '/',
}) {
  final List<String> dateParts = date.split(separator);

  return separed
      ? '${dateParts[0]} de ${monthInText(int.parse(dateParts[1]), 'es')} ${showYear ? 'de ${dateParts[2]}' : ''}'
      : '${dateParts[0]} ${monthInText(int.parse(dateParts[1]), 'es')} ${showYear ? dateParts[2] : ''}';
}

String subscriptionReadableDate(DateTime date) {
  return '${date.day < 10 ? '0' : ''}${date.day} ${monthInTextMin(date.month).capitalize()} ${date.year}';
}

class HourMinuteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(':', '');

    if (newText.length > 4) return oldValue; // Limit input length to 4 digits

    // Handle deletion gracefully
    if (newValue.text.length < oldValue.text.length) {
      return newValue; // Allow backspacing without reformatting
    }

    // Format with `:` separator
    String formattedText = newText;
    if (newText.length >= 3) {
      formattedText = '${newText.substring(0, 2)}:${newText.substring(2)}';
    }

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
