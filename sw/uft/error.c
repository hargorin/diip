/*
* @Author: Noah Huetter
* @Date:   2018-03-21 11:50:26
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2018-03-21 12:08:30
*/
/**
 * Defines error functions. Source: http://unpbook.com/src.html
 */

#include "uft.h"

#include    <stdarg.h>      /* ANSI C header file */
#include    <syslog.h>      /* for syslog() */

#define MAXLINE     4096    /* max text line length */

int     daemon_proc = 0;        /* set nonzero by daemon_init() */

static void err_doit(int, int, const char *, va_list);

/**
 * @brief      Fatal error related to system call
 * Print mesage, dump core and terminate
 *
 * @param[in]  fmt        The format
 * @param[in]  <unnamed>  var args
 */
void err_dump(const char *fmt, ...)
{
    va_list     ap;

    va_start(ap, fmt);
    err_doit(1, LOG_ERR, fmt, ap);
    va_end(ap);
    abort();        /* dump core and terminate */
    exit(1);        /* shouldn't get here */
}

/**
 * @brief      Nonfatal error unrelated to system call
 * Print message and return
 *
 * @param[in]  fmt        The format
 * @param[in]  <unnamed>  { parameter_description }
 */
void err_msg(const char *fmt, ...)
{
    va_list     ap;

    va_start(ap, fmt);
    err_doit(0, LOG_INFO, fmt, ap);
    va_end(ap);
    return;
}

/**
 * @brief      Fatal error unrelated to system call
 * Print message and terminate
 *
 * @param[in]  fmt        The format
 * @param[in]  <unnamed>  { parameter_description }
 */
void err_quit(const char *fmt, ...)
{
    va_list     ap;

    va_start(ap, fmt);
    err_doit(0, LOG_ERR, fmt, ap);
    va_end(ap);
    exit(1);
}

/**
 * @brief      Nonfatal error related to system call
 * Print message and return
 *
 * @param[in]  fmt        The format
 * @param[in]  <unnamed>  { parameter_description }
 */
void err_ret(const char *fmt, ...)
{
    va_list     ap;

    va_start(ap, fmt);
    err_doit(1, LOG_INFO, fmt, ap);
    va_end(ap);
    return;
}

/**
 * @brief      Fatal error related to sys call
 * Print message and terminate
 *
 * @param[in]  fmt        The format
 * @param[in]  <unnamed>  var args
 */
void err_sys(const char *fmt, ...)
{
    va_list     ap;

    va_start(ap, fmt);
    err_doit(1, LOG_ERR, fmt, ap);
    va_end(ap);
    exit(1);
}

/**
 * @brief      Print message and return to caller. Caller specifies errnoflag
 * and level
 *
 * @param[in]  errnoflag  The errnoflag
 * @param[in]  level      The level
 * @param[in]  fmt        The format string
 * @param[in]  ap         variable arguments list
 */
static void err_doit(int errnoflag, int level, const char *fmt, va_list ap)
{
    int     errno_save, n;
    char    buf[MAXLINE + 1];

    errno_save = errno;     /* value caller might want printed */
    vsnprintf(buf, MAXLINE, fmt, ap);   /* safe */
    n = strlen(buf);
    if (errnoflag)
    {
        snprintf(buf + n, MAXLINE - n, ": %s", strerror(errno_save));
    }
    strcat(buf, "\n");

    if (daemon_proc) 
    {
        syslog(level, "%s", buf);
    } 
    else 
    {
        fflush(stdout);     /* in case stdout and stderr are the same */
        fputs(buf, stderr);
        fflush(stderr);
    }
    return;
}