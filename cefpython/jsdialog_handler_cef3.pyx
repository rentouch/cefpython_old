# Copyright (c) 2012-2013 The CEF Python authors. All rights reserved.
# License: New BSD License.
# Website: http://code.google.com/p/cefpython/


# -----------------------------------------------------------------------------
# PyJSDialogCallback
# -----------------------------------------------------------------------------
cdef PyJSDialogCallback CreatePyJSDialogCallback(
        CefRefPtr[CefJSDialogCallback] cefCallback):
    cdef PyJSDialogCallback pyCallback = PyAuthCallback()
    pyCallback.cefCallback = cefCallback
    return pyCallback

cdef class PyJSDialogCallback:
    cdef CefRefPtr[CefJSDialogCallback] cefCallback

    cpdef py_void Continue(self, py_bool allow, py_string user_input):
        self.cefCallback.get().Continue(bool(allow),
                                        PyToCefStringValue(user_input))


# -----------------------------------------------------------------------------
# JSDialogHandler
# -----------------------------------------------------------------------------
cdef public cpp_bool CefJSDialogHandler_OnJSDialog(
        CefRefPtr[CefBrowser] cefBrowser,
        const CefString& origin_url,
        const CefString& accept_lang,
        cef_types.cef_jsdialog_type_t dialog_type,
        const CefString& message_text,
        const CefString& default_prompt_text,
        CefRefPtr[CefJSDialogCallback] callback,
        cpp_bool& suppress_message
        ) except * with gil:
    cdef PyBrowser pyBrowser
    cdef py_string pyOriginUrl
    cdef py_string pyAcceptLang
    cdef py_string pyMessageText
    cdef py_string pyDefaultPromptText
    ## XXX pyCallback
    cdef PyJSDialogCallback pyCallback
    cdef list pySuppressMessage = []
    
    cdef object clientCallback
    cdef py_bool returnValue
    try:
        pyBrowser = GetPyBrowser(cefBrowser)
        pyOriginUrl = CefToPyString(origin_url)
        pyAcceptLang = CefToPyString(accept_lang)
        pyMessageText = CefToPyString(message_text)
        pyDefaultPromptText = CefToPyString(default_prompt_text)
        ## pyCallback = XXX(callback)
        pySuppressMessage = [bool(suppress_message)]
        
        clientCallback = pyBrowser.GetClientCallback("OnJSDialog")
        if clientCallback:
            returnValue = clientCallback(pyBrowser, pyOriginUrl, pyAcceptLang,
                    dialog_type, pyMessageText, pyDefaultPromptText, None, pySuppressMessage)
            (&suppress_message)[0] = <cpp_bool>bool(pySuppressMessage[0])
            return returnValue
        return False
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)