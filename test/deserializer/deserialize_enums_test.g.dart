// GENERATED CODE - DO NOT MODIFY BY HAND

part of deserialiazer.deserialize_enums_test;

// **************************************************************************
// Generator: DsonGenerator
// **************************************************************************

abstract class _$ObjectWithEnumSerializable extends SerializableMap {
  Color get color;
  void set color(Color v);

  operator [](Object key) {
    switch (key) {
      case 'color':
        return color;
    }
    throwFieldNotFoundException(key, 'ObjectWithEnum');
  }

  operator []=(Object key, value) {
    switch (key) {
      case 'color':
        color = value;
        return;
    }
    throwFieldNotFoundException(key, 'ObjectWithEnum');
  }

  Iterable<String> get keys => ObjectWithEnumClassMirror.fields.keys;
}

// **************************************************************************
// Generator: MirrorsGenerator
// **************************************************************************

const ColorClassMirror =
    const ClassMirror(name: 'Color', isEnum: true, values: Color.values);
_ObjectWithEnum__Constructor(params) => new ObjectWithEnum();

const $$ObjectWithEnum_fields_color = const DeclarationMirror(type: Color);

const ObjectWithEnumClassMirror =
    const ClassMirror(name: 'ObjectWithEnum', constructors: const {
  '': const FunctionMirror(
      parameters: const {}, call: _ObjectWithEnum__Constructor)
}, fields: const {
  'color': $$ObjectWithEnum_fields_color
}, getters: const [
  'color'
], setters: const [
  'color'
]);

// **************************************************************************
// Generator: InitMirrorsGenerator
// **************************************************************************

_initMirrors() {
  initClassMirrors(
      {Color: ColorClassMirror, ObjectWithEnum: ObjectWithEnumClassMirror});
  initFunctionMirrors({});
}
