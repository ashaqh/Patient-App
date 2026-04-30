import 'package:intl/intl.dart';

class DateTimeUtils {
  // Format date for display
  static String formatDate(DateTime date, {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }
  
  // Format time for display
  static String formatTime(DateTime time, {String format = 'hh:mm a'}) {
    return DateFormat(format).format(time);
  }
  
  // Format date and time for display
  static String formatDateTime(DateTime dateTime, {String format = 'dd MMM yyyy, hh:mm a'}) {
    return DateFormat(format).format(dateTime);
  }
  
  // Parse date from string
  static DateTime? parseDate(String dateString, {String format = 'yyyy-MM-dd'}) {
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  // Parse time from string
  static DateTime? parseTime(String timeString, {String format = 'HH:mm:ss'}) {
    try {
      return DateFormat(format).parse(timeString);
    } catch (e) {
      return null;
    }
  }
  
  // Get today's date at start of day
  static DateTime startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  // Get today's date at end of day
  static DateTime endOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }
  
  // Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // Check if a date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }
  
  // Check if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
  
  // Get days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inDays).abs();
  }
  
  // Get time of day from DateTime
  static TimeOfDay timeOfDayFromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
  
  // Combine date and time
  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
  
  // Format duration for display (e.g., "2 days", "3 hours")
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return '${duration.inSeconds} ${duration.inSeconds == 1 ? 'second' : 'seconds'}';
    }
  }
  
  // Get relative time string (e.g., "2 days ago", "in 3 hours")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      final pastDifference = difference.abs();
      if (pastDifference.inDays > 0) {
        return '${pastDifference.inDays} ${pastDifference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (pastDifference.inHours > 0) {
        return '${pastDifference.inHours} ${pastDifference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (pastDifference.inMinutes > 0) {
        return '${pastDifference.inMinutes} ${pastDifference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } else {
      if (difference.inDays > 0) {
        return 'in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
      } else if (difference.inHours > 0) {
        return 'in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
      } else if (difference.inMinutes > 0) {
        return 'in ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
      } else {
        return 'Now';
      }
    }
  }
  
  // Check if time is in the past
  static bool isTimeInPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }
  
  // Check if time is in the future
  static bool isTimeInFuture(DateTime dateTime) {
    return dateTime.isAfter(DateTime.now());
  }
}