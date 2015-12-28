//--------------------------------------------------------------------------------------------------
// (c)2015 Meecaa Corporation. All rights reserved.
// Author: Hank Yue
// 2015.10.21

#ifndef __DECODER_DEF_H__
#define __DECODER_DEF_H__

#define FS  44100
#define RECORD_BUF_SIZE 32768
#define MSG_BUF_SIZE 16

#define CANNOT_FIND_START_SYMBOL_ERR    1
#define START_SYMBOL_NOT_ZERO_ERR       2
#define STOP_SYMBOL_NOT_ONE_ERR         3
#define PARITY_ERR                      4
#define CHECKSUM_ERR                    5
#define FOURTH_BYTE_ERR                 6
#define INFO_NOT_COMPLETED_ERR          7

typedef int   INT32;
typedef short int   INT16;



// Mask this line to prevent GCC compile warning
//#define NULL				0

#define SAFE_DELETE(p)       {if (p) {delete   (p); (p) = NULL;}}
#define SAFE_DELETE_ARRAY(p) {if (p) {delete[] (p); (p) = NULL;}}

#endif
