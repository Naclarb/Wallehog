import '../../shared/sound_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../app/design_tokens.dart';
import '../../application/records_controller.dart';
import '../../domain/expression_parser.dart';
import 'goal_carousel.dart';
import 'recent_savings.dart';
import 'tablet_navigation.dart';
import '../entry/entry_page.dart';
import '../../domain/saving_record.dart';
import '../entry/calculator_sheet.dart';

import '../help/help_page.dart';
import '../../domain/pig_growth.dart';

import '../../domain/encouragement.dart';
import '../../domain/deposit_moment.dart';
import '../../shared/coin_deposit_feedback.dart';
import '../../shared/inline_pig.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});
  final RecordsController controller;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  RecordsController get controller => widget.controller;
  final _encouragements = Encouragements();
  bool _adding = false;
  bool _goalTurning = false;
  bool _addPressed = false;
  Offset? _pigPosition;
  Offset? _pigDragStart;
  bool _draggingPig = false;
  bool _returnConsumed = false;
  int _feedbackEvent = 0;
  int _flyawayEvent = 0;
  final _pigImage = GlobalKey();
  late final _depositMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _cancelDeposit() {
    _feedbackEvent++;
    _depositTimer?.cancel();
    _depositMotion.stop();
    _depositMotion.value = 0;
    setState(() => _deposit = null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancelDeposit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _depositMotion.value = 1;
  }

  Widget? _deposit;
  Timer? _depositTimer;
  late final _addPulse = AnimationController(
    vsync: this,
    duration: AppMotion.response,
  );
  Future<void> _add() async {
    if (_adding || _goalTurning || !controller.canWrite) return;
    _adding = true;
    _cancelDeposit();
    final returning =
        !_returnConsumed &&
        controller.records.isNotEmpty &&
        controller.records.every(
          (r) => DateTime.now().difference(r.createdAt).inDays >= 7,
        );
    final previousIds = controller.records.map((r) => r.id).toSet();
    final previousProgress = controller.goalProgressMinor;
    final previousGrowth = PigGrowth(controller.summary.goodChoices);
    final previousGoal = controller.goal;
    int? amount;
    try {
      amount = await showCalculator(context, controller);
    } finally {
      _adding = false;
    }
    if (amount != null && mounted) {
      if (_page == 0 && _pigImage.currentContext != null) {
        await Scrollable.ensureVisible(_pigImage.currentContext!);
        if (!mounted) return;
      }
      if (!MediaQuery.disableAnimationsOf(context)) _addPulse.forward(from: 0);
      final added = controller.records
          .where((r) => !previousIds.contains(r.id))
          .toList();
      // 只对一个真正新增的记录发出回应，重读/重复请求不额外庆祝。
      if (added.length != 1) return;
      final sameGoal =
          previousGoal != null && previousGoal.id == controller.goal?.id;
      final moment = depositMoment(
        newRecordId: added.single.id!,
        targetMinor: sameGoal ? previousGoal.targetMinor : null,
        beforeMinor: previousProgress,
        afterMinor: controller.goalProgressMinor,
      );
      _returnConsumed = true;
      final scene = switch (moment) {
        DepositMoment.firstSaving => EncouragementScene.firstSaving,
        DepositMoment.halfway => EncouragementScene.halfway,
        _ => encouragementScene(
          completed: moment == DepositMoment.completed,
          fraction: controller.goal?.progressFraction(controller.records) ?? 0,
          returning: returning,
        ),
      };
      final event = ++_feedbackEvent;
      final growth = PigGrowth(controller.summary.goodChoices);
      var levelUp = false;
      if (previousGrowth.crossedByNewRecord(growth.choices) &&
          controller.canWrite &&
          controller.repository is GrowthCelebrationStore) {
        try {
          levelUp = await (controller.repository as GrowthCelebrationStore)
              .claimGrowthCelebration(growth.level);
        } catch (_) {
          // 记录已经成功。去重存储失败时只给普通反馈，避免重复庆祝。
        }
      }
      if (!mounted || event != _feedbackEvent) return;
      setState(
        () => _deposit = CoinDepositFeedback(
          targetKey: _pigImage,
          motion: _depositMotion,
          key: ValueKey(event),
          level: growth.level,
          levelUp: levelUp,
          moment: moment,
          reaction: added.single.id!.isEven ? 1 : 0,
          amount: '+¥${formatMoney(amount!)}',
          message: _encouragements.pick(scene),
        ),
      );
      if (MediaQuery.disableAnimationsOf(context)) {
        _depositMotion.value = 1;
      } else {
        _depositMotion.forward(from: 0);
      }
      final celebration = levelUp || moment == DepositMoment.completed;
      final soundDelay = celebration || MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 550);
      Future.delayed(soundDelay, () {
        if (!mounted || event != _feedbackEvent || _deposit == null) return;
        SoundService.play(celebration ? 'celebrate' : 'coin');
      });
      _depositTimer?.cancel();
      _depositTimer = Timer(const Duration(milliseconds: 2300), () {
        if (mounted) setState(() => _deposit = null);
      });
    }
  }

  int _page = 0;

  void _home() {
    _cancelDeposit();
    setState(() => _page = 0);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _help() {
    _cancelDeposit();
    setState(() => _page = 1);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final tablet = constraints.maxWidth >= 600;
        final home = _homeContent(tablet: tablet);
        return PopScope(
          canPop: _page == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _page != 0) _home();
          },
          child: Scaffold(
            backgroundColor: pageBackground,
            bottomNavigationBar: tablet ? null : _bottomNavigation(),
            body: Stack(
              children: [
                Positioned.fill(
                  child: tablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TabletNavigation(
                              selectedIndex: _page,
                              primaryAction: _addButton(),
                              onHome: _home,
                              onHelp: _help,
                            ),
                            Expanded(child: _pageContent(home)),
                          ],
                        )
                      : _pageContent(home),
                ),
                if (_page == 0)
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, area) {
                        final safeTop = MediaQuery.paddingOf(context).top;
                        final maxX = math.max(0.0, area.maxWidth - 84);
                        final minY = math.min(
                          safeTop,
                          math.max(0.0, area.maxHeight - 78),
                        );
                        final maxY = math.max(minY, area.maxHeight - 78);
                        final initialX = tablet
                            ? math.max(0.0, area.maxWidth - 116)
                            : math.max(0.0, area.maxWidth - 104);
                        final position =
                            _pigPosition ?? Offset(initialX, minY + 4);
                        final x = position.dx.clamp(0.0, maxX);
                        final y = position.dy.clamp(minY, maxY);
                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration:
                                  _draggingPig ||
                                      MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              left: x,
                              top: y,
                              child: GestureDetector(
                                key: const Key('draggablePig'),
                                onLongPressStart: (_) => setState(() {
                                  _draggingPig = true;
                                  _pigDragStart = Offset(x, y);
                                  _cancelDeposit();
                                }),
                                onLongPressMoveUpdate: (details) =>
                                    setState(() {
                                      _pigPosition = Offset(
                                        ((_pigDragStart?.dx ?? x) +
                                                details.offsetFromOrigin.dx)
                                            .clamp(0.0, maxX),
                                        ((_pigDragStart?.dy ?? y) +
                                                details.offsetFromOrigin.dy)
                                            .clamp(minY, maxY),
                                      );
                                    }),
                                onLongPressEnd: (_) => setState(() {
                                  final p = _pigPosition ?? Offset(x, y);
                                  final distances = [
                                    p.dx,
                                    maxX - p.dx,
                                    p.dy - minY,
                                    maxY - p.dy,
                                  ];
                                  final nearest = distances.indexOf(
                                    distances.reduce(math.min),
                                  );
                                  _pigPosition = switch (nearest) {
                                    0 => Offset(0, p.dy),
                                    1 => Offset(maxX, p.dy),
                                    2 => Offset(p.dx, minY),
                                    _ => Offset(p.dx, maxY),
                                  };
                                  _draggingPig = false;
                                }),
                                child: InlinePig(
                                  imageKey: _pigImage,
                                  depositMotion: _depositMotion,
                                  flyawayEvent: _flyawayEvent,
                                  cancelEvent: _feedbackEvent,
                                  level: PigGrowth(
                                    controller.summary.goodChoices,
                                  ).level,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                if (_deposit != null && _page == 0)
                  Positioned.fill(child: _deposit!),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _addButton() => AnimatedBuilder(
    animation: _addPulse,
    builder: (context, child) => Transform.scale(
      key: const Key('addPulse'),
      scale: MediaQuery.disableAnimationsOf(context)
          ? 1
          : 1 - .045 * math.sin(math.pi * _addPulse.value),
      child: child,
    ),
    child: Listener(
      onPointerDown: (_) => setState(() => _addPressed = true),
      onPointerUp: (_) => setState(() => _addPressed = false),
      onPointerCancel: (_) => setState(() => _addPressed = false),
      child: AnimatedScale(
        key: const Key('addPress'),
        scale: _addPressed && !MediaQuery.disableAnimationsOf(context)
            ? .94
            : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: IconButton.filled(
          key: const Key('newRecord'),
          tooltip: '记录节省',
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            maximumSize: const Size(48, 48),
            backgroundColor: primaryPink,
            foregroundColor: ink,
            // 切换心愿期间仍禁用录入，但不切换为灰色，避免底栏闪烁。
            disabledBackgroundColor: primaryPink,
            disabledForegroundColor: ink,
            shape: const CircleBorder(),
          ),
          onPressed: controller.busy || !controller.loaded || _goalTurning
              ? null
              : _add,
          icon: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    ),
  );

  Widget _bottomNavigation() => Container(
    decoration: const BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: SizedBox(
        key: const Key('bottomNavigationContent'),
        height: 56,
        child: Row(
          children: [
            _navItem(
              '首页',
              Icons.home_outlined,
              const Key('homeTab'),
              _home,
              selected: _page == 0,
            ),
            Expanded(child: Center(child: _addButton())),
            _navItem(
              '帮助',
              Icons.help_outline_rounded,
              const Key('helpTab'),
              _help,
              selected: _page == 1,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _homeContent({required bool tablet}) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: tablet ? 1120 : AppSize.contentMax,
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tablet ? 32 : 20,
                  tablet ? 24 : 4,
                  tablet ? 32 : 20,
                  0,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 78),
                    SizedBox(height: tablet ? 24 : 6),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  key: const Key('homeScroll'),
                  padding: EdgeInsets.fromLTRB(
                    tablet ? 32 : 20,
                    0,
                    tablet ? 32 : 20,
                    96,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!controller.loaded) ...[
                        Text(controller.error ?? '正在唤醒小猪…'),
                        if (!controller.busy)
                          TextButton(
                            onPressed: controller.load,
                            child: const Text('重新读取'),
                          ),
                      ] else
                        LayoutBuilder(
                          builder: (context, area) {
                            final split =
                                tablet &&
                                area.maxWidth >= 760 &&
                                MediaQuery.textScalerOf(context).scale(14) <=
                                    21;
                            final goal = GoalCarousel(
                              controller: controller,
                              spacious: split,
                              onTransitionChanged: (turning) {
                                if (turning) _cancelDeposit();
                                if (mounted) {
                                  setState(() => _goalTurning = turning);
                                }
                              },
                            );
                            final summary = _savedMoney();
                            final recent = RecentSavings(
                              records: controller.records,
                              enabled: controller.canWrite,
                              onDelete: (record) async {
                                _cancelDeposit();
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('删除这笔记录？'),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    content: const Text('删除后无法撤销。'),
                                    actions: [
                                      IconButton(
                                        tooltip: '取消',
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                      IconButton(
                                        key: const Key('confirmDeleteSaving'),
                                        tooltip: '确认删除',
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: deepPink,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && !controller.busy) {
                                  final goalId = controller.goal?.id;
                                  final before = controller.goalProgressMinor;
                                  final success = await controller.delete(
                                    record.id!,
                                  );
                                  if (mounted &&
                                      success &&
                                      goalId != null &&
                                      controller.goal?.id == goalId &&
                                      controller.goalProgressMinor < before) {
                                    setState(() => _flyawayEvent++);
                                  }
                                }
                              },
                              onRecord: (record) {
                                _cancelDeposit();
                                if (record.kind == DecisionKind.forgone) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => EntryPage(
                                        controller: controller,
                                        record: record,
                                      ),
                                    ),
                                  );
                                } else {
                                  showCalculator(
                                    context,
                                    controller,
                                    record: record,
                                  );
                                }
                              },
                            );
                            if (split) {
                              return Row(
                                key: const Key('tabletColumns'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 6, child: goal),
                                  const SizedBox(width: 28),
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        summary,
                                        const SizedBox(height: 28),
                                        recent,
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: tablet ? 640 : double.infinity,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    goal,
                                    const SizedBox(height: 10),
                                    summary,
                                    const SizedBox(height: 12),
                                    recent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      if (controller.error != null && controller.loaded)
                        Text(
                          controller.error!,
                          style: const TextStyle(color: deepPink),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _savedMoney() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('累计节省', style: AppType.caption),
      const SizedBox(height: 4),
      Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: controller.summary.savedMinor.toDouble()),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => Text(
              '¥${formatMoney(value.round())}',
              key: const Key('savedMoney'),
              style: AppType.savedAmount,
            ),
          ),
        ),
      ),
    ],
  );
  final _scrollController = ScrollController();
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _depositMotion.dispose();
    _depositTimer?.cancel();
    _scrollController.dispose();
    _addPulse.dispose();
    super.dispose();
  }

  Widget _pageContent(Widget home) => switch (_page) {
    1 => HelpPage(controller: controller),
    _ => home,
  };

  Widget _navItem(
    String label,
    IconData icon,
    Key key,
    VoidCallback? onTap, {
    bool selected = false,
  }) => Expanded(
    child: Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        child: InkWell(
          key: key,
          onTap: onTap,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: .08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 25,
                color: selected ? primaryPink : Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
