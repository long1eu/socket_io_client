// GENERATED CODE - DO NOT MODIFY BY HAND

part of deconstructed_packet;

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

Serializer<DeconstructedPacket> _$deconstructedPacketSerializer =
    new _$DeconstructedPacketSerializer();

class _$DeconstructedPacketSerializer
    implements StructuredSerializer<DeconstructedPacket> {
  @override
  final Iterable<Type> types = const [
    DeconstructedPacket,
    _$DeconstructedPacket
  ];
  @override
  final String wireName = 'DeconstructedPacket';

  @override
  Iterable serialize(Serializers serializers, DeconstructedPacket object,
      {FullType specifiedType: FullType.unspecified}) {
    final result = <Object>[
      'packet',
      serializers.serialize(object.packet,
          specifiedType: const FullType(Packet)),
      'buffers',
      serializers.serialize(object.buffers,
          specifiedType: const FullType(List, const [const FullType(Object)])),
    ];

    return result;
  }

  @override
  DeconstructedPacket deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType: FullType.unspecified}) {
    final result = new DeconstructedPacketBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'packet':
          result.packet.replace(serializers.deserialize(value,
              specifiedType: const FullType(Packet)) as Packet);
          break;
        case 'buffers':
          result.buffers = serializers.deserialize(value,
                  specifiedType:
                      const FullType(List, const [const FullType(Object)]))
              as List<Object>;
          break;
      }
    }

    return result.build();
  }
}

class _$DeconstructedPacket extends DeconstructedPacket {
  @override
  final Packet packet;
  @override
  final List<Object> buffers;

  factory _$DeconstructedPacket([void updates(DeconstructedPacketBuilder b)]) =>
      (new DeconstructedPacketBuilder()..update(updates)).build();

  _$DeconstructedPacket._({this.packet, this.buffers}) : super._() {
    if (packet == null)
      throw new BuiltValueNullFieldError('DeconstructedPacket', 'packet');
    if (buffers == null)
      throw new BuiltValueNullFieldError('DeconstructedPacket', 'buffers');
  }

  @override
  DeconstructedPacket rebuild(void updates(DeconstructedPacketBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  DeconstructedPacketBuilder toBuilder() =>
      new DeconstructedPacketBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! DeconstructedPacket) return false;
    return packet == other.packet && buffers == other.buffers;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, packet.hashCode), buffers.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('DeconstructedPacket')
          ..add('packet', packet)
          ..add('buffers', buffers))
        .toString();
  }
}

class DeconstructedPacketBuilder
    implements Builder<DeconstructedPacket, DeconstructedPacketBuilder> {
  _$DeconstructedPacket _$v;

  PacketBuilder _packet;
  PacketBuilder get packet => _$this._packet ??= new PacketBuilder();
  set packet(PacketBuilder packet) => _$this._packet = packet;

  List<Object> _buffers;
  List<Object> get buffers => _$this._buffers;
  set buffers(List<Object> buffers) => _$this._buffers = buffers;

  DeconstructedPacketBuilder();

  DeconstructedPacketBuilder get _$this {
    if (_$v != null) {
      _packet = _$v.packet?.toBuilder();
      _buffers = _$v.buffers;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeconstructedPacket other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$DeconstructedPacket;
  }

  @override
  void update(void updates(DeconstructedPacketBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$DeconstructedPacket build() {
    _$DeconstructedPacket _$result;
    try {
      _$result = _$v ??
          new _$DeconstructedPacket._(packet: packet.build(), buffers: buffers);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'packet';
        packet.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'DeconstructedPacket', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}
