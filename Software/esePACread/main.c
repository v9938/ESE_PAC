/*
	esePAC Test program
	Copyright 2021 @V9938
	
	V1.0		1st version
*/

#include <stdio.h>
#include<string.h>
#include <msx.h>
#include <sys/ioctl.h>

#define VERSION "V1.0"
#define DATE "2021/10"

#define BUF_SIZE 0x2000

//Global
unsigned char SelectSlot;		//Select Slot number
unsigned char eseSlot;			//SimpleROM Slot number

//Assembler SubRoutine

void asmCalls(){
#asm
chengePageSlot:
	di
    ld a,(_SelectSlot)	;Slot Number
    ld hl,04000h		;Chenge Slot Page1
    call 0024h			;call ENSLT

    ld a,04Dh			;PAC SRAM Chenge
    ld (05FFEh),a
    ld a,069h
    ld (05FFFh),a
	ret

PacPass:
	ld hl,00000h		;find!
	jr restoreRAMPage	;
PacErr:
	ld hl,0ffffh		;Not find!
restoreRAMPage:
    ld a,000h			;Reset Setting
    ld (05FFEh),a
    ld (05FFFh),a
	push hl
	ld a,(0f342h)		;Restore RAM Page (RAMAD1)
    ld hl,04000h		;Select page 1
    call 0024h			;call ENASLT
	pop hl
	ei
	ret
#endasm
}
void pause()
{
#asm
pauseLoop:
	jr pauseLoop
#endasm

}

void WriteSramData(unsigned char *bufferAddress)
{
#asm
	push hl					;Backup Buffer address
	call chengePageSlot		;Page1 Select PAC Slot

	ld de,04000h			;PAC SRAM address
	ld bc,02000h-2			;Transfer Size
	pop hl					;Buffer address load
	ldir
	jr	restoreRAMPage		;Restore Slot
#endasm
}

void ReadSramData(unsigned char *bufferAddress)
{
#asm
	push hl					;Backup Buffer address
	call chengePageSlot		;Page1 Select PAC Slot

	ld hl,04000h			;PAC SRAM address
	ld bc,02000h-2			;Transfer Size
	pop de					;Buffer address load
	ldir
	jr	restoreRAMPage		;Restore Slot
#endasm
}

int chkPacInSlot() __z88dk_fastcall __naked {
#asm
	di
    ld a,(_SelectSlot)	;Slot Number
    ld hl,04000h		;Chenge Slot Page1
    call 0024h			;call ENSLT
	ld hl,04000h		;Check Address 

	call chkData		;Check 4000h
	jr z,PacErr			;Fail (RAM Slot?)
	
    ld a,04Dh			;PAC SRAM Chenge
    ld (05FFEh),a
    ld a,069h
    ld (05FFFh),a

	call chkData		;Check 4000h
	jr nz,PacErr		;Fail (Not Use/ROM Slot?)

	inc hl				;One more check...
	call chkData		;Check 4001h
	jr nz,PacErr		;Fail (Not Use/ROM Slot?)
	jr PacPass

chkData:
	ld a,(hl)			;Read SRAM Data
	ld b,a				;Backup org data
	xor 0ffh			;Data bitflip
	ld (hl),a			;Write SRAM Data
	ld c,(hl)			;Read SRAM Data (Again)
	ld (hl),b			;pop ori Data
	xor c				;2nd Data(XOR)?
	ret					;z = Read/Write PASS 
#endasm
}


void findPacSlot(void){
	unsigned char i;
	unsigned int findflag;
	
	if ((SelectSlot & 0xf0) == 0x80){
		//Expantion Slot Check
		for (i=0;i<4;i++){
			findflag = chkPacInSlot();
			if (findflag == 0) {
				eseSlot = SelectSlot;
			}
			SelectSlot = SelectSlot + 4;
		}
	}else{
		//Master Slot Check
		findflag = chkPacInSlot();
		if (findflag == 0) {
			eseSlot = SelectSlot;
		}
	}
}

int main(int argc,char *argv[])
{
	FILE *fp;
	unsigned char SRAMData[BUF_SIZE];

	
	
	printf("esePAC Read Program %s\n",VERSION);
	printf("Copyrigth %s @v9938\n\n",DATE);

	if (argc<2){
		printf( ">pacRead\n");
		printf( "This program is used to backup esePanasonic Amusement Cartridge.\n");
		return 0;
	}


	printf("Search PAC ... ");
	eseSlot = 0;
	//Slot 0 Search
	SelectSlot = *((unsigned char *)0xfcc1) | 0x01;		//EXPTBL (SLOT0)
	findPacSlot();
	//Slot 1 Search
	SelectSlot = *((unsigned char *)0xfcc2) | 0x01;		//EXPTBL (SLOT1)
	findPacSlot();
	//Slot 2 Search
	SelectSlot = *((unsigned char *)0xfcc3) | 0x02;		//EXPTBL (SLOT2)
	findPacSlot();
	//Slot 3 Search
	SelectSlot = *((unsigned char *)0xfcc4) | 0x03;		//EXPTBL (SLOT3)
	findPacSlot();

	if (eseSlot == 0) {								// Not find esePAC
		printf("NOT find\n");
		printf("Bye...\n");
		return -1;
	}else{
		printf("Find!\n");
		printf("\nSlot: %02x",eseSlot);
		SelectSlot = eseSlot;
	}

	
   	printf( "\nRead RAM Data...");
	ReadSramData(SRAMData);

   	printf( "\nSave Data...");
	fp =fopen(argv[1],"wb");
    if( fp == NULL ){
    	printf( "\nFile can't open... %s\n", argv[1]);
    	return -1;
    }
    fwrite(SRAMData,sizeof SRAMData, 1,fp);
	fclose(fp);
	printf("\n\nDone. Thank you using!\n");
	return 0;

}
