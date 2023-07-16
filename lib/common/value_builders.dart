import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../extensions.dart';

Widget _defaultEmptyBuilder(BuildContext context) => const SizedBox();

Widget _defaultErrorBuilder(BuildContext context, Object error) =>
    Text('$error');

class ValueStreamBuilder<T> extends StatefulWidget {
  final T? initialValue;
  final Stream<T> stream;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, T value) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const ValueStreamBuilder({
    super.key,
    this.initialValue,
    required this.stream,
    this.emptyBuilder,
    required this.builder,
    this.errorBuilder,
  });

  @override
  State<ValueStreamBuilder<T>> createState() => _ValueStreamBuilderState<T>();
}

class _ValueStreamBuilderState<T> extends State<ValueStreamBuilder<T>> {
  var _hasData = false;
  late T _value;
  Object? _error;

  StreamSubscription<T>? _subscription;

  T? get _initialValue {
    if (widget.initialValue != null) widget.initialValue;
    if (widget.stream is BehaviorSubject) {
      final stream = widget.stream as BehaviorSubject;
      if (stream.hasValue) return stream.value;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream.listen((e) => setState(() {
          _hasData = true;
          _value = e;
        }))
      ..onError((e) => setState(() => _error = e));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) '$_error'.log;

    return _error != null
        ? widget.errorBuilder?.call(context, _error!) ??
            _defaultErrorBuilder(context, _error!)
        : _hasData
            ? widget.builder(context, _value)
            : _initialValue != null
                ? widget.builder(context, _initialValue as T)
                : widget.emptyBuilder?.call(context) ??
                    _defaultEmptyBuilder(context);
  }
}

class ValueFutureBuilder<T> extends StatefulWidget {
  final T? initialValue;
  final Future<T> future;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, T value) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const ValueFutureBuilder({
    super.key,
    this.initialValue,
    required this.future,
    this.emptyBuilder,
    required this.builder,
    this.errorBuilder,
  });

  @override
  State<ValueFutureBuilder<T>> createState() => _ValueFutureBuilderState<T>();
}

class _ValueFutureBuilderState<T> extends State<ValueFutureBuilder<T>> {
  var _hasData = false;
  late T _value;
  Object? _error;

  @override
  void initState() {
    super.initState();
    widget.future.then((e) {
      if (mounted) {
        setState(() {
          _hasData = true;
          _value = e;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _error = e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _error != null
        ? widget.errorBuilder?.call(context, _error!) ??
            _defaultErrorBuilder(context, _error!)
        : _hasData
            ? widget.builder(context, _value)
            : widget.initialValue != null
                ? widget.builder(context, widget.initialValue as T)
                : widget.emptyBuilder?.call(context) ??
                    _defaultEmptyBuilder(context);
  }
}
