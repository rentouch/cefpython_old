# Copyright (c) 2012-2013 The CEF Python authors. All rights reserved.
# License: New BSD License.
# Website: http://code.google.com/p/cefpython/

cdef extern from "client_handler/cookie_visitor.h":
    cdef cppclass CookieVisitor:
        CookieVisitor(int cookieVisitorId)
