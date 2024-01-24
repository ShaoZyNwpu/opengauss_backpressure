/* -------------------------------------------------------------------------
 *
 *	  ISO8859_1 <--> UTF8
 *
 * Portions Copyright (c) 1996-2012, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/backend/utils/mb/conversion_procs/utf8_and_iso8859_1/utf8_and_iso8859_1.c
 *
 * -------------------------------------------------------------------------
 */

#include "postgres.h"
#include "knl/knl_variable.h"
#include "fmgr.h"
#include "mb/pg_wchar.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(iso8859_1_to_utf8);
PG_FUNCTION_INFO_V1(utf8_to_iso8859_1);

extern "C" Datum iso8859_1_to_utf8(PG_FUNCTION_ARGS);
extern "C" Datum utf8_to_iso8859_1(PG_FUNCTION_ARGS);

/* ----------
 * conv_proc(
 *		INTEGER,	-- source encoding id
 *		INTEGER,	-- destination encoding id
 *		CSTRING,	-- source string (null terminated C string)
 *		CSTRING,	-- destination string (null terminated C string)
 *		INTEGER		-- source string length
 * ) returns VOID;
 * ----------
 */
Datum iso8859_1_to_utf8(PG_FUNCTION_ARGS)
{
    unsigned char* src = (unsigned char*)PG_GETARG_CSTRING(2);
    unsigned char* dest = (unsigned char*)PG_GETARG_CSTRING(3);
    int len = PG_GETARG_INT32(4);
    unsigned short c;

    bool bulkload_illegal_chars_conversion = false;

    if (u_sess->cmd_cxt.bulkload_compatible_illegal_chars) {
        bulkload_illegal_chars_conversion = true;
    }

    CHECK_ENCODING_CONVERSION_ARGS(PG_LATIN1, PG_UTF8);

    while (len > 0) {
        c = *src;
        if (c == 0) {
            if (bulkload_illegal_chars_conversion) {
                /*
                 * use ' ' as conversion.
                 */
                *dest++ = ' ';
                src++;
                len--;
                continue;
            } else {
                report_invalid_encoding(PG_LATIN1, (const char*)src, len);
            }
        }
        if (!IS_HIGHBIT_SET(c))
            *dest++ = c;
        else {
            *dest++ = (c >> 6) | 0xc0;
            *dest++ = (c & 0x003f) | HIGHBIT;
        }
        src++;
        len--;
    }
    *dest = '\0';

    PG_RETURN_VOID();
}

Datum utf8_to_iso8859_1(PG_FUNCTION_ARGS)
{
    unsigned char* src = (unsigned char*)PG_GETARG_CSTRING(2);
    unsigned char* dest = (unsigned char*)PG_GETARG_CSTRING(3);
    int len = PG_GETARG_INT32(4);
    unsigned short c, c1;
    int l;

    bool bulkload_illegal_chars_conversion = false;

    if (u_sess->cmd_cxt.bulkload_compatible_illegal_chars) {
        bulkload_illegal_chars_conversion = true;
    }

    CHECK_ENCODING_CONVERSION_ARGS(PG_UTF8, PG_LATIN1);

    while (len > 0) {
        c = *src;
        if (c == 0) {
            if (bulkload_illegal_chars_conversion) {
                /*
                 * use ' ' as conversion.
                 */
                *dest++ = ' ';
                src++;
                len--;
                continue;
            } else {
                report_invalid_encoding(PG_UTF8, (const char*)src, len);
            }
        }
        /* fast path for ASCII-subset characters */
        if (!IS_HIGHBIT_SET(c)) {
            *dest++ = c;
            src++;
            len--;
        } else {
            l = pg_utf_mblen(src);
            if (l > len || !pg_utf8_islegal(src, l)) {
                if (bulkload_illegal_chars_conversion) {
                    /*
                     * use '?' as conversion.
                     */
                    *dest++ = '?';
                    src++;
                    len--;
                    continue;
                } else {
                    report_invalid_encoding(PG_UTF8, (const char*)src, len);
                }
            }
            if (l != 2) {
                if (bulkload_illegal_chars_conversion) {
                    /*
                     * use '?' as conversion.
                     */
                    *dest++ = '?';
                    src += l;
                    len -= l;
                    continue;
                } else {
                    report_untranslatable_char(PG_UTF8, PG_LATIN1, (const char*)src, len);
                }
            }
            c1 = src[1] & 0x3f;
            c = ((c & 0x1f) << 6) | c1;
            if (c >= 0x80 && c <= 0xff) {
                *dest++ = (unsigned char)c;
                src += 2;
                len -= 2;
            } else {
                if (bulkload_illegal_chars_conversion) {
                    /*
                     * use '?' as conversion.
                     */
                    *dest++ = '?';
                    src += 2;
                    len -= 2;
                    continue;
                } else {
                    report_untranslatable_char(PG_UTF8, PG_LATIN1, (const char*)src, len);
                }
            }
        }
    }
    *dest = '\0';

    PG_RETURN_VOID();
}

