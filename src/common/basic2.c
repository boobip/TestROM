#include "basic2.h"

#include<mystdio.h>

//char* const _rndc = 0xd;


extern void oswrch2(char c);


//void basic2_rndgen()
//{
//	__asm__ __volatile__("jsr $af87");
//}

//void basic2_rndseed(uint32_t Seed)
//{
//	*_rnd = Seed;
//	*_rnd5 = 0x40; // do this because basic does it
//	//oswrch2(0xaa);
//}


//int fputc(int c, FILE *f)
//{
//	register char x asm("a") = c;
//	if (x == '\n')
//		/* OSNEWL */
//		__asm__ __volatile__("jsr $ffe7");
//	else
//		/* OSWRCH */
//		__asm__ __volatile__("jsr $ffee" : : "Aq" (x));
//
//	return c;
//}

void testfunc()
{
	osasci('@');
}

void basic2_SetPrintFormat(char B4, char B3, char B2, char B1)
{
	//TODO: change to an enum and pick from a lookup table
	((char*)_basic_reg_atpercent)[0] = B1; //width
	((char*)_basic_reg_atpercent)[1] = B2; //digits
	((char*)_basic_reg_atpercent)[2] = B3; //mode gen=0,exp=1,fix=2
	((char*)_basic_reg_atpercent)[3] = B4; //use on str$
}

void basic2_cntosudec()
{
	if (((char*)_basic_reg_inta)[3] < 0x80U) return basic2_cntosdec();

	basic2_SetPrintFormat(1, 0, 10, 1);
	_basic_reg_fpa->binaryexponent = 0xA0;
	_basic_reg_fpa->exponentoverflow = 0;
	_basic_reg_fpa->mantissa[0] = ((char*)_basic_reg_inta)[3];
	_basic_reg_fpa->mantissa[1] = ((char*)_basic_reg_inta)[2];
	_basic_reg_fpa->mantissa[2] = ((char*)_basic_reg_inta)[1];
	_basic_reg_fpa->mantissa[3] = ((char*)_basic_reg_inta)[0];
	_basic_reg_fpa->roundingbyte = 0;
	_basic_reg_fpa->sign = 0;
	basic2_cntosfp();
	basic2_SetPrintFormat(0, 0, 9, 10);
}
