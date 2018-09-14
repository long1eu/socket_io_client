class ManagerState {
  final int i;

  const ManagerState._(this.i);

  static const ManagerState closed = const ManagerState._(0);
  static const ManagerState opening = const ManagerState._(1);
  static const ManagerState open = const ManagerState._(2);

  static const List<ManagerState> values = const <ManagerState>[closed, opening, open];
  static const List<String> _strings = const <String>['closed', 'opening', 'open'];

  @override
  String toString() => _strings[i];
}
