/*
 * Generated by dtrace(1M).
 */

#ifndef	_RACCOMPOUNDDISPOSABLEPROVIDER_H
#define	_RACCOMPOUNDDISPOSABLEPROVIDER_H

#include <unistd.h>

#ifdef	__cplusplus
extern "C" {
#endif

#define RACCOMPOUNDDISPOSABLE_STABILITY "___dtrace_stability$RACCompoundDisposable$v1$1_1_0_1_1_0_1_1_0_1_1_0_1_1_0"

#define RACCOMPOUNDDISPOSABLE_TYPEDEFS "___dtrace_typedefs$RACCompoundDisposable$v2"

#if !defined(DTRACE_PROBES_DISABLED) || !DTRACE_PROBES_DISABLED

#define	RACCOMPOUNDDISPOSABLE_ADDED(arg0, arg1, arg2) \
do { \
	__asm__ volatile(".reference " RACCOMPOUNDDISPOSABLE_TYPEDEFS); \
	__dtrace_probe$RACCompoundDisposable$added$v1$63686172202a$63686172202a$6c6f6e67(arg0, arg1, arg2); \
	__asm__ volatile(".reference " RACCOMPOUNDDISPOSABLE_STABILITY); \
} while (0)
#define	RACCOMPOUNDDISPOSABLE_ADDED_ENABLED() \
	({ int _r = __dtrace_isenabled$RACCompoundDisposable$added$v1(); \
		__asm__ volatile(""); \
		_r; })
#define	RACCOMPOUNDDISPOSABLE_REMOVED(arg0, arg1, arg2) \
do { \
	__asm__ volatile(".reference " RACCOMPOUNDDISPOSABLE_TYPEDEFS); \
	__dtrace_probe$RACCompoundDisposable$removed$v1$63686172202a$63686172202a$6c6f6e67(arg0, arg1, arg2); \
	__asm__ volatile(".reference " RACCOMPOUNDDISPOSABLE_STABILITY); \
} while (0)
#define	RACCOMPOUNDDISPOSABLE_REMOVED_ENABLED() \
	({ int _r = __dtrace_isenabled$RACCompoundDisposable$removed$v1(); \
		__asm__ volatile(""); \
		_r; })


extern void __dtrace_probe$RACCompoundDisposable$added$v1$63686172202a$63686172202a$6c6f6e67(const char *, const char *, long);
extern int __dtrace_isenabled$RACCompoundDisposable$added$v1(void);
extern void __dtrace_probe$RACCompoundDisposable$removed$v1$63686172202a$63686172202a$6c6f6e67(const char *, const char *, long);
extern int __dtrace_isenabled$RACCompoundDisposable$removed$v1(void);

#else

#define	RACCOMPOUNDDISPOSABLE_ADDED(arg0, arg1, arg2) \
do { \
	} while (0)
#define	RACCOMPOUNDDISPOSABLE_ADDED_ENABLED() (0)
#define	RACCOMPOUNDDISPOSABLE_REMOVED(arg0, arg1, arg2) \
do { \
	} while (0)
#define	RACCOMPOUNDDISPOSABLE_REMOVED_ENABLED() (0)

#endif /* !defined(DTRACE_PROBES_DISABLED) || !DTRACE_PROBES_DISABLED */


#ifdef	__cplusplus
}
#endif

#endif	/* _RACCOMPOUNDDISPOSABLEPROVIDER_H */
