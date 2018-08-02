#ifndef ERROR_H
#define ERROR_H

#ifdef __cplusplus
extern "C" {
#endif

void     err_dump(const char *, ...);
void     err_msg(const char *, ...);
void     err_quit(const char *, ...);
void     err_ret(const char *, ...);
void     err_sys(const char *, ...);


#ifdef __cplusplus
}
#endif

#endif  /* ERROR_H */
