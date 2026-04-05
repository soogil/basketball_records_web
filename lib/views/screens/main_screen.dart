import 'dart:js_interop';
import 'dart:ui' as ui;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iggys_point/presenters/contracts/main_contract.dart';
import 'package:iggys_point/presenters/main_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:web/web.dart' as web;

import 'package:iggys_point/views/widgets/main_app_bar.dart';
import 'package:iggys_point/views/widgets/player_table_row.dart';

final isMobileProvider = Provider.family<bool, BuildContext>((ref, context) {
  return MediaQuery.of(context).size.width < 600;
});

class MainScreen extends HookConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureKey = useMemoized(() => GlobalKey());
    final isCapturingState = useState<bool>(false);
    final captureState = useState<MainState?>(null);

    Future<void> captureFullList(MainState state) async {
      isCapturingState.value = true;
      captureState.value = state;

      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 80));

      try {
        final boundary = captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) return;

        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return;

        final bytes = Uint8List.view(byteData.buffer);
        final blob = web.Blob(
          [bytes.toJS].toJS,
          web.BlobPropertyBag(type: 'image/png'),
        );
        final url = web.URL.createObjectURL(blob);
        final anchor =
            web.document.createElement('a') as web.HTMLAnchorElement;
        anchor.href = url;
        anchor.download =
            '이기스포인트_${ref.read(selectedSeasonProvider)}.png';
        web.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        web.URL.revokeObjectURL(url);
      } finally {
        isCapturingState.value = false;
        captureState.value = null;
      }
    }

    bool handleKeyEvent(KeyEvent event) {
      if (event is KeyDownEvent &&
          HardwareKeyboard.instance.isControlPressed &&
          HardwareKeyboard.instance.isShiftPressed &&
          event.logicalKey == LogicalKeyboardKey.keyA) {
        ref.read(mainAdminModeProvider.notifier).state = true;
        return true;
      }
      return false;
    }

    useEffect(() {
      HardwareKeyboard.instance.addHandler(handleKeyEvent);
      return () => HardwareKeyboard.instance.removeHandler(handleKeyEvent);
    }, []);

    Future<void> deleteAllCookies() async {
      final cookies = web.document.cookie.split(';');
      for (var cookie in cookies) {
        final eqPos = cookie.indexOf('=');
        final name = eqPos > -1 ? cookie.substring(0, eqPos) : cookie;
        web.document.cookie =
            '$name=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/';
      }
      web.window.location.reload();
    }

    final presenterState = ref.watch(mainPresenterProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: deleteAllCookies,
            child: presenterState.when(
              skipLoadingOnReload: true,
              data: (state) => CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  MainAppBar(
                    state: state,
                    isCapturing: isCapturingState.value,
                    onCapture: captureFullList,
                  ),
                  SliverStickyHeader(
                    header: const PlayerTableHeader(),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        state.players
                            .asMap()
                            .entries
                            .map((e) => PlayerTableRow(
                                player: e.value, index: e.key))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('에러 발생: $error')),
            ),
          ),
          if (isCapturingState.value && captureState.value != null)
            Positioned(
              left: -(screenWidth + 100),
              top: 0,
              width: screenWidth,
              child: RepaintBoundary(
                key: captureKey,
                child: Material(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PlayerTableHeader(),
                      ...captureState.value!.players.asMap().entries.map(
                            (e) => PlayerTableRow(
                                player: e.value, index: e.key),
                          ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
