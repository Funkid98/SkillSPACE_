// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class SplineRobot extends StatefulWidget {
  final ValueNotifier<Offset?> mouseNotifier;
  final double width;
  final double height;

  const SplineRobot({
    super.key,
    required this.mouseNotifier,
    this.width = 240,
    this.height = 180,
  });

  @override
  State<SplineRobot> createState() => _SplineRobotState();
}

class _SplineRobotState extends State<SplineRobot> {
  late final String _viewId;
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _viewId = 'spline-robot-${DateTime.now().microsecondsSinceEpoch}';

    // ── Inject global CSS so flt-platform-view doesn't swallow pointer ──────
    // Without this the browser captures mouse events on the platform-view
    // container before Flutter's MouseRegion sees them, breaking cursor tracking.
    _injectPlatformViewFix();

    _iframe = html.IFrameElement()
      ..id = _viewId
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'transparent'
      ..style.pointerEvents = 'none'
      ..srcdoc = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body, html {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: transparent;
    }
    spline-viewer {
      width: 100%;
      height: 100%;
    }
  </style>
  <script type="module" src="https://unpkg.com/@splinetool/viewer@1.12.95/build/spline-viewer.js"></script>
</head>
<body>
  <spline-viewer id="spline" url="https://prod.spline.design/ky3EN5pZOYlB5BzF/scene.splinecode" hint="false"></spline-viewer>
  <script>
    window.addEventListener('message', (event) => {
      const spline = document.getElementById('spline');
      if (!spline) return;
      
      const canvas = spline.shadowRoot ? spline.shadowRoot.querySelector('canvas') : null;
      if (!canvas) return;
      
      const rect = canvas.getBoundingClientRect();
      let clientX, clientY;
      
      if (event.data.type === 'mousemove') {
        clientX = rect.left + (event.data.x * rect.width);
        clientY = rect.top + (event.data.y * rect.height);
      } else if (event.data.type === 'static') {
        clientX = rect.left + rect.width / 2;
        clientY = rect.top + rect.height / 2;
      } else {
        return;
      }
      
      const mouseEvent = new MouseEvent('mousemove', {
        clientX: clientX,
        clientY: clientY,
        bubbles: true,
        composed: true
      });
      canvas.dispatchEvent(mouseEvent);
      
      const pointerEvent = new PointerEvent('pointermove', {
        clientX: clientX,
        clientY: clientY,
        bubbles: true,
        composed: true,
        pointerId: 1,
        pointerType: 'mouse',
        isPrimary: true
      });
      canvas.dispatchEvent(pointerEvent);
    });

    // Hide "Built with Spline" watermark by injecting CSS into the shadow DOM
    function hideSplineLogo() {
      const viewer = document.getElementById('spline');
      if (!viewer) { setTimeout(hideSplineLogo, 300); return; }
      const shadow = viewer.shadowRoot;
      if (!shadow) { setTimeout(hideSplineLogo, 300); return; }
      if (!shadow.querySelector('#hide-logo-style')) {
        const style = document.createElement('style');
        style.id = 'hide-logo-style';
        style.textContent =
          'a[href*="spline"],' +
          '[class*="logo"],' +
          '[class*="watermark"],' +
          '[class*="badge"],' +
          'a[target="_blank"],' +
          '#hint, .hint, [id*="hint"], [class*="hint"],' +
          '#cursor, .cursor, [id*="cursor"], [class*="cursor"]' +
          '{ display:none !important; opacity:0 !important; pointer-events:none !important; }';
        shadow.appendChild(style);
      }
      ['a[href*="spline"]','[class*="logo"]','[class*="watermark"]','a[target="_blank"]','#hint','.hint','#cursor','.cursor'].forEach(sel => {
        shadow.querySelectorAll(sel).forEach(el => el.style.setProperty('display','none','important'));
      });
    }
    setTimeout(hideSplineLogo, 600);
    setTimeout(hideSplineLogo, 1800);
    setTimeout(hideSplineLogo, 4000);
  </script>
</body>
</html>
''';

    ui_web.platformViewRegistry
        .registerViewFactory(_viewId, (int viewId) => _iframe!);

    widget.mouseNotifier.addListener(_onMouseChanged);
  }

  @override
  void dispose() {
    widget.mouseNotifier.removeListener(_onMouseChanged);
    super.dispose();
  }

  void _injectPlatformViewFix() {
    // ── 1. Targeted CSS Fix: Apply pointer-events: none ONLY to this specific view ──
    // This prevents the iframe from blocking clicks on the navigation buttons above it.
    int retries = 0;
    void applyFix() {
      if (retries > 20) return;
      retries++;

      final iframe = _iframe;
      if (iframe != null && iframe.isConnected == true) {
        html.Element? current = iframe;
        while (current != null) {
          if (current.tagName.toLowerCase() == 'flt-platform-view') {
            current.style.pointerEvents = 'none';
            final slot =
                current.querySelector('flt-platform-view-slot-content');
            if (slot != null) {
              slot.style.pointerEvents = 'none';
            }
            return; // Success
          }
          final parentNode = current.parentNode;
          if (parentNode is html.ShadowRoot) {
            current = parentNode.host;
          } else {
            current = current.parent;
          }
        }
      }
      Future.delayed(const Duration(milliseconds: 100), applyFix);
    }

    Future.delayed(const Duration(milliseconds: 100), applyFix);

    // ── 2. JS mousemove on the window (capture phase) → postMessage to iframe ──
    // Bypasses Flutter's MouseRegion entirely so tracking never drops.
    html.window.addEventListener('mousemove', (html.Event event) {
      if (event is! html.MouseEvent) return;
      final e = event;

      final iframe = _iframe;
      if (iframe == null) return;
      final rect = iframe.getBoundingClientRect();
      if (rect.width == 0 || rect.height == 0) return;

      final x = (e.client.x - rect.left) / rect.width;
      final y = (e.client.y - rect.top) / rect.height;

      if (x < -0.1 || x > 1.1 || y < -0.1 || y > 1.1) {
        iframe.contentWindow?.postMessage({'type': 'static'}, '*');
        return;
      }
      iframe.contentWindow?.postMessage({
        'type': 'mousemove',
        'x': x.clamp(0.0, 1.0),
        'y': y.clamp(0.0, 1.0),
      }, '*');
    }, true);
  }

  void _onMouseChanged() {
    // Fallback for static/idle state from Flutter's MouseRegion
    final offset = widget.mouseNotifier.value;
    if (offset == null) {
      _iframe?.contentWindow?.postMessage({'type': 'static'}, '*');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
