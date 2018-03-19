// GENERATED CODE - DO NOT MODIFY BY HAND

part of packet;

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

Serializer<Packet> _$packetSerializer = new _$PacketSerializer();

class _$PacketSerializer implements StructuredSerializer<Packet> {
  @override
  final Iterable<Type> types = const [Packet, _$Packet];
  @override
  final String wireName = 'Packet';

  @override
  Iterable serialize(Serializers serializers, Packet object,
      {FullType specifiedType: FullType.unspecified}) {
    final result = <Object>[
      'type',
      serializers.serialize(object.type,
          specifiedType: const FullType(PacketType)),
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(int)),
    ];
    if (object.namespace != null) {
      result
        ..add('namespace')
        ..add(serializers.serialize(object.namespace,
            specifiedType: const FullType(String)));
    }
    if (object.data != null) {
      result
        ..add('data')
        ..add(serializers.serialize(object.data,
            specifiedType: const FullType(Object)));
    }
    if (object.attachments != null) {
      result
        ..add('attachments')
        ..add(serializers.serialize(object.attachments,
            specifiedType: const FullType(int)));
    }
    if (object.query != null) {
      result
        ..add('query')
        ..add(serializers.serialize(object.query,
            specifiedType: const FullType(String)));
    }

    return result;
  }

  @override
  Packet deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType: FullType.unspecified}) {
    final result = new PacketBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(PacketType)) as PacketType;
          break;
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'namespace':
          result.namespace = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'data':
          result.data = serializers.deserialize(value,
              specifiedType: const FullType(Object));
          break;
        case 'attachments':
          result.attachments = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'query':
          result.query = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Packet extends Packet {
  @override
  final PacketType type;
  @override
  final int id;
  @override
  final String namespace;
  @override
  final Object data;
  @override
  final int attachments;
  @override
  final String query;

  factory _$Packet([void updates(PacketBuilder b)]) =>
      (new PacketBuilder()..update(updates)).build();

  _$Packet._(
      {this.type,
      this.id,
      this.namespace,
      this.data,
      this.attachments,
      this.query})
      : super._() {
    if (type == null) throw new BuiltValueNullFieldError('Packet', 'type');
    if (id == null) throw new BuiltValueNullFieldError('Packet', 'id');
  }

  @override
  Packet rebuild(void updates(PacketBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  PacketBuilder toBuilder() => new PacketBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! Packet) return false;
    return type == other.type &&
        id == other.id &&
        namespace == other.namespace &&
        data == other.data &&
        attachments == other.attachments &&
        query == other.query;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, type.hashCode), id.hashCode),
                    namespace.hashCode),
                data.hashCode),
            attachments.hashCode),
        query.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Packet')
          ..add('type', type)
          ..add('id', id)
          ..add('namespace', namespace)
          ..add('data', data)
          ..add('attachments', attachments)
          ..add('query', query))
        .toString();
  }
}

class PacketBuilder implements Builder<Packet, PacketBuilder> {
  _$Packet _$v;

  PacketType _type;
  PacketType get type => _$this._type;
  set type(PacketType type) => _$this._type = type;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  String _namespace;
  String get namespace => _$this._namespace;
  set namespace(String namespace) => _$this._namespace = namespace;

  Object _data;
  Object get data => _$this._data;
  set data(Object data) => _$this._data = data;

  int _attachments;
  int get attachments => _$this._attachments;
  set attachments(int attachments) => _$this._attachments = attachments;

  String _query;
  String get query => _$this._query;
  set query(String query) => _$this._query = query;

  PacketBuilder();

  PacketBuilder get _$this {
    if (_$v != null) {
      _type = _$v.type;
      _id = _$v.id;
      _namespace = _$v.namespace;
      _data = _$v.data;
      _attachments = _$v.attachments;
      _query = _$v.query;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Packet other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$Packet;
  }

  @override
  void update(void updates(PacketBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$Packet build() {
    final _$result = _$v ??
        new _$Packet._(
            type: type,
            id: id,
            namespace: namespace,
            data: data,
            attachments: attachments,
            query: query);
    replace(_$result);
    return _$result;
  }
}
