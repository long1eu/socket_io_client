// GENERATED CODE - DO NOT MODIFY BY HAND

part of manager_state;

// **************************************************************************
// Generator: BuiltValueGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line
// ignore_for_file: annotate_overrides
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: avoid_returning_this
// ignore_for_file: omit_local_variable_types
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: sort_constructors_first

const ManagerState _$CLOSED = const ManagerState._('CLOSED');
const ManagerState _$OPENING = const ManagerState._('OPENING');
const ManagerState _$OPEN = const ManagerState._('OPEN');

ManagerState _$ManagerStateValueOf(String name) {
  switch (name) {
    case 'CLOSED':
      return _$CLOSED;
    case 'OPENING':
      return _$OPENING;
    case 'OPEN':
      return _$OPEN;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ManagerState> _$ManagerStateValues =
    new BuiltSet<ManagerState>(const <ManagerState>[
  _$CLOSED,
  _$OPENING,
  _$OPEN,
]);

Serializer<ManagerState> _$managerStateSerializer =
    new _$ManagerStateSerializer();

class _$ManagerStateSerializer implements PrimitiveSerializer<ManagerState> {
  @override
  final Iterable<Type> types = const <Type>[ManagerState];
  @override
  final String wireName = 'ManagerState';

  @override
  Object serialize(Serializers serializers, ManagerState object,
          {FullType specifiedType: FullType.unspecified}) =>
      object.name;

  @override
  ManagerState deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType: FullType.unspecified}) =>
      ManagerState.valueOf(serialized as String);
}
