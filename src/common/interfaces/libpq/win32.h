/*
 * Portions Copyright (c) 2020 Huawei Technologies Co.,Ltd.
 * Portions Copyright (c) 2012, PostgreSQL Global Development Group
 * src/common/interfaces/libpq/win32.h
 */
#ifndef __win32_h_included
#define __win32_h_included

/*
 * Some compatibility functions
 */
#ifdef __BORLANDC__
#define _timeb timeb
#define _ftime(a) ftime(a)
#define _errno errno
#define popen(a, b) _popen(a, b)
#else
/* open provided elsewhere */
#define close(a) _close(a)
#define read(a, b, c) _read(a, b, c)
#define write(a, b, c) _write(a, b, c)
#endif

#undef EAGAIN /* doesn't apply on sockets */
#undef EINTR
#define EINTR WSAEINTR
#ifndef EWOULDBLOCK
#define EWOULDBLOCK WSAEWOULDBLOCK
#endif
#ifndef ECONNRESET
#define ECONNRESET WSAECONNRESET
#endif
#ifndef EINPROGRESS
#define EINPROGRESS WSAEINPROGRESS
#endif
#ifndef ETIMEDOUT
#define ETIMEDOUT WSAETIMEDOUT
#endif

#ifdef WIN32
#define unsetenv(x) pgwin32_unsetenv(x)
#endif

/*
 * support for handling Windows Socket errors
 */
extern const char* winsock_strerror(int err, char* strerrbuf, size_t buflen);

#endif
