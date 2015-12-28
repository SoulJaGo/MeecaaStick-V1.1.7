//
//  lib_decode.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/31.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//
//版本文件名：

#ifndef __HomeKinsa__lib_decode__
#define __HomeKinsa__lib_decode__

#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <assert.h>
//#include <cutils/log.h>
//#include <windows.h>
#include <wchar.h>
#include <string.h>
#include <dlfcn.h>
#define SAMPLE_DATAPOS_LEN_MAX 1024
#define SAMPLE_DATA_LEN_MAX   8//2046
#define SAMPLE_8BIT   0
#define SAMPLE_16BIT  1
#define SAMPLE_BIT_SMALL_MODE  0
#define SAMPLE_BIT_LARGE_MODE  1

#define DATA_POSSIBLE_L 0
#define DATA_POSSIBLE_H 1

#define DATA_IDLE  			0x01
#define DATA_START_BIT 		0x02
#define DATA_DATA_BIT  		0x03
#define DATA_PRAPILY_BIT 	0x04
#define DATA_STOP_BIT    	0x05

#define DATA_BIT_STATUS1  0x01
#define DATA_BIT_STATUS2  0x02
#define DATA_BIT_STATUS3  0x03
#define DATA_BIT_STATUS4  0x04

#define SMART_FLAG_1 0x01
#define SMART_FLAG_0 0x00

#define SMART_DATA_START 0xAA
#define SMART_DATA_END   0x55

#define BYTE_BIT_STATUS1  0x01
#define BYTE_BIT_STATUS2  0x02
#define BYTE_BIT_STATUS3  0x03
#define BYTE_BIT_STATUS4  0x04

#define IDLE_BIT_STATUS1  0x01
#define IDLE_BIT_STATUS2  0x02
#define IDLE_BIT_STATUS3  0x03

#define BYTE_OK             0xA1
#define DATA_OK             0xA2

#define ERROR_START  		0xB1
#define ERROR_BYTE   		0xB2
#define ERROR_PAITY  		0xB3
#define ERROR_STOP   		0xB4
#define ERROR_DEFAULT       0xB5

#define ERROR_START_FLAG    0xC1
#define ERROR_END_FLAG      0xC2

#define ERROR_A2D           0xC3
#define ERROR_SPL           0xC4

#define ERROR_NO_IDLE       0xC5

#define DATA_BUFFER_STAT    0x01
#define DATA_BUFFER_DATA    0x02
#define DATA_BUFFER_END     0x03

#define DEAL_STEUP_1        0x01
#define DEAL_STEUP_2        0x02
#define DEAL_STEUP_3        0x03
#define DEAL_STEUP_4        0x04
#define DEAL_STEUP_5       0x05
#define DEAL_STEUP_6        0x06

#define BUFF_LEN    4
#define DEL_ISTATUS_
typedef struct
{
    unsigned char bit1: 1;
    unsigned char otherbit: 7;
}__BIT;
typedef struct
{
    int ecodefre;  //编码速率 Hz为单位
    int datapossible; //数据极性
    int min_interval_ms;	//最小间隔时间ms为单位
    int  channale;  //采样声道
    //	unsigned char  samplebit;
    //	unsigned char  bitmode;
    unsigned char data[SAMPLE_DATA_LEN_MAX];//数据
    int test_interval_count;//建议周期，按照采样点计算
    int test_half_interval_count;//建议半周期
    int error_band;//周期误差,按照采样点基数按
    int smart_flag;
    short sourcedata[SAMPLE_DATA_LEN_MAX*256 + 2048+1024];//数据
    int   sourcedata_len;
    int dead_value_pos;
    
}VOICE_Struct;
VOICE_Struct voice_class;
short sourcedatapos[SAMPLE_DATAPOS_LEN_MAX];
char  charsourcedatapossbile[SAMPLE_DATA_LEN_MAX*256 + 2048+1024];
char logms[1024];
//void byteToHexStr(unsigned char byte_arr[], int arr_len,char *hexstr);

/*******************************************************************************************
 **函数名:toHexString(const unsigned char* input, const int datasize)
 **功能  :
 **输入参数:
 **返回值  :
 ******************************************************************************************/
static void byteToHexStr2(unsigned char *byte_arr, int arr_len,char *hexstr)
{
    int i;
    char hex1;
    char hex2;
    unsigned char value;
    unsigned char v1;
    unsigned char v2;
    for (i=0;i<arr_len;i++)
    {
        
        value=byte_arr[i];
        v1=(value& 0xF0) >> 4;
        v2=value & 0x0F;
        
        if (v1>=0&&v1<=9)
            hex1=(char)(0x30+v1);
        else
            hex1=(char)(0x37+v1);
        
        
        if (v2>=0&&v2<=9)
            hex2=(char)(0x30+v2);
        else
            hex2=(char)(0x37+v2);
        
        
        hexstr[i << 1] = hex1;
        hexstr[(i << 1)+ 1] = hex2;
        
    }
    
}

/***********************************************************************************************
 **函数名:	mk_AudioFormat(unsigned short sampleFre,,unsigned short voiceFre,unsigned char channale,unsigned char samplebit,unsigned char bitmode,unsigned char smart_flag)
 **功能   : 设置录音文件的初始化值
 **输入参数:
 **返回值  :
 ************************************************************************************************/
static int mk_AudioFormat(int sampleFre,int voiceFre,int channale,int samplebit,int bitmode,int smart_flag,int dead_value)
{
    int i;
    voice_class.min_interval_ms = 1000.00/((double)sampleFre);
    voice_class.channale = channale;
    voice_class.ecodefre = voiceFre;
    voice_class.test_interval_count = (unsigned short)(sampleFre/voiceFre);
    voice_class.test_half_interval_count =(unsigned short) (voice_class.test_interval_count /2);
    voice_class.smart_flag = smart_flag;
    voice_class.error_band = (int)(voice_class.test_interval_count * 0.2);
    voice_class.dead_value_pos = dead_value;
    
    for(i = 0; i<SAMPLE_DATAPOS_LEN_MAX;i++)
    {
        sourcedatapos[i]= -1 ;
    }
    return 1;
}

/*************************************************************************************
 **函数名: mk_analog2digtal(short *psourcedata, char*pdestdata,int len)
 **功能  :将采集到的数据 变成01
 **输入参数:
 **返回值:
 **************************************************************************************/
static int mk_analog2digtal(short *psourcedata, char*pdestdata,int len)
{
    int i;
    int positivebit = 0;
    int nativebit = 0;
    int  nowbitstatus = 0;
    for(i = 0; i< len; i++)
    {
        if(psourcedata[i] > 0){
            pdestdata[i] = 1;
            positivebit++;
            nowbitstatus = 1;
            
        }
     /*   else if(psourcedata[i]== 0){
            if(1 == nowbitstatus){
                if((positivebit >=11) &&())
            }
        }*/
        else{
            pdestdata[i] = 0;
            nativebit++;
            nowbitstatus = 2;
        }
    }
    nowbitstatus = 0;
    return 1;
}

/*************************************************************************************
 **函数名: mk_analog2digtal(short *psourcedata, char*pdestdata,int len)
 **功能  :将采集到的数据 变成01
 **输入参数:
 **返回值:
 **************************************************************************************/
static int mk_analog2digtal2(short *psourcedata, char*pdestdata,int len)
{
    int i;
    int positivebit = 0;
    int nativebit = 0;
    int  nowbitstatus = 0;
    for(i = 0; i< len; i++)
    {
        if(psourcedata[i] >= 0){
            pdestdata[i] = 0;
            positivebit++;
            nowbitstatus = 1;
            
        }
        /*   else if(psourcedata[i]== 0){
         if(1 == nowbitstatus){
         if((positivebit >=11) &&())
         }
         }*/
        else{
            pdestdata[i] = 1;
            nativebit++;
            nowbitstatus = 2;
        }
    }
    nowbitstatus = 0;
    return 1;
}
/***************************************************************************************
 **函数名:
 **功能  :
 **输入参数:
 **返回值:
 **************************************************************************************/
static int data_deal(short *psourcedata,int len)
{
    short tempshort;
    for(int i=1;i<(len-1);i++)
    {
       
        tempshort= (short)((psourcedata[i]+psourcedata[i-1] + psourcedata[i+1])/3);
        psourcedata[i] = tempshort;
    }
    return 1;
}
/**************************************************************************************
 **函数名:
 **功能  :
 **输入参数:
 **返回中:
 ***********************************************************************************/
 static short mk_FindmaxValue(short * psourcedta,int len)
{
    short max_value1 = psourcedta[0];
    short max_value2 = psourcedta[0];
    short max_value3 = psourcedta[0];
    short res = 0;
    for(int i=0;i< len;i++){
        if(max_value1 > abs(psourcedta[i])){
            max_value3 = max_value2;
            max_value2 = max_value1;
            max_value1 = abs(psourcedta[i]);
        }
    }
        res = (short)(((max_value1/3.0) + (max_value2/3.0) + (max_value3/3.0))*0.2);
    return res;
}

/*************************************************************************************
 **函数名: mk_analog2digtal(short *psourcedata, char*pdestdata,int len)
 **功能  :将采集到的数据 变成01
 **输入参数:
 **返回值:
 **************************************************************************************/
static int mk_analog2digtal1(short *psourcedata, char*pdestdata,int len)
{
    int i;
    int positivebit = 0;
    int nativebit = 0;
    int  nowbitstatus = 0;
    short tempvalue = mk_FindmaxValue(psourcedata,len);
    short natempvalue = 0 - tempvalue;
    int j = 0;
    for(i = 0; i< len; i++)
    {
        if(psourcedata[i] >= tempvalue){
            pdestdata[j] = 1;
            positivebit++;
            nowbitstatus = 1;
            j++;
            
        }
        /*   else if(psourcedata[i]== 0){
         if(1 == nowbitstatus){
         if((positivebit >=11) &&())
         }
         }*/
        else if(psourcedata[i] <= natempvalue){
            pdestdata[j] = 0;
            nativebit++;
            nowbitstatus = 2;
            j++;
        }
    }
    nowbitstatus = 0;
    return j;
}


/*************************************************************************************
 **函数名: mk_Splitdata(char*pdata,int len)
 **功能  :  2015.2.6 拆分 模拟出高低电平
 **输入参数:
 **返回值:
 *************************************************************************************/
static int mk_Splitdata(char*pdata,int len)
{
    int startpos = 0;
    int lastpos = 0;
    int nowpos = 0;
    char startdata;
    int temppos = 0;
    startpos = 0;
    lastpos = len -1;
    
    startdata = pdata[0];
    nowpos = startpos=0;
    sourcedatapos[temppos] = nowpos;
    /*	if((nowpos < lastpos)&&(pdata[nowpos] ==pdata[nowpos + 1]))
     {
     temppos++;
     sourcedatapos[temppos] = nowpos;
     startdata = pdata[nowpos];
					
     }else if((nowpos == 0) || (nowpos == lastpos))
     {
     temppos++;
     sourcedatapos[temppos] = nowpos;
     startdata = pdata[nowpos];
     }
     */
    /*查找第一个跳跃点*/
    while(nowpos <= lastpos)
    {
        if(startdata !=pdata[nowpos])
        {
            
            temppos++;
            sourcedatapos[temppos] = nowpos;
            startdata = pdata[nowpos];
            
        }
        
        nowpos++;
    }
    return 1;
    /*
     while(nowpos <= (lastpos - (voice_class.test_half_interval_count+ voice_class.error_band)))
     {
     if(startdata != pdata[nowpos + voice_class.test_half_interval_count+ voice_class.error_band])
     {
     if(startdata != pdata[nowpos + voice_class.test_half_interval_count- voice_class.error_band]))
			 	{
     //  认为是毛刺,清空当前标志
     
     sourcedatapos[temppos] = 0;
     temppos--;
			 	}
     }
     }*/
}

/*******************************************************************************************
 **函数名:mk_deletfirstper()
 **功能  : 这个函数主要是处理数字化后的1 和相应的跳跃点 因为存在的问题是在空闲周期内第一个周期高电平太高容易误判
 在后续处理中 我们用查找空闲波的方式代替了这个函数 目前不用
 ** 输入参数:
 **返回值 :
 ****************************************************************************************/
static int mk_deletfirstper()
{
    int temp;
    int i;
    int j;
    temp = sourcedatapos[2];
    int len = SAMPLE_DATA_LEN_MAX*265 + 256;
    for(i = 0; i< temp;i++)
    {
        for(j =0; j<len;j++)
            charsourcedatapossbile[j] = charsourcedatapossbile[j+1];
    }
    return 1;
}
/***************************************************************************************
 **函数名:  mk_Getpossible(int pos)
 **功能  :  获取当前电平
 **输入参数:
 **返回值  :
 ***************************************************************************************/
static int mk_Getpossible(int pos)
{
    int res;
    res = charsourcedatapossbile[sourcedatapos[pos]-2];
    return res;
}
/****

/********************************************************************************************
 **函数名:
 **功能  :检查起始位置 数据的格式 1 startbit  + 8 databit + 1 paritybit + 1 stopbit
 **输入参数:
 **返回值:
 ****************************************************************************************/
static int mk_Startbit(short *pposdata,int *pos)
{
    int i;
    i = *pos;
    while((pposdata[i]!= -1) && (i < SAMPLE_DATAPOS_LEN_MAX))
    {
        /*毛刺*/
        if((pposdata[i+1] - pposdata[i]) <=voice_class.error_band)
        {
            i++;
        }
        /*短半周期 非起始位*/
        
        else if(((pposdata[i+1] - pposdata[i]) >=(voice_class.test_half_interval_count - voice_class.error_band))
                &&((pposdata[i+1] - pposdata[i]) <(voice_class.test_interval_count - voice_class.error_band)))
        {
            i++;
        }
        /*长周期 起始位*/
        else if((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band))
            
            //else if(((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band))
            //	 &&((pposdata[i+1] - pposdata[i]) <(voice_class.test_interval_count + voice_class.error_band + 2)))
        {
            i++;
         //   if(1 == mk_Getpossible(i))
          //  {
            *pos =i;
            //printf("JNIMSG_byte__find the startbitposiii: %d\n",i);
            return 1;
          //  }else
          //  {
          //      return 0;
          //  }
         // return 0;
            
        }
    }
    return 0;
}

/***************************************************************************************
 **函数名:  mk_Getpossible(int pos)
 **功能  :  获取当前电平
 **输入参数:
 **返回值  :
 ***************************************************************************************/
/*static int mk_Getpossible(int pos)
{
    int res;
    res = charsourcedatapossbile[sourcedatapos[pos]-2];
    return res;
}*/

/***************************************************************************************
 **函数名:
 **功能  :
 **输入参数:
 **返回值 :
 ****************************************************************************************/
static int mk_Getbytebit(char *psourcedata,short *pposdata,int *pos,int temppossible ,unsigned char *bytebit)
{
    int i;
    int num;
    unsigned char istatus;
    i = *pos;
    istatus = BYTE_BIT_STATUS1;
    num = 3;
    /*在找到起始位置后 按照正常方式连续找即可，不需要在整个数组里面查找*/
    //else if(((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band))
    //&&((pposdata[i+1] - pposdata[i]) <(voice_class.test_interval_count + voice_class.error_band + 2)))
    
    while(num > 0){
        num --;
        /*先判断周期，再判断电平*/
        //if(temppossible)//正常方式
        //{
        switch(istatus){
            case BYTE_BIT_STATUS1:{
                /*短半周期*/
                if(((pposdata[i+1] - pposdata[i]) >=(voice_class.test_half_interval_count - voice_class.error_band))
              //  &&((pposdata[i+1] - pposdata[i]) < (voice_class.test_interval_count - voice_class.error_band)))
                   &&((pposdata[i+1] - pposdata[i]) <=(voice_class.test_half_interval_count + voice_class.error_band)))
                    
                {
                    
                    istatus = BYTE_BIT_STATUS2;
                }//else if((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band -1))
                else if((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band))
                    
                {
                    i = i + 1;
                    istatus = BYTE_BIT_STATUS4;
                }
                
            }break;
            case BYTE_BIT_STATUS2:{ //短周期进入
                if(((pposdata[i+2] - pposdata[i+1]) >=(voice_class.test_half_interval_count - voice_class.error_band))
                  /* &&((pposdata[i+2] - pposdata[i+1]) <= (voice_class.test_interval_count - voice_class.error_band))*/)
                    
                    
                {
                    i = i+ 2;
                    //printf("JNIMSG_body__just bit+3\n");
                    
                    istatus = BYTE_BIT_STATUS3;
                }else
                {
                    return 0;
                }
            }break;
            case BYTE_BIT_STATUS3:{ //短周期解码
                /*确定是 0或者1*/
                if(0 == psourcedata[pposdata[i-1] -voice_class.error_band])
                {
                    if(1 == psourcedata[pposdata[i]-voice_class.error_band])
                    {
                        *pos = i;
                        if(temppossible)*bytebit = 0;//正常方式
                        else *bytebit = 0x80;
                        return 1;
                    }else
                    {
                        return 0;
                    }
                    
                }else if(1 == psourcedata[pposdata[i-1] -voice_class.error_band])
                {
                    if(0 == psourcedata[pposdata[i]-voice_class.error_band])
                    {
                        *pos = i;
                        if(temppossible)*bytebit = 0x80;//正常方式
                        else *bytebit = 0;
                        
                        return 1;
                    }else
                    {
                        return 0;
                    }
                }
                
            }break;
            case BYTE_BIT_STATUS4:{//长周期解码
                //printf("JNIMSG_body__long per mode\n");
                if(0 == psourcedata[pposdata[i] -voice_class.error_band])
                {
                    *pos = i;
                    if(temppossible)*bytebit = 0x80;//正常方式
                    else *bytebit = 0;
                    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_body", "BYTEBIT:%d\n",*bytebit);
                    //printf("JNIMSG_body_1 _BYTEBIT:%d\n",*bytebit);
                    return 1;
                }else if(1 == psourcedata[pposdata[i] -voice_class.error_band])
                {
                    *pos = i;
                    if(temppossible)*bytebit = 0;//正常方式
                    else *bytebit = 0x80;
                    //printf("JNIMSG_body_2 _BYTEBIT:%d\n",*bytebit);
                    return 1;
                }else
                {
                    return 0;
                }
            }
            default: break; 
                
        }	
        
        
        //}
    }
    return 0;
}
/***************************************************************************************
 **函数名:
 **功能  :
 **输入参数:
 **返回值 :
 ****************************************************************************************/
static int mk_Getbytebit_check(char *psourcedata,short *pposdata,int *pos,int temppossible ,unsigned char *bytebit)
{
    int i;
    int num;
    unsigned char istatus;
    i = *pos;
    istatus = BYTE_BIT_STATUS1;
    num = 3;
    /*在找到起始位置后 按照正常方式连续找即可，不需要在整个数组里面查找*/
    //else if(((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band))
    //&&((pposdata[i+1] - pposdata[i]) <(voice_class.test_interval_count + voice_class.error_band + 2)))
    
    while(num > 0){
        num --;
        /*先判断周期，再判断电平*/
        //if(temppossible)//正常方式
        //{
        switch(istatus){
            case BYTE_BIT_STATUS1:{
                /*短半周期*/
                if(((pposdata[i+1] - pposdata[i]) >=(voice_class.test_half_interval_count - voice_class.error_band))
               //      &&((pposdata[i+1] - pposdata[i]) < (voice_class.test_interval_count - voice_class.error_band)))
                   &&((pposdata[i+1] - pposdata[i]) <=(voice_class.test_half_interval_count + voice_class.error_band)))
                    
                {
                    
                    istatus = BYTE_BIT_STATUS2;
                }//else if((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band -1))
                else if((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band))
                    
                {
                    i = i + 1;
                    istatus = BYTE_BIT_STATUS4;
                }
                
            }break;
            case BYTE_BIT_STATUS2:{ //短周期进入
                if(((pposdata[i+2] - pposdata[i+1]) >=(voice_class.test_half_interval_count - voice_class.error_band))
                    &&((pposdata[i+2] - pposdata[i+1]) <= (voice_class.test_interval_count - voice_class.error_band)))
                    
                    
                {
                    i = i+ 2;
                    //printf("JNIMSG_body__just bit+3\n");
                    
                    istatus = BYTE_BIT_STATUS3;
                }else
                {
                    return 0;
                }
            }break;
            case BYTE_BIT_STATUS3:{ //短周期解码
                /*确定是 0或者1*/
                if(0 == psourcedata[pposdata[i-1] -voice_class.error_band])
                {
                    if(1 == psourcedata[pposdata[i]-voice_class.error_band])
                    {
                        *pos = i;
                        if(temppossible)*bytebit = 0;//正常方式
                        else *bytebit = 0x80;
                        return 1;
                    }else
                    {
                        return 0;
                    }
                    
                }else if(1 == psourcedata[pposdata[i-1] -voice_class.error_band])
                {
                    if(0 == psourcedata[pposdata[i]-voice_class.error_band])
                    {
                        *pos = i;
                        if(temppossible)*bytebit = 0x80;//正常方式
                        else *bytebit = 0;
                        
                        return 1;
                    }else
                    {
                        return 0;
                    }
                }
                
            }break;
            case BYTE_BIT_STATUS4:{//长周期解码
                //printf("JNIMSG_body__long per mode\n");
                if(0 == psourcedata[pposdata[i] -voice_class.error_band])
                {
                    *pos = i;
                    if(temppossible)*bytebit = 0x80;//正常方式
                    else *bytebit = 0;
                    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_body", "BYTEBIT:%d\n",*bytebit);
                    //printf("JNIMSG_body_1 _BYTEBIT:%d\n",*bytebit);
                    return 1;
                }else if(1 == psourcedata[pposdata[i] -voice_class.error_band])
                {
                    *pos = i;
                    if(temppossible)*bytebit = 0;//正常方式
                    else *bytebit = 0x80;
                    //printf("JNIMSG_body_2 _BYTEBIT:%d\n",*bytebit);
                    return 1;
                }else
                {
                    return 0;
                }
            }break;
            default: break;
                
        }
        
        
        //}
    }
    return 0;
}
/***************************************************************************************
 **函数名:
 **功能  :
 **输入参数:
 **返回值 :
 ****************************************************************************************/
static int mk_Getbytebit1(char *psourcedata,short *pposdata,int *pos,int temppossible ,unsigned char *bytebit)
{
    int i;
    int num;
    unsigned char istatus;
    i = *pos;
    istatus = BYTE_BIT_STATUS1;
    num = 3;
    /*在找到起始位置后 按照正常方式连续找即可，不需要在整个数组里面查找*/
    //else if(((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band))
    //&&((pposdata[i+1] - pposdata[i]) <(voice_class.test_interval_count + voice_class.error_band + 2)))
    
    while(num > 0){
        num --;
        /*先判断周期，再判断电平*/
        //if(temppossible)//正常方式
        //{
        switch(istatus){
            case BYTE_BIT_STATUS1:{
                /*短半周期*/
                if(((pposdata[i+1] - pposdata[i]) >=(voice_class.test_half_interval_count - voice_class.error_band))
                   //       &&((pposdata[i+2] - pposdata[i+1]) < (voice_class.test_interval_count - voice_class.error_band)))
                   &&((pposdata[i+1] - pposdata[i]) < (voice_class.test_interval_count -voice_class.error_band+2)))
                    
                {
                    
                    istatus = BYTE_BIT_STATUS2;
                }else if((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band+2))
                    //else if((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band -1))
                    
                {
                    i = i + 1;
                    istatus = BYTE_BIT_STATUS4;
                }
                
            }break;
            case BYTE_BIT_STATUS2:{ //短周期进入
                if(((pposdata[i+2] - pposdata[i+1]) >=(voice_class.test_half_interval_count - voice_class.error_band))
                   /* &&((pposdata[i+2] - pposdata[i+1]) <= (voice_class.test_interval_count - voice_class.error_band))*/)
                    
                    
                {
                    i = i+ 2;
                    //printf("JNIMSG_body__just bit+3\n");
                    
                    istatus = BYTE_BIT_STATUS3;
                }else
                {
                    return 0;
                }
            }break;
            case BYTE_BIT_STATUS3:{ //短周期解码
                /*确定是 0或者1*/
                if(0 == psourcedata[pposdata[i-1] -voice_class.error_band])
                {
                    if(1 == psourcedata[pposdata[i]-voice_class.error_band])
                    {
                        *pos = i;
                        if(temppossible)*bytebit = 0;//正常方式
                        else *bytebit = 0x80;
                        return 1;
                    }else
                    {
                        return 0;
                    }
                    
                }else if(1 == psourcedata[pposdata[i-1] -voice_class.error_band])
                {
                    if(0 == psourcedata[pposdata[i]-voice_class.error_band])
                    {
                        *pos = i;
                        if(temppossible)*bytebit = 0x80;//正常方式
                        else *bytebit = 0;
                        
                        return 1;
                    }else
                    {
                        return 0;
                    }
                }
                
            }break;
            case BYTE_BIT_STATUS4:{//长周期解码
                //printf("JNIMSG_body__long per mode\n");
                if(0 == psourcedata[pposdata[i] -voice_class.error_band])
                {
                    *pos = i;
                    if(temppossible)*bytebit = 0x80;//正常方式
                    else *bytebit = 0;
                    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_body", "BYTEBIT:%d\n",*bytebit);
                    //printf("JNIMSG_body_1 _BYTEBIT:%d\n",*bytebit);
                    return 1;
                }else if(1 == psourcedata[pposdata[i] -voice_class.error_band])
                {
                    *pos = i;
                    if(temppossible)*bytebit = 0;//正常方式
                    else *bytebit = 0x80;
                    //printf("JNIMSG_body_2 _BYTEBIT:%d\n",*bytebit);
                    return 1;
                }else
                {
                    return 0;
                }
            }
                break;
            default: break;
                
        }
        
        
        //}
    }
    return 0;
}


/*******************************************************************************************
 **函数名:  mk_GetBytebody(char *psourcedata,short *pposdata,int *pos,int temppossible ,unsigned char *onebyte,unsigned char * paritybyte)
 **功能  :   获取 8bit-> byte
 **输入参数:
 **返回值  :
 ********************************************************************************************/
static int mk_GetBytebody(char *psourcedata,short *pposdata,int *pos,int temppossible ,unsigned char *onebyte,unsigned char * paritybyte)
{
    int i = 0;
    unsigned char tempbit;
    unsigned char tempbyte = 0;
    unsigned char tempcount;
    for( i = 0; i < 8;i++){
        
        if(mk_Getbytebit_check(psourcedata,pposdata,pos, temppossible ,&tempbit))
        {
            tempbyte = tempbyte>>1;
            tempbyte |= tempbit;
            
            //bitclass->bit1 +=(tempbit >> 7);
            
        }else
        {
            //printf("JNIMSG_body tempbyte is: %d\n",tempbyte);
            return 0;
        }
    }
    //bitclass->bit1 = 0;
    tempcount = 0;
    for(i = 0;i < 8;i++)
    {
        tempcount = tempcount + (tempbyte >> i) & 0x01;
    }
    *paritybyte = tempcount & 0x01;
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_body", "tempbyte is: %d",tempbyte);
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_WWW_N", "tempbyte is: %d",tempcount);
    //printf("JNIMSG_body__tempbyte is : %d\n",tempbyte);
    //printf("JNIMSG_body__tempbyte is : %d\n",tempbyte);
    *onebyte = tempbyte;
    return 1;
}

/********************************************************************************************
 **函数名: mk_GetParitybit(char *psourcedata,short *pposdata,int *pos,int temppossible,unsigned char paritybyte)
 **功能  : 判断校验位
 **输入参数:
 **返回值  :
 *********************************************************************************************/
static int mk_GetParitybit(char *psourcedata,short *pposdata,int *pos,int temppossible,unsigned char paritybyte)
{
    unsigned char tempbit;
    
    if(mk_Getbytebit_check(psourcedata,pposdata,pos,temppossible ,&tempbit))
    {
        //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_bit_WWW_P", "find thePARBIT_2:%d\n",(int)(tempbit >> 7));
        //printf("JNIMSG_bit_WWW_P the Parbit_2 %d\n", (tempbit >> 7));
        if(paritybyte ==((tempbit >> 7)& 0x01))
        {
            return 1;
        }else
        {
            return 0;
        }
    }else
    {
        //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_WWW", "run here");
        //printf("JNIMSG_WWW____run here\n");
        return 0;
    }
    return 0;
    
}

/**************************************************************************************************
 **函数名: mk_Getstopbit(char *psourcedata,short *pposdata,int *pos,int temppossible)
 **功能  :  获取停止位
 **输入参数:
 **返回值:
 **************************************************************************************************/
static int mk_Getstopbit(char *psourcedata,short *pposdata,int *pos,int temppossible)
{
    unsigned char tempbit;
    if(mk_Getbytebit_check(psourcedata,pposdata,pos,temppossible ,&tempbit))
    {
        if(1 == (tempbit >> 7))
        {
            return 1;
        }else
        {
            return 0;
        }
    }else
    {
        return 0;
    }
    return 0;
}

/***************************************************************************************
 **函数名: mk_Getbyte(char *psourcedata,short *pposdata,int *pos,unsigned char *onebyte)
 **功能  :  获取一个字节
 **输入参数:
 **返回值:
 ****************************************************************************************/
static int mk_Getbyte(char *psourcedata,short *pposdata,int *pos,unsigned char *onebyte)
{
    int istatus;
    int temppossible = 0;
    //__BIT bitclass;
    unsigned char paritybyte = 0;
    int i = 5;
    istatus = DATA_IDLE;
    while(i > 0){
        switch(istatus)
        {
            case DATA_IDLE:{
                if(mk_Startbit(pposdata,pos))
                {
                    istatus = DATA_START_BIT;
                }else
                {
                    return ERROR_START;
                }
            }break;
            case DATA_START_BIT:{
                //int2str(i,logms);
                
                
                ////__android_log_print(ANDROID_LOG_INFO, "JNIMSG_byte startbitpos:", logms);
//                temppossible = 1;//强制默认为正常方式mk_Getpossible(*pos);
                temppossible = mk_Getpossible(*pos);
                istatus = DATA_DATA_BIT;
            }break;
            case DATA_DATA_BIT:{
                if(mk_GetBytebody(psourcedata,pposdata,pos,temppossible ,onebyte,&paritybyte))
                {
                    istatus = DATA_PRAPILY_BIT;
                    //printf("JNIMSG_bit_WWW find thePARBIT_1:%d\n",(int)(paritybyte));
                }else
                {
                    //printf("JNIMSG_byte not find the bytebody");
                    return ERROR_BYTE;
                }
            }break;
            case DATA_PRAPILY_BIT: {
                //printf("JNIMSG_byte find the bytebody:%d\n",(int)(*onebyte));
            
                if(mk_GetParitybit(psourcedata,pposdata,pos,temppossible,paritybyte))
                {
                    istatus = DATA_STOP_BIT;
                }else
                {
                    if(onebyte[0] == SMART_DATA_END)
                    {
                        istatus = DATA_STOP_BIT;
                    }else{
                        //printf("JNIMSG_PRAPILY ERROR_P");
                        return ERROR_PAITY;//2015-4-8 12:13
                    }
                }
            }break;
            case DATA_STOP_BIT:{
                if(mk_Getstopbit(psourcedata,pposdata,pos,temppossible))
                {
                    return BYTE_OK;
                }else
                {
                    if(onebyte[0] == SMART_DATA_END)
                    {
                        return BYTE_OK;
                    }else{
                        //printf("JNIMSG_STOP ERROR_S");
                        return ERROR_STOP;//2015-4-8 12:13
                    }
                }
            }break;
            default: break;
                
        }
    }
    return ERROR_DEFAULT;
}
/***************************************************************************************
 **函数名: mk_Getbyte(char *psourcedata,short *pposdata,int *pos,unsigned char *onebyte)
 **功能  :  获取一个字节
 **输入参数:
 **返回值:
 ****************************************************************************************/
static int mk_Getbyte1(char *psourcedata,short *pposdata,int *pos,unsigned char *onebyte)
{
    int istatus;
    int temppossible = 0;
    //__BIT bitclass;
    unsigned char paritybyte = 0;
    int i = 5;
    istatus = DATA_IDLE;
    while(i > 0){
        switch(istatus)
        {
            case DATA_IDLE:{
                if(mk_Startbit(pposdata,pos))
                {
                    istatus = DATA_START_BIT;
                }else
                {
                    return ERROR_START;
                }
            }break;
            case DATA_START_BIT:{
                //int2str(i,logms);
                
                
                ////__android_log_print(ANDROID_LOG_INFO, "JNIMSG_byte startbitpos:", logms);
                //                temppossible = 1;//强制默认为正常方式mk_Getpossible(*pos);
                temppossible = mk_Getpossible(*pos);
                istatus = DATA_DATA_BIT;
            }break;
            case DATA_DATA_BIT:{
                if(mk_GetBytebody(psourcedata,pposdata,pos,temppossible ,onebyte,&paritybyte))
                {
                    istatus = DATA_PRAPILY_BIT;
                    //printf("JNIMSG_bit_WWW find thePARBIT_1:%d\n",(int)(paritybyte));
                }else
                {
                    //printf("JNIMSG_byte not find the bytebody");
                    return ERROR_BYTE;
                }
            }break;
            case DATA_PRAPILY_BIT: {
                //printf("JNIMSG_byte find the bytebody:%d\n",(int)(*onebyte));
                
                if(mk_GetParitybit(psourcedata,pposdata,pos,temppossible,paritybyte))
                {
                    istatus = DATA_STOP_BIT;
                }else
                {
                    if(onebyte[0] == SMART_DATA_END)
                    {
                        istatus = DATA_STOP_BIT;
                    }else{
                        //printf("JNIMSG_PRAPILY ERROR_P");
                        return ERROR_PAITY;//2015-4-8 12:13
                    }
                }
            }break;
            case DATA_STOP_BIT:{
                if(mk_Getstopbit(psourcedata,pposdata,pos,temppossible))
                {
                    return BYTE_OK;
                }else
                {
                    if(onebyte[0] == SMART_DATA_END)
                    {
                        return BYTE_OK;
                    }else{
                        //printf("JNIMSG_STOP ERROR_S");
                        return ERROR_STOP;//2015-4-8 12:13
                    }
                }
            }break;
                
        }
    }
    return ERROR_DEFAULT;
}

/***************************************************************************************
 **函数名:mk_Getdata(char *psourcedata,short *pposdata,int *pos,int temppossible,unsigned char *pdata,int *len)
 **功能  :获取一段数据 这个需要按照米开科技的协议结构来做
 **输入参数:
 **返回值 :
 *****************************************************************************************/
static int mk_Getdata1(char *psourcedata,short *pposdata,int *pos,int temppossible,unsigned char *pdata,int *len)
{
    int istatus = DATA_BUFFER_STAT;
    unsigned char tempbyte;
    unsigned char res;
    int i = 0;
    while(1){
        switch(istatus)
        {
            case DATA_BUFFER_STAT:{
                res = mk_Getbyte(psourcedata,pposdata,pos,&tempbyte);
                if(BYTE_OK == res)
                {
                    
                    if(SMART_DATA_START == tempbyte){
                        pdata[i] = tempbyte;
                        istatus = DATA_BUFFER_DATA;
                        i++;
                        //printf("JNIMSG_100 find the 0xAA \n");
                    }else
                    {
                        //printf("JNIMSG_100_1 find not start flag!! \n");
                        return ERROR_START_FLAG;
                    }
                }else
                {
                    byteToHexStr2(&res, 1,logms);
                    
                    //printf("JNIMSG_100_1 find failed!!ERROR_Flag: \n");
                    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_100_2", logms);
                    return res;
                }
            }break;
            case DATA_BUFFER_DATA:{
                //printf("JNIMSG_100_1 nowAApos is%d:\n",*pos);
                res = mk_Getbyte(psourcedata,pposdata,pos,&tempbyte);
                if(BYTE_OK == res)
                {
                    pdata[i] = tempbyte;
                    if((SMART_DATA_END == pdata[i]) && (i>=4))
                    {
                        istatus = DATA_BUFFER_END;
                    }else
                    {
                        istatus = DATA_BUFFER_DATA;
                        i++;
                    }
                }else
                {
                    //printf("JNIMSG_100_2 find 2 now error!! \n");
                    *len = i + 1;
                    if((*len)>3)
                    {
                        if(tempbyte == (pdata[i -1] + pdata[i-2]))
                        {
                            pdata[i] = tempbyte;
                        }
                    }
                    return res;
                }
            }break;
            case DATA_BUFFER_END:{
                *len = i + 1;
                //printf("JNIMSG_100 find the 0x55 \n");
                //printf("JNIMSG_100_1 find the len: %d; \n",i);
                return DATA_OK;
            }break;
            default: istatus = DATA_BUFFER_STAT; break;
        }
        
    }
}
/**********************************************************************************
 **函数名:
 **功能  :
 **输入参数:
 **功能   :
 **返回值:
 *********************************************************************************/
static int mk_Getdata2(char *psourcedata,short *pposdata,int *pos,int temppossible,unsigned char *pdata,int *len)
{
    int istatus = DATA_BUFFER_DATA;
    unsigned char tempbyte;
    unsigned char res;
    int i = 0;
    while(1){
        switch(istatus)
        {
            case DATA_BUFFER_STAT:{
                res = mk_Getbyte(psourcedata,pposdata,pos,&tempbyte);
                if(BYTE_OK == res)
                {
                    
                    if(SMART_DATA_START == tempbyte){
                        pdata[i] = tempbyte;
                        istatus = DATA_BUFFER_DATA;
                        i++;
                        //printf("JNIMSG_100 find the 0xAA \n");
                    }else
                    {
                        //printf("JNIMSG_100_1 find not start flag!! \n");
                        return ERROR_START_FLAG;
                    }
                }else
                {
                    byteToHexStr2(&res, 1,logms);
                    
                    //printf("JNIMSG_100_1 find failed!!ERROR_Flag: \n");
                    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_100_2", logms);
                    return res;
                }
            }break;
            case DATA_BUFFER_DATA:{
                //printf("JNIMSG_100_1 nowAApos is%d:\n",*pos);
                res = mk_Getbyte(psourcedata,pposdata,pos,&tempbyte);
                if(BYTE_OK == res)
                {
                    pdata[i] = tempbyte;
                    if((SMART_DATA_END == pdata[i]) && (i>=(BUFF_LEN-1)))
                    {
                        istatus = DATA_BUFFER_END;
                    }else
                    {
                        istatus = DATA_BUFFER_DATA;
                        i++;
                    }
                }else
                {
                    //printf("JNIMSG_100_2 find 2 now error!! \n");
                    *len = i + 1;
                  /*  if((*len)>4)
                    {
                        
                            pdata[(*len) + 1] = SMART_DATA_END;
                        *len  = (*len) + 1;
                    }*/
                    return res;
                }
            }break;
            case DATA_BUFFER_END:{
                *len = i + 1;
                //printf("JNIMSG_100 find the 0x55 \n");
                //printf("JNIMSG_100_1 find the len: %d; \n",i);
                return DATA_OK;
            }break;
            default:  break;
        }
        
    }
}

/*******************************************************************************
 **函数名:  myabs(int n)
 **输入参数:  求取绝对值
 **功能:
 **返回值 :
 ********************************************************************************/
static int myabs(int n)
{
    return n * ((n>>31<<1) +1);
}

/*****************************************************************************************
 **函数名:mk_NOTDATA(unsigned char *psourcedata,unsigned char *pdestdata,unsigned short len)
 **功能  :数据转化 针对国标和非国标之间的数据转化，目前不用
 **输入参数:
 **返回值 :
 ******************************************************************************************/
static int mk_NOTDATA(unsigned char *psourcedata,unsigned char *pdestdata,int len)
{
    unsigned short i;
    unsigned char j;
    unsigned char tmpbyte;
    for(i = 0; i< len;i++)
    {
        tmpbyte = 0;
        for(j = 0;j <8;j++)
            tmpbyte |= ((psourcedata[i] >> j) & 0x01) <<(7-j);
        
        pdestdata[i] = tmpbyte;
    }
    return 1;
}

/***************************************************************************************
 **函数名:
 **功能  : 本函数主要是用来去除空录的波形的处理 预处理，我们目前将这部分函数做到了APP里面 ，没做到库
 **输入参数:
 **返回值:
 *****************************************************************************************/
static int mk_Pretreatment(short  *psourcedata,int len)
{
    int i,j;
    for(i =0; i<len;i++)
    {
        if(myabs(psourcedata[i]) > voice_class.dead_value_pos)
        {
            break;
        }
    }
    j = 0;
    
    while(i < len)
    {
        voice_class.sourcedata[j++] = psourcedata[i++];
    }
    for(i =0; i<len;i++)
    {
        psourcedata[i] = voice_class.sourcedata[i];
    }
    return 1;
}
/***************************************************************************************
 **函数名:
 **功能  : 寻找空闲波段。
 **输入参数:
 **返回值 :
 ***************************************************************************************/
static int mk_Findidle(short *pposdata,int *pos)
{
    int idle_count = 0;
    int temp_now_pos=0;
    int istatus = IDLE_BIT_STATUS1;
    int i;
    i = *pos;
    while((pposdata[i]!= -1) && (i < SAMPLE_DATAPOS_LEN_MAX)){
        switch(istatus){
            case IDLE_BIT_STATUS1:{
                /*短半周期*/
                if(((pposdata[i+1] - pposdata[i]) >=(voice_class.test_half_interval_count - voice_class.error_band))
                   &&((pposdata[i+1] - pposdata[i]) <(voice_class.test_interval_count - voice_class.error_band)))
                {
                    
                    istatus = BYTE_BIT_STATUS2;
                }else /*if((pposdata[i+1] - pposdata[i]) >=(voice_class.test_interval_count - voice_class.error_band))*/
                {
                    i = i + 1;
                    idle_count = 0;
                    temp_now_pos = i;
                    istatus = BYTE_BIT_STATUS1;
                }
            }break;
            case IDLE_BIT_STATUS2:{ //短周期进入
                if(((pposdata[i+2] - pposdata[i+1]) >=(voice_class.test_half_interval_count - voice_class.error_band))
                   &&((pposdata[i+2] - pposdata[i+1]) <(voice_class.test_interval_count - voice_class.error_band)))
                    
                {
                    i = i+ 2;
                    idle_count++;
                    if(idle_count >=2)
                    {
                        istatus = BYTE_BIT_STATUS3;
                    }else{
                        istatus = BYTE_BIT_STATUS1;
                    }
                }else
                {
                    i = i + 2;
                    idle_count = 0;
                    temp_now_pos = i;
                    istatus = BYTE_BIT_STATUS1;
                }
            }break;
            case IDLE_BIT_STATUS3:{
                *pos = temp_now_pos;
                //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_byte", "find the IDLEbitiiii: %d;",temp_now_pos);
                //printf("find the IDLEbitiiii: %d;\n",temp_now_pos);
                return 1;
            }break;
            default: break;
        }
   	}
    return 0;
}
/***************************************************************************************************************
 **函数名：
 **功能 ；
 **输入参数
 **返回中
 *************************************************************************************************************/
static void mk_calc1(short *lin,int off,int len) {
    int i,j;
    for (i = 0; i < len; i++) {
        j = lin[i+off];
        lin[i+off] = (short)(j  >>2);
    }
}
/******************************************************************************************
 **函数名:  mk_Data(short  *psourcedata,int len,unsigned char *pdestdata,int *bytelen)
 **功能  :  对接收到的数据进行处理 返回
 **输入参数:
 **返回值  :
 *******************************************************************************************/
static int mk_Data1(short  *psourcedata,int len,unsigned char *pdestdata,int *bytelen)
{
    unsigned char res;
    int pos =0;
    int temppossible = 0;
    int i;
    bool stepflag = true;
    int templen = 0;
    /*第一步去除空录的波形*/
    mk_calc1(psourcedata,0,len);
    //data_deal(psourcedata,len);
    //mk_Pretreatment(psourcedata,len);
    /*第二步数模转化，将AD采样到的数据转化为0 或者1*/
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_1", "Gey digtal data");
 // if(steflag){
        //if(!mk_analog2digtal1(psourcedata, charsourcedatapossbile,len))
         //   return ERROR_A2D;
 /*   }else
    {
        if(!mk_analog2digtal1(psourcedata, charsourcedatapossbile,len))
            return ERROR_A2D;
    }
  */
   mk_analog2digtal(psourcedata, charsourcedatapossbile,len);
  
    /*第三步拆分数据，模拟出矩形波*/
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_2", "split");
    //if(!mk_Splitdata(charsourcedatapossbile,len))
     //   return ERROR_SPL;
    if(!mk_Splitdata(charsourcedatapossbile,len))
       return ERROR_SPL;
    //printf("************split data begin**************\n");
    //for (int k=0; k<1024; k++) {
    //    printf("%i %i\n",k,sourcedatapos[k]);
    //}
    //printf("************split data end**************\n");
    /*第四步找到正常的空闲波形 最少找5个作为起始*/
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_3", "IDLE_find");
    if(!mk_Findidle(sourcedatapos,&pos))
        return ERROR_NO_IDLE;
    
    /*第五步获取数据*/
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_3", "decod digtal data");
  //  res = mk_Getdata(charsourcedatapossbile,sourcedatapos,&pos,temppossible,pdestdata,bytelen);
     res = mk_Getdata2(charsourcedatapossbile,sourcedatapos,&pos,temppossible,pdestdata,bytelen);
    if(DATA_OK !=res){
        /*此处加入判断*/
        if(bytelen[0] == (BUFF_LEN - 1)){ //结束符号未被加入
            pdestdata[bytelen[0]] = SMART_DATA_END;
            bytelen[0] =bytelen[0] + 1;
        }else if(bytelen[0] == BUFF_LEN)
        {
            if(pdestdata[bytelen[0] -1] != SMART_DATA_END)
        
                pdestdata[bytelen[0] - 1] = SMART_DATA_END;
        }
    /*    if(pdestdata[2] != ((pdestdata[0]+pdestdata[1])&0xFF))
        {
            stepflag = false;
            goto STEP;
            
        }
     */
        return res;
    }
  //  if((pdestdata[1]+pdestdata[2]))
    return DATA_OK;
    
    
}
/********************************************************************************************************
 **
 **
 **
 **
 ********************************************************************************************************/

static int mk_Data(short  *psourcedata,int len,unsigned char *pdestdata,int *bytelen)
{
    unsigned char res;
    int pos =0;
    int temppossible = 0;
    int i;
    /*第一步去除空录的波形*/
    mk_calc1(psourcedata,0,len);
    //mk_Pretreatment(psourcedata,len);
    /*第二步数模转化，将AD采样到的数据转化为0 或者1*/
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_1", "Gey digtal data");
    
    if(!mk_analog2digtal(psourcedata, charsourcedatapossbile,len))
        return ERROR_A2D;
    
    /*第三步拆分数据，模拟出矩形波*/
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_2", "split");
    if(!mk_Splitdata(charsourcedatapossbile,len))
        return ERROR_SPL;
    //printf("************split data begin**************\n");
    //for (int k=0; k<1024; k++) {
    //    printf("%i %i\n",k,sourcedatapos[k]);
    //}
    //printf("************split data end**************\n");
    /*第四步找到正常的空闲波形 最少找5个作为起始*/
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_3", "IDLE_find");
    if(!mk_Findidle(sourcedatapos,&pos))
        return ERROR_NO_IDLE;
    
    /*第五步获取数据*/
    //__android_log_print(ANDROID_LOG_INFO, "JNIMSG_3", "decod digtal data");
    res = mk_Getdata2(charsourcedatapossbile,sourcedatapos,&pos,temppossible,pdestdata,bytelen);
    if(DATA_OK !=res){
        /*此处加入判断*/
        if(bytelen[0] == (BUFF_LEN -1)){ //结束符号未被加入
            pdestdata[bytelen[0]] = SMART_DATA_END;
            bytelen[0] =bytelen[0] + 1;
        }else if(bytelen[0] == BUFF_LEN)
        {
            if(pdestdata[bytelen[0] -1] != SMART_DATA_END)
                pdestdata[bytelen[0] - 1] = SMART_DATA_END;
        }
        return res;
    }
    //  if((pdestdata[1]+pdestdata[2]))
    return DATA_OK;
}

#endif /* defined(__HomeKinsa__lib_decode__) */
