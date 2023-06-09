#ifndef __HARDWARE_H__
#define __HARDWARE_H__

#include <stdint.h>


#define REG(write,read) 	union { uint8_t write; const uint8_t read; }


typedef struct {
	REG(orb, irb);			// W: Output register B; R: input register B
	REG(ora, ira);			// W: Output register B; R: input register B
	uint8_t ddrb;			// Data Direction Register B
	uint8_t ddra;			// Data Direction Register A
	uint8_t t1c_l;			// W: T1 Low-Order Latches; R: T1 Low-Order Counter IFR6 reset
	uint8_t t1c_h;			// T1 High-Order Counter
	uint8_t t1l_l;			// T1 Low-Order Latches
	uint8_t t1l_h;			// T1 High-Order Latches
	uint8_t t2c_l;			// W: T2 Low-Order Latches; R: T2 Low-Order Counter IFR5 reset
	uint8_t t2c_h;			// W: T2 High-Order Counter IFR5 reset; R: T2 High-Order Counter
	uint8_t sr;				// Shift Register
	uint8_t acr;			// Auxiliary Control Register
	uint8_t pcr;			// Peripheral Control Register
	uint8_t ifr;			// Interrupt Flag Register
	uint8_t ier;			// Interrupt Enable Register
	REG(ora_nh, ira_nh);	// Same as ora/ira except no "Handshake"
} via_t;

typedef struct {
	uint8_t addr;
	uint8_t reg;
} crtc_t;




typedef struct {
	REG(control, status);	// W: control register; R: status register
	REG(txb, rxb);			// W: transmit buffer; R: receive buffer
} acia_t;

typedef struct {
	uint8_t vcr;			// W: video control register
	uint8_t palette;		// W: palette register
} vidula_t;

typedef struct {
	uint8_t dummy;
} fdc8271_t;

typedef struct {
	uint8_t dummy;
} fdc1770_t;

typedef struct {
	uint8_t dummy;
} adlc_t;

typedef struct {
	uint8_t dummy;
} adc_t;

typedef struct {
	uint8_t dummy;
} tubeula_t;

#define ALIGN(n) __attribute__((aligned(n)))

typedef struct {
	ALIGN(8)	crtc_t crtc;				// 6845 CRTC video controller
	ALIGN(8)	acia_t acia;				// 6850 ACIA serial contoller
	ALIGN(16)	uint8_t serial_ula;			// serial ULA
	ALIGN(16)	vidula_t video_ula;			// video ULA
	ALIGN(16)	uint8_t romsel;				// paged ROM select register
	ALIGN(32)	via_t system_via;			// 6522 VIA system
	ALIGN(32)	via_t user_via;				// 6522 VIA user
	union {
		ALIGN(32) fdc8271_t floppy_8271;	// 8271 Floppy controller
		ALIGN(32) fdc1770_t floppy_1770;	// 1770 Floppy controller
	};
	ALIGN(32)	adlc_t econet;				// 68B54 ADLC Econet controller
	ALIGN(32)	adc_t adc;					// uPD7002 Analogue to digital converter
	ALIGN(32)	tubeula_t tube_ula;			// Tube
} sheila_t;



static volatile sheila_t* const sheila = (sheila_t* const)0xfe00U;

// use to prevent compiler emitting "lda #ofs, tay, sta $nnnn,7" instead of sta $mmmm
static inline void outb(volatile uint8_t* const p, uint8_t val) { *p = val; }
static inline uint8_t inb(volatile const uint8_t* const p) { return *p; }



//
// globally useful helper functions
typedef enum {
	SB_SN76489, SB_TMS5520_RS, SB_TMS5520_WS,
	SB_KEYBEN_N, SB_C0, SB_C1, SB_KEYBLED1, SB_KEYBLED0
} slowbusdev_t;

static inline void slowbus1(slowbusdev_t dev) {
	//	sheila->system_via.orb = (dev & 0xf) | 8;
	outb(&sheila->system_via.orb, (dev & 0xf) | 8);
}
static inline void slowbus0(slowbusdev_t dev) {
	outb(&sheila->system_via.orb, (dev & 0xf));
}
static inline void slowbusdirection(uint8_t mask) {
	outb(&sheila->system_via.ddra, mask); // set inputs/outputs
}
static inline void slowbuswrite(uint8_t data) {
	outb(&sheila->system_via.ora, data);
}
static inline uint8_t slowbusread() {
	return inb(&sheila->system_via.ira);
}

void slowbus_sn76489_write(uint8_t data);


//
// misc helpers
#define NOPDELAY(us) __asm__ __volatile__("jsr nopdelayus_" #us)



#endif // !__HARDWARE_H__
