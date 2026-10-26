import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

final Set<String> _registeredViews = {};

Widget buildWebDocumentPreview(String url) {
  final viewType = 'document-image-${url.hashCode}';

  if (_registeredViews.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final image = html.ImageElement()
        ..src = url
        ..alt = 'Documento oficial'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain';

      return html.DivElement()
        ..style.width = '100%'
        ..style.height = '70vh'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..children.add(image);
    });
  }

  return SizedBox(
    width: double.infinity,
    height: 600,
    child: HtmlElementView(viewType: viewType),
  );
}
