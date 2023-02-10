import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../extensions.dart';

class ValueFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final T? initialData;
  final Widget Function(BuildContext context, T value) builder;
  final Widget? emptyWidget;
  final Widget? errorWidget;

  const ValueFutureBuilder({
    Key? key,
    required this.future,
    this.initialData,
    required this.builder,
    this.emptyWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          snapshot.error.toString().log;
          return errorWidget ??
              emptyWidget ??
              // TODO Replace with Container() after Navigator migration
              const Material();
        }
        if (!snapshot.hasData) {
          // TODO Replace with Container() after Navigator migration
          return emptyWidget ?? const Material();
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}

class ValueStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final T? initialData;
  final Widget Function(BuildContext context, T value) builder;
  final Widget? emptyWidget;
  final Widget? errorWidget;

  const ValueStreamBuilder({
    Key? key,
    required this.stream,
    this.initialData,
    required this.builder,
    this.emptyWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData ??
          (stream is BehaviorSubject
              ? (stream as BehaviorSubject).valueOrNull
              : null),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          snapshot.error.toString().log;
          return errorWidget ??
              emptyWidget ??
              // TODO Replace with Container() after Navigator migration
              const Material();
        }
        if (!snapshot.hasData) {
          // TODO Replace with Container() after Navigator migration
          return emptyWidget ?? const Material();
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}
