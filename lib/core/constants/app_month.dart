enum AppMonth {
  january(1, 'January', 'Jan'),
  february(2, 'February', 'Feb'),
  march(3, 'March', 'Mar'),
  april(4, 'April', 'Apr'),
  may(5, 'May', 'May'),
  june(6, 'June', 'Jun'),
  july(7, 'July', 'Jul'),
  august(8, 'August', 'Aug'),
  september(9, 'September', 'Sep'),
  october(10, 'October', 'Oct'),
  november(11, 'November', 'Nov'),
  december(12, 'December', 'Dec');

  const AppMonth(this.number, this.fullName, this.shortName);

  final int number;

  final String fullName;

  final String shortName;

  static AppMonth fromNumber(int monthNumber) {
    if (monthNumber < 1 || monthNumber > 12) {
      throw ArgumentError.value(
        monthNumber,
        'monthNumber',
        'Must be between 1 and 12.',
      );
    }
    return AppMonth.values[monthNumber - 1];
  }

  static AppMonth of(DateTime dt) => fromNumber(dt.month);
}
