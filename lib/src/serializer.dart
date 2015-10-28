part of dson;

Logger _serLog = new Logger('object_mapper_serializer');

/// Variable that save all the serialized objects. If an object 
/// has been serilized in the past is going to be saved by this variable
/// and is not going to be serialized again.
Map<Object, Map> _serializedStack = {};

/// Checks if the [value] is primitive (String, number, boolean or null)
bool isPrimitive(value) => value is String || value is num || value is bool || value == null;

/// Checks if the [value] is primitive, [DateTime], [List], or [Map]
bool isSimple(value) => isPrimitive(value) || value is DateTime || value is List || value is Map;

/// Serializes the [object] to a JSON string.
/// 
/// Parameters:
/// 
/// [depth] :  determines how deep is going to be the serialization and to avoid cyclical object reference stack overflow. 
/// [exclude] : exclude some attributes. It could be [String], [Map], or [List]
String toJson(object, {bool parseString: false, depth, exclude}) {
  _serLog.fine("Start serializing");

  if (object is String && !parseString) return object;
  
  var result = JSON.encode(objectToSerializable(object, depth: depth, exclude: exclude));

  _serializedStack.clear();

  return result;
}


/// Converts the non-primitive [object] to a serializable [Map].
///
/// Parameters:
///
/// * [depth] :  determines how deep is going to be the serialization and to avoid cyclical object reference stack overflow.
/// * [exclude] : exclude some attributes. It could be [String], [Map], or [List]
Map toMap(object, {depth, exclude, String fieldName}) =>
    objectToSerializable(object, depth: depth, exclude: exclude);

/// Converts the [object] to a serializable [Map], [String], [int], [DateTime]
/// or any other serializiable object.
/// 
/// Parameters:
/// 
/// * [depth] :  determines how deep is going to be the serialization and to avoid cyclical object reference stack overflow. 
/// * [exclude] : exclude some attributes. It could be [String], [Map], or [List]
Object objectToSerializable(object, {depth, exclude, String fieldName}) {
  if (isPrimitive(object)) {
    _serLog.fine("Found primetive: $object");
    return object;
  } else if (object is DateTime) {
    _serLog.fine("Found DateTime: $object");
    return object.toIso8601String();
  } else if (object is List) {
    _serLog.fine("Found list: $object");
    return _serializeList(object, depth, exclude, fieldName);
  } else if (object is Map) {
    _serLog.fine("Found map: $object");
    return _serializeMap(object, depth, exclude, fieldName);
  } else {
    _serLog.fine("Found object: $object");
    return _serializeObject(object, depth, exclude, fieldName);
  }
}

/// Converts a List into a serializable [List]
List _serializeList(List list, depth, exclude, String fieldName) {
  List newList = [];

  list.forEach((item) {
    newList.add(objectToSerializable(item, depth: depth, exclude: exclude, fieldName: fieldName));
  });

  return newList;
}

/// Converts a [Map] into a serializable [Map]
Map _serializeMap(Map map, depth, exclude, String fieldName) {
  Map newMap = new Map<String, Object>();
  map.forEach((key, val) {
    if (val != null) {
      newMap[key] = objectToSerializable(val, depth: depth, exclude: exclude, fieldName: fieldName);
    }
  });

  return newMap;
}

/// Runs through the Object keys by using a ClassMirror.
Object _serializeObject(obj, depth, exclude, fieldName) {
  InstanceMirror instMirror = serializable.reflect(obj);
  ClassMirror classMirror = instMirror.type;
  _serLog.fine("Serializing class: ${classMirror.qualifiedName}");

  Map result = new Map<String, dynamic>();

  if (_serializedStack[obj] == null) {

    var publicVariables = getPublicVariablesAndGettersFromClass(classMirror, serializable);
    depth = _getNextDepth(depth, fieldName);
    if (depth != null || !_isCiclical(obj, instMirror) || fieldName == null) {
      publicVariables.forEach((fieldName, decl) {
        _pushField(fieldName, decl, instMirror, result, depth, exclude);
      });

      _serializedStack[obj] = result;
    }
    
    if (_isCiclical(obj, instMirror)) {
      if (publicVariables['id'] == null) {
        result['hashcode'] = obj.hashCode;
      } else {
        result['id'] = obj.id;
      }
    }

  } else {
    result = _serializedStack[obj];
  }

  _serLog.fine("Serialization completed.");
  return result;
}

/// Checks the DeclarationMirror [variable] for annotations and adds
/// the value to the [result] map. If there's no [SerializedName] annotation
/// with a different name set it will use the name of [symbol].
void _pushField(String fieldName, DeclarationMirror variable, InstanceMirror instMirror, Map<String, dynamic> result, depth, exclude) {

  if (fieldName.isEmpty) return;

//  InstanceMirror field = instMirror.invokeGetter(fieldName);
  Object value = instMirror.invokeGetter(fieldName);
  _serLog.finer("Start serializing field: ${fieldName}");

  // check if there is a DartsonProperty annotation
  SerializedName prop = new GetValueOfAnnotation<SerializedName>().fromDeclaration(variable);
  _serLog.finest("Property Annotation: ${prop}");

  if (prop != null && prop.name != null) {
    _serLog.finer("Field renamed to: ${prop.name}");
    fieldName = prop.name;
  }


  _serLog.finer("depth: $depth");

  //If the value is not null and the annotation @ignore is not on variable declaration
  if (value != null && !new IsAnnotation<_Ignore>().onDeclaration(variable)
      // And exclude is pressent
      && (exclude == null
        // or exclude is Map (we are excluding nested attribute)
        || exclude is Map
        // or exclude is String and fieldName distinct of exclude (we exclude this attribute)
        || exclude is String && fieldName != exclude
        // or exclude is List and exclude contains this fieldName (we exclude this attribute)
        || exclude is List && !exclude.contains(fieldName))) {

    _serLog.finer("Serializing field: ${fieldName}");

    result[fieldName] = objectToSerializable(value,
        depth: depth,
        exclude: _getNext(exclude, fieldName),
        fieldName: fieldName);
  }
}

/// Cheks if the value is not Simple (primitive, datetime, List, or Map)
/// and if the annotation [Cyclical] is not over the class of the object
_isCiclical(value, InstanceMirror im) =>
  !isSimple(value) && new IsAnnotation<_Cyclical>().onInstance(im);

/// Gets the next depth from the actual depth for the nested attribute with name [fieldName]
_getNextDepth(depth, String fieldName) {
  if(fieldName != null) {
    return _getNext(depth, fieldName);
  } else {
    return depth;
  }
}

/// Gets the next [excludeOrDepth] for the nested attribute with name [fieldName]
_getNext(excludeOrDepth, String fieldName) {
  if (excludeOrDepth is List) {
    excludeOrDepth = excludeOrDepth.firstWhere((e) => //
        e == fieldName || e is Map && e.keys.contains(fieldName), orElse: () => null);
  }
  
  if(excludeOrDepth is Map) return excludeOrDepth[fieldName];
  
  if(excludeOrDepth is String && excludeOrDepth == fieldName) return excludeOrDepth;
}