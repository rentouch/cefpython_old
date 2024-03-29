# Copyright (c) 2012-2013 The CEF Python authors. All rights reserved.
# License: New BSD License.
# Website: http://code.google.com/p/cefpython/

# -----------------------------------------------------------------------------
# CEF values to Python values
# -----------------------------------------------------------------------------

cdef object CheckForCefPythonMessageHash(CefRefPtr[CefBrowser] cefBrowser,
        py_string pyString):
    # A javascript callback from the Renderer process is sent as a string.
    # TODO: this could be sent using CefBinaryNamedString in the future,
    #       see this topic "Sending custom data types using process messaging":
    #       http://www.magpcss.org/ceforum/viewtopic.php?f=6&t=10881
    cdef py_string cefPythonMessageHash = "####cefpython####"
    cdef JavascriptCallback jsCallback
    cdef py_string jsonData
    cdef object message
    if pyString.startswith(cefPythonMessageHash):
        jsonData = pyString[len(cefPythonMessageHash):]
        message = json.loads(jsonData)
        if message and type(message) == dict and ("what" in message) \
                and message["what"] == "javascript-callback":
            jsCallback = CreateJavascriptCallback(
                    message["callbackId"], cefBrowser,
                    message["frameId"], message["functionName"])
            return jsCallback
    return pyString

cdef list CefListValueToPyList(
        CefRefPtr[CefBrowser] cefBrowser,
        CefRefPtr[CefListValue] cefListValue,
        int nestingLevel=0):
    assert cefListValue.get().IsValid(), "cefListValue is invalid"
    if nestingLevel > 8:
        raise Exception("CefListValueToPyList(): max nesting level (8)"
                " exceeded")
    cdef int index
    cdef int size = cefListValue.get().GetSize()
    cdef cef_types.cef_value_type_t valueType
    cdef list ret = []
    cdef CefRefPtr[CefBinaryValue] binaryValue
    cdef cef_types.uint32 uint32_value
    cdef cef_types.int64 int64_value
    cdef object originallyString
    for index in range(0, size):
        valueType = cefListValue.get().GetType(index)
        if valueType == cef_types.VTYPE_NULL:
            ret.append(None)
        elif valueType == cef_types.VTYPE_BOOL:
            ret.append(bool(cefListValue.get().GetBool(index)))
        elif valueType == cef_types.VTYPE_INT:
            ret.append(cefListValue.get().GetInt(index))
        elif valueType == cef_types.VTYPE_DOUBLE:
            ret.append(cefListValue.get().GetDouble(index))
        elif valueType == cef_types.VTYPE_STRING:
            originallyString = CefToPyString(
                    cefListValue.get().GetString(index))
            originallyString = CheckForCefPythonMessageHash(cefBrowser,
                    originallyString)
            ret.append(originallyString)
        elif valueType == cef_types.VTYPE_DICTIONARY:
            ret.append(CefDictionaryValueToPyDict(
                    cefBrowser,
                    cefListValue.get().GetDictionary(index),
                    nestingLevel + 1))
        elif valueType == cef_types.VTYPE_LIST:
            ret.append(CefListValueToPyList(
                    cefBrowser,
                    cefListValue.get().GetList(index),
                    nestingLevel + 1))
        elif valueType == cef_types.VTYPE_BINARY:
            binaryValue = cefListValue.get().GetBinary(index)
            if binaryValue.get().GetSize() == sizeof(uint32_value):
                binaryValue.get().GetData(
                        &uint32_value, sizeof(uint32_value), 0)
                ret.append(uint32_value)
            elif binaryValue.get().GetSize() == sizeof(int64_value):
                binaryValue.get().GetData(
                        &int64_value, sizeof(int64_value), 0)
                ret.append(int64_value)
            else:
                raise Exception("Unknown binary value, size=%s" % \
                        binaryValue.get().GetSize())
        else:
            raise Exception("Unknown value type=%s" % valueType)
    return ret

cdef dict CefDictionaryValueToPyDict(
        CefRefPtr[CefBrowser] cefBrowser,
        CefRefPtr[CefDictionaryValue] cefDictionaryValue,
        int nestingLevel=0):
    assert cefDictionaryValue.get().IsValid(), "cefDictionaryValue is invalid"
    if nestingLevel > 8:
        raise Exception("CefDictionaryValueToPyDict(): max nesting level (8)"
                " exceeded")
    cdef cpp_vector[CefString] keyList
    cefDictionaryValue.get().GetKeys(keyList)
    cdef cef_types.cef_value_type_t valueType
    cdef dict ret = {}
    cdef cpp_vector[CefString].iterator iterator = keyList.begin()
    cdef CefString cefKey
    cdef py_string pyKey
    cdef CefRefPtr[CefBinaryValue] binaryValue
    cdef cef_types.uint32 uint32_value
    cdef cef_types.int64 int64_value
    cdef object originallyString
    while iterator != keyList.end():
        cefKey = deref(iterator)
        pyKey = CefToPyString(cefKey)
        preinc(iterator)
        valueType = cefDictionaryValue.get().GetType(cefKey)
        if valueType == cef_types.VTYPE_NULL:
            ret[pyKey] = None
        elif valueType == cef_types.VTYPE_BOOL:
            ret[pyKey] = bool(cefDictionaryValue.get().GetBool(cefKey))
        elif valueType == cef_types.VTYPE_INT:
            ret[pyKey] = cefDictionaryValue.get().GetInt(cefKey)
        elif valueType == cef_types.VTYPE_DOUBLE:
            ret[pyKey] = cefDictionaryValue.get().GetDouble(cefKey)
        elif valueType == cef_types.VTYPE_STRING:
            originallyString = CefToPyString(
                    cefDictionaryValue.get().GetString(cefKey))
            originallyString = CheckForCefPythonMessageHash(cefBrowser,
                    originallyString)
            ret[pyKey] = originallyString
        elif valueType == cef_types.VTYPE_DICTIONARY:
            ret[pyKey] = CefDictionaryValueToPyDict(
                    cefBrowser,
                    cefDictionaryValue.get().GetDictionary(cefKey),
                    nestingLevel + 1)
        elif valueType == cef_types.VTYPE_LIST:
            ret[pyKey] = CefListValueToPyList(
                    cefBrowser,
                    cefDictionaryValue.get().GetList(cefKey),
                    nestingLevel + 1)
        elif valueType == cef_types.VTYPE_BINARY:
            binaryValue = cefDictionaryValue.get().GetBinary(cefKey)
            if binaryValue.get().GetSize() == sizeof(uint32_value):
                binaryValue.get().GetData(
                        &uint32_value, sizeof(uint32_value), 0)
                ret[pyKey] = uint32_value
            elif binaryValue.get().GetSize() == sizeof(int64_value):
                binaryValue.get().GetData(
                        &int64_value, sizeof(int64_value), 0)
                ret[pyKey] = int64_value
            else:
                raise Exception("Unknown binary value, size=%s" % \
                        binaryValue.get().GetSize())
        else:
            raise Exception("Unknown value type = %s" % valueType)
    return ret

# -----------------------------------------------------------------------------
# Python values to CEF values
# -----------------------------------------------------------------------------

cdef CefRefPtr[CefListValue] PyListToCefListValue(
        int browserId,
        object frameId,
        list pyList,
        int nestingLevel=0) except *:
    if nestingLevel > 8:
        raise Exception("PyListToCefListValue(): max nesting level (8)"
                " exceeded")
    cdef type valueType
    cdef CefRefPtr[CefListValue] ret = CefListValue_Create()
    cdef CefRefPtr[CefBinaryValue] binaryValue
    for index, value in enumerate(pyList):
        valueType = type(value)
        if valueType == type(None):
            ret.get().SetNull(index)
        elif valueType == bool:
            ret.get().SetBool(index, bool(value))
        elif valueType == int:
            ret.get().SetInt(index, int(value))
        elif valueType == long:
            # Int32 range is -2147483648..2147483647, we've increased the
            # minimum size by one as Cython was throwing a warning:
            # "unary minus operator applied to unsigned type, result still
            # unsigned".
            if value <= 2147483647 and value >= -2147483647:
                ret.get().SetInt(index, int(value))
            else:
                # Long values become strings.
                ret.get().SetString(index, PyToCefStringValue(str(value)))
        elif valueType == float:
            ret.get().SetDouble(index, float(value))
        elif valueType == bytes or valueType == str \
                or (PY_MAJOR_VERSION < 3 and valueType == unicode):
            # The unicode type is not defined in Python 3.
            ret.get().SetString(index, PyToCefStringValue(str(value)))
        elif valueType == dict:
            ret.get().SetDictionary(index, PyDictToCefDictionaryValue(
                    browserId, frameId, value, nestingLevel + 1))
        elif valueType == list or valueType == tuple:
            if valueType == tuple:
                value = list(value)
            ret.get().SetList(index, PyListToCefListValue(
                    browserId, frameId, value, nestingLevel + 1))
        elif valueType == types.FunctionType or valueType == types.MethodType:
            ret.get().SetBinary(index, PutPythonCallback(
                    browserId, frameId, value))
        else:
            # Raising an exception probably not a good idea, why
            # terminate application when we can cast it to string,
            # the data may contain some non-standard object that is
            # probably redundant, but casting to string will do no harm.
            # This will handle the "type" type.
            ret.get().SetString(index, PyToCefStringValue(str(value)))
    return ret

cdef void PyListToExistingCefListValue(
        int browserId,
        object frameId,
        list pyList,
        CefRefPtr[CefListValue] cefListValue,
        int nestingLevel=0) except *:
    # When sending process messages you must use an existing
    # CefListValue, see browser.pyx > SendProcessMessage().
    if nestingLevel > 8:
        raise Exception("PyListToCefListValue(): max nesting level (8)"
                " exceeded")
    cdef type valueType
    cdef CefRefPtr[CefListValue] newCefListValue
    for index, value in enumerate(pyList):
        valueType = type(value)
        if valueType == type(None):
            cefListValue.get().SetNull(index)
        elif valueType == bool:
            cefListValue.get().SetBool(index, bool(value))
        elif valueType == int:
            cefListValue.get().SetInt(index, int(value))
        elif valueType == long:
            # Int32 range is -2147483648..2147483647, we've increased the
            # minimum size by one as Cython was throwing a warning:
            # "unary minus operator applied to unsigned type, result still
            # unsigned".
            if value <= 2147483647 and value >= -2147483647:
                cefListValue.get().SetInt(index, int(value))
            else:
                # Long values become strings.
                cefListValue.get().SetString(index, PyToCefStringValue(str(
                        value)))
        elif valueType == float:
            cefListValue.get().SetDouble(index, float(value))
        elif valueType == bytes or valueType == str \
                or (PY_MAJOR_VERSION < 3 and valueType == unicode):
            # The unicode type is not defined in Python 3.
            cefListValue.get().SetString(index, PyToCefStringValue(str(value)))
        elif valueType == dict:
            cefListValue.get().SetDictionary(index, PyDictToCefDictionaryValue(
                    browserId, frameId, value, nestingLevel + 1))
        elif valueType == list or valueType == tuple:
            if valueType == tuple:
                value = list(value)
            newCefListValue = CefListValue_Create()
            PyListToExistingCefListValue(browserId, frameId, value,
                    newCefListValue, nestingLevel + 1)
            cefListValue.get().SetList(index, newCefListValue)
        elif valueType == types.FunctionType or valueType == types.MethodType:
            cefListValue.get().SetBinary(index, PutPythonCallback(
                        browserId, frameId, value))
        else:
            # Raising an exception probably not a good idea, why
            # terminate application when we can cast it to string,
            # the data may contain some non-standard object that is
            # probably redundant, but casting to string will do no harm.
            # This will handle the "type" type.
            cefListValue.get().SetString(index, PyToCefStringValue(str(value)))

cdef CefRefPtr[CefDictionaryValue] PyDictToCefDictionaryValue(
        int browserId,
        object frameId,
        dict pyDict,
        int nestingLevel=0) except *:
    if nestingLevel > 8:
        raise Exception("PyDictToCefDictionaryValue(): max nesting level (8)"
                " exceeded")
    cdef type valueType
    cdef CefRefPtr[CefDictionaryValue] ret = CefDictionaryValue_Create()
    cdef CefString cefKey
    cdef object value
    for pyKey in pyDict:
        value = pyDict[pyKey]
        valueType = type(value)
        PyToCefString(pyKey, cefKey)
        if valueType == type(None):
            ret.get().SetNull(cefKey)
        elif valueType == bool:
            ret.get().SetBool(cefKey, bool(value))
        elif valueType == int:
            ret.get().SetInt(cefKey, int(value))
        elif valueType == long:
            # Int32 range is -2147483648..2147483647, we've increased the
            # minimum size by one as Cython was throwing a warning:
            # "unary minus operator applied to unsigned type, result still
            # unsigned".
            if value <= 2147483647 and value >= -2147483647:
                ret.get().SetInt(cefKey, int(value))
            else:
                # Long values become strings.
                ret.get().SetString(cefKey, PyToCefStringValue(str(value)))
        elif valueType == float:
            ret.get().SetDouble(cefKey, float(value))
        elif valueType == bytes or valueType == str \
                or (PY_MAJOR_VERSION < 3 and valueType == unicode):
            # The unicode type is not defined in Python 3.
            ret.get().SetString(cefKey, PyToCefStringValue(str(value)))
        elif valueType == dict:
            ret.get().SetDictionary(cefKey, PyDictToCefDictionaryValue(
                    browserId, frameId, value, nestingLevel + 1))
        elif valueType == list or valueType == tuple:
            if valueType == tuple:
                value = list(value)
            ret.get().SetList(cefKey, PyListToCefListValue(
                    browserId, frameId, value, nestingLevel + 1))
        elif valueType == types.FunctionType or valueType == types.MethodType:
            ret.get().SetBinary(cefKey, PutPythonCallback(
                    browserId, frameId, value))
        else:
            # Raising an exception probably not a good idea, why
            # terminate application when we can cast it to string,
            # the data may contain some non-standard object that is
            # probably redundant, but casting to string will do no harm.
            # This will handle the "type" type.
            ret.get().SetString(cefKey, PyToCefStringValue(str(value)))
    return ret
