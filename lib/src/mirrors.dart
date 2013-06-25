// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fancy_syntax.mirrors;

import 'dart:mirrors';

/**
 * Walks up the class hierarchy to find a method declaration with the given
 * [name].
 *
 * Note that it's not possible to tell if there's an implementation via
 * noSuchMethod().
 */
Mirror getMemberMirror(ClassMirror classMirror, Symbol name) {
  if (classMirror.members.containsKey(name)) {
    return classMirror.members[name];
  }
  if (hasSuperclass(classMirror)) {
    var mirror = getMemberMirror(classMirror.superclass, name);
    if (mirror != null) {
      return mirror;
    }
  }
  for (ClassMirror supe in classMirror.superinterfaces) {
    var mirror = getMemberMirror(supe, name);
    if (mirror != null) {
      return mirror;
    }
  }
  return null;
}

ClassMirror __objMirror;
ClassMirror get _objMirror {
  if (__objMirror == null) {
    __objMirror = reflectClass(Object);
  }
  return __objMirror;
}

/**
 * Work-around for http://dartbug.com/5794
 */
bool hasSuperclass(ClassMirror classMirror) {
  var superclass = classMirror.superclass;
  return (superclass != null) && (superclass != _objMirror);
}
