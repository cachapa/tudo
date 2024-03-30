import 'package:flutter/material.dart';

typedef MasterBuilder = Widget Function(
    BuildContext context, bool isMasterDetail);
typedef DetailBuilder = Widget? Function(
    BuildContext context, bool isMasterDetail);
typedef EmptyBuilder = Widget Function(BuildContext context);

class MasterDetail extends StatelessWidget {
  final double thresholdWidth;
  final double masterWidth;
  final MasterBuilder masterBuilder;
  final DetailBuilder detailBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final VoidCallback onPopDetail;

  const MasterDetail({
    super.key,
    this.thresholdWidth = 700.0,
    this.masterWidth = 340.0,
    required this.masterBuilder,
    required this.detailBuilder,
    this.emptyBuilder,
    required this.onPopDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.sizeOf(context).width > thresholdWidth;
    final master = masterBuilder(context, isLargeScreen);
    final detail = detailBuilder(context, isLargeScreen);

    return isLargeScreen
        ? _buildLarge(context, master, detail)
        : _buildSmall(context, master, detail);
  }

  Widget _buildSmall(BuildContext context, Widget master, Widget? detail) {
    return PopScope(
      canPop: detail == null,
      onPopInvoked: (didPop) {
        if (detail != null) onPopDetail();
      },
      child: Navigator(
        pages: [
          MaterialPage(child: master),
          if (detail != null) MaterialPage(child: detail),
        ],
        onPopPage: (route, result) {
          onPopDetail();
          return false;
        },
      ),
    );
  }

  Widget _buildLarge(BuildContext context, Widget master, Widget? detail) {
    return Row(
      children: [
        SizedBox(
          width: masterWidth,
          child: master,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: Durations.medium2,
            child: detail ?? emptyBuilder?.call(context) ?? const SizedBox(),
          ),
        ),
      ],
    );
  }
}
