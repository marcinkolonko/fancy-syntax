// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:fancy_syntax/syntax.dart';

import 'person.dart';

main() {
  TemplateElement.syntax['fancy'] = new FancySyntax(scope: {
    'uppercase' : (String v) => v.toUpperCase(),
  });
  var john = new Person('John', 'Messerly');
  query('#test').model = john;
  query('#test2').model = john;
}
