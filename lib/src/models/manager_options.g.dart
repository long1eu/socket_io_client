// GENERATED CODE - DO NOT MODIFY BY HAND

part of manager_options;

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

class _$ManagerOptions extends ManagerOptions {
  @override
  final bool reconnection;
  @override
  final int reconnectionAttempts;
  @override
  final int reconnectionDelay;
  @override
  final int reconnectionDelayMax;
  @override
  final double randomizationFactor;
  @override
  final IoEncoder encoder;
  @override
  final IoDecoder decoder;
  @override
  final int timeout;
  @override
  final SocketOptions options;

  factory _$ManagerOptions([void updates(ManagerOptionsBuilder b)]) =>
      (new ManagerOptionsBuilder()..update(updates)).build();

  _$ManagerOptions._(
      {this.reconnection,
      this.reconnectionAttempts,
      this.reconnectionDelay,
      this.reconnectionDelayMax,
      this.randomizationFactor,
      this.encoder,
      this.decoder,
      this.timeout,
      this.options})
      : super._() {
    if (reconnection == null)
      throw new BuiltValueNullFieldError('ManagerOptions', 'reconnection');
    if (reconnectionAttempts == null)
      throw new BuiltValueNullFieldError(
          'ManagerOptions', 'reconnectionAttempts');
    if (reconnectionDelay == null)
      throw new BuiltValueNullFieldError('ManagerOptions', 'reconnectionDelay');
    if (reconnectionDelayMax == null)
      throw new BuiltValueNullFieldError(
          'ManagerOptions', 'reconnectionDelayMax');
    if (randomizationFactor == null)
      throw new BuiltValueNullFieldError(
          'ManagerOptions', 'randomizationFactor');
    if (timeout == null)
      throw new BuiltValueNullFieldError('ManagerOptions', 'timeout');
    if (options == null)
      throw new BuiltValueNullFieldError('ManagerOptions', 'options');
  }

  @override
  ManagerOptions rebuild(void updates(ManagerOptionsBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  ManagerOptionsBuilder toBuilder() =>
      new ManagerOptionsBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! ManagerOptions) return false;
    return reconnection == other.reconnection &&
        reconnectionAttempts == other.reconnectionAttempts &&
        reconnectionDelay == other.reconnectionDelay &&
        reconnectionDelayMax == other.reconnectionDelayMax &&
        randomizationFactor == other.randomizationFactor &&
        encoder == other.encoder &&
        decoder == other.decoder &&
        timeout == other.timeout &&
        options == other.options;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc($jc(0, reconnection.hashCode),
                                    reconnectionAttempts.hashCode),
                                reconnectionDelay.hashCode),
                            reconnectionDelayMax.hashCode),
                        randomizationFactor.hashCode),
                    encoder.hashCode),
                decoder.hashCode),
            timeout.hashCode),
        options.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ManagerOptions')
          ..add('reconnection', reconnection)
          ..add('reconnectionAttempts', reconnectionAttempts)
          ..add('reconnectionDelay', reconnectionDelay)
          ..add('reconnectionDelayMax', reconnectionDelayMax)
          ..add('randomizationFactor', randomizationFactor)
          ..add('encoder', encoder)
          ..add('decoder', decoder)
          ..add('timeout', timeout)
          ..add('options', options))
        .toString();
  }
}

class ManagerOptionsBuilder
    implements Builder<ManagerOptions, ManagerOptionsBuilder> {
  _$ManagerOptions _$v;

  bool _reconnection;
  bool get reconnection => _$this._reconnection;
  set reconnection(bool reconnection) => _$this._reconnection = reconnection;

  int _reconnectionAttempts;
  int get reconnectionAttempts => _$this._reconnectionAttempts;
  set reconnectionAttempts(int reconnectionAttempts) =>
      _$this._reconnectionAttempts = reconnectionAttempts;

  int _reconnectionDelay;
  int get reconnectionDelay => _$this._reconnectionDelay;
  set reconnectionDelay(int reconnectionDelay) =>
      _$this._reconnectionDelay = reconnectionDelay;

  int _reconnectionDelayMax;
  int get reconnectionDelayMax => _$this._reconnectionDelayMax;
  set reconnectionDelayMax(int reconnectionDelayMax) =>
      _$this._reconnectionDelayMax = reconnectionDelayMax;

  double _randomizationFactor;
  double get randomizationFactor => _$this._randomizationFactor;
  set randomizationFactor(double randomizationFactor) =>
      _$this._randomizationFactor = randomizationFactor;

  IoEncoder _encoder;
  IoEncoder get encoder => _$this._encoder;
  set encoder(IoEncoder encoder) => _$this._encoder = encoder;

  IoDecoder _decoder;
  IoDecoder get decoder => _$this._decoder;
  set decoder(IoDecoder decoder) => _$this._decoder = decoder;

  int _timeout;
  int get timeout => _$this._timeout;
  set timeout(int timeout) => _$this._timeout = timeout;

  SocketOptionsBuilder _options;
  SocketOptionsBuilder get options =>
      _$this._options ??= new SocketOptionsBuilder();
  set options(SocketOptionsBuilder options) => _$this._options = options;

  ManagerOptionsBuilder();

  ManagerOptionsBuilder get _$this {
    if (_$v != null) {
      _reconnection = _$v.reconnection;
      _reconnectionAttempts = _$v.reconnectionAttempts;
      _reconnectionDelay = _$v.reconnectionDelay;
      _reconnectionDelayMax = _$v.reconnectionDelayMax;
      _randomizationFactor = _$v.randomizationFactor;
      _encoder = _$v.encoder;
      _decoder = _$v.decoder;
      _timeout = _$v.timeout;
      _options = _$v.options?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ManagerOptions other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$ManagerOptions;
  }

  @override
  void update(void updates(ManagerOptionsBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$ManagerOptions build() {
    _$ManagerOptions _$result;
    try {
      _$result = _$v ??
          new _$ManagerOptions._(
              reconnection: reconnection,
              reconnectionAttempts: reconnectionAttempts,
              reconnectionDelay: reconnectionDelay,
              reconnectionDelayMax: reconnectionDelayMax,
              randomizationFactor: randomizationFactor,
              encoder: encoder,
              decoder: decoder,
              timeout: timeout,
              options: options.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'options';
        options.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'ManagerOptions', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}
