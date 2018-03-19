library manager_state;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'manager_state.g.dart';

class ManagerState extends EnumClass {
  const ManagerState._(String name) : super(name);

  static const ManagerState CLOSED = _$CLOSED;
  static const ManagerState OPENING = _$OPENING;
  static const ManagerState OPEN = _$OPEN;

  static BuiltSet<ManagerState> get values => _$ManagerStateValues;

  static ManagerState valueOf(String name) => _$ManagerStateValueOf(name);

  static Serializer<ManagerState> get serializer => _$managerStateSerializer;
}
