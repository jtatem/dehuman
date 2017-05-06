    processor 6502
    include vcs.h
    org $F000
	

rand1 = $80
rand2 = $81
RangeUpperBound = $90
RangeLowerBound = $91
RangeUpperBoundDir = $92
RangeLowerBoundDir = $93
RangeUpperBoundSpeed = $94
RangeLowerBoundSpeed = $95

RangeASize = $97
RangeBSize = $98
RangeCSize = $99

RangeUpperMax = $A0
RangeLowerMin = $A1
RangeSizeMin = $A2
RangeSizeMax = $A3

BgColOuter = $A4
FgColOuter = $A5
BgColInner = $A6
FgColInner = $A7

SpeedChangeCounter = $A8
SpeedChangePointer = $A9
Player0Speed = $AA
Player1Speed = $AB

ColorChangeCounter = $B0
ColorChangePointer = $B1
Player0ColOuter = $B2
Player1ColOuter = $B3
Player0ColInner = $B4
Player1ColInner = $B5

RandSpriteA = $B6
RandSpriteB = $B7
RandSpriteC = $B8
RandSpriteD = $B9
RandSpriteE = $BA
RandSpriteF = $BB

FrameCounter = $BC

BeatDelayCounter = $C4
BeatPosCounter = $C5
ActiveBeatData = $C6
BeatDataALen = $C7
BeatDataBLen = $C8
BeatDataCLen = $C9

LeftFreqDiv = $CA
RightFreqDiv = $CB
LeftFreqChangeTimer = $CC
RightFreqChangeTimer = $CD

Numerator = $D0
Denominator = $D1

NoteDelayCounter = $E0
NotePosCounter = $E1
ActiveNoteData = $E2
NoteDataALen = $E3
NoteDataBLen = $E4
NoteDataCLen = $E5
NoteInstrumentPointer = $E6
NoteInstrumentValue = $E7



Start
    SEI ; disable interrupts
    CLD ; clear BCD math bit    
    LDX #$FF ; x = 255
    TXS ; use x to reset stack pointer
    LDA #0 ; store 0 in a, will use this to clear mem           
ClearMem 
    STA 0,X     ; put value of a (0) into the mem loc x+0
    DEX ; decrement x   
    BNE ClearMem ; keep looping til x hits 0
	
; Other pre-drawing setup
	LDA #7
	STA ColorChangePointer
	LDA #6
	STA ColorChangeCounter
	LDA #29
	STA SpeedChangePointer
	LDA #10
	STA SpeedChangeCounter
	LDA #0
	STA FrameCounter
	
	; init music counters
	
	LDA #34
	STA BeatDataALen
	LDA #50
	STA BeatDataBLen
	LDA #21
	STA BeatDataCLen
	LDA #1
	STA ActiveBeatData
	
	LDA #1
	STA BeatDelayCounter
	LDA BeatDataALen
	STA BeatPosCounter
	
	LDA #18
	STA NoteDataALen
	LDA #58
	STA NoteDataBLen
	LDA #24
	STA NoteDataCLen
	LDA #1
	STA ActiveNoteData
	
	LDA #1
	STA NoteDelayCounter
	LDA NoteDataALen
	STA NotePosCounter
	
	LDA #0
	STA LeftFreqDiv
	STA RightFreqDiv
	LDA #2
	STA LeftFreqChangeTimer
	STA RightFreqChangeTimer
	
	LDA #4
	STA NoteInstrumentPointer
	LDA #6
	STA NoteInstrumentValue
	
		
	LDA #210
	STA rand1
	LDA #69
	STA rand2
	
; Setup sliding range initial values

	LDA #185
	STA RangeUpperMax
	LDA #5
	STA RangeLowerMin
	LDA #3
	STA RangeSizeMin
	LDA #100
	STA RangeSizeMax

	LDA #125
	STA RangeUpperBound
	LDA #75
	STA RangeLowerBound
	LDA #1
	STA RangeUpperBoundDir
	LDA #0
	STA RangeLowerBoundDir
	LDA #1
	STA RangeUpperBoundSpeed
	LDA #1
	STA RangeLowerBoundSpeed
	
	; Initialize random seeds
	
	LDA #77
	STA rand1
	LDA #202
	STA rand2


    
; Let's draw a frame    
MainLoop
    LDA  #2 ; a = 2, need bit 1 for enabling VSYNC
    STA  VSYNC  ; enable VSYNC
    STA  WSYNC  ; hold VSYNC for 3 scanlines by WSYNC'ing 3x
    STA  WSYNC  ; WSYNC doesn't care what value is passed
    STA  WSYNC  
    LDA  #43 ; a = 43. 2798 cycles to wait. Using 64 cycle timer, that's about 43       
    STA  TIM64T ; store that in the timer
    LDA #0      ; a = 0, need 0 for disabling VSYNC     
    STA  VSYNC  ; disable vsync

; SAFE ZONE FOR PRE-VISIBLE FRAME STUFF


	
	DEC ColorChangeCounter
	BNE EndColorChangeBlock
	LDX ColorChangePointer
	LDA RedColors-1,X
	STA FgColOuter
	LDA RedColors,X
	STA BgColOuter
	LDA RedColors+2,X
	STA Player0ColOuter
	LDA RedColors+3,X
	STA Player1ColOuter
	LDA GrayCycle-1,X
	STA FgColInner
	LDA GrayCycle,X
	STA BgColInner
	LDA GrayCycle+2,X
	STA Player0ColInner
	LDA GrayCycle+3,X
	STA Player1ColInner
	LDA #7
	STA ColorChangeCounter
	DEC ColorChangePointer
	BNE EndColorChangeBlock
	LDA #7
	STA ColorChangePointer
EndColorChangeBlock    


	DEC SpeedChangeCounter
	BNE EndSpeedChangeBlock
	LDX SpeedChangePointer
	LDA Player0SpeedRange-1,X
	STA Player0Speed
	LDA Player1SpeedRange,X
	STA Player1Speed
	LDA #10
	STA SpeedChangeCounter
	DEC SpeedChangePointer
	BNE EndSpeedChangeBlock
	LDA #29
	STA SpeedChangePointer

EndSpeedChangeBlock
    

;	Apply range changes
	
	LDA RangeUpperBoundDir
	CMP #1
	BEQ RangeUpperBoundAdd
	CMP #0
	BEQ RangeUpperBoundSub
RangeUpperBoundAdd
	LDA RangeUpperBound
	ADC RangeUpperBoundSpeed
	STA RangeUpperBound
	JMP RangeUpperBoundDeltaEnd
RangeUpperBoundSub
	LDA RangeUpperBound
	SBC RangeUpperBoundSpeed
	STA RangeUpperBound
RangeUpperBoundDeltaEnd
	CMP RangeUpperMax
	BCC CheckRangeUpperBoundMin
	LDA RangeUpperMax
	STA RangeUpperBound
	LDA #0
	STA RangeUpperBoundDir
	JMP RangeUpperBoundSpeedRandom
CheckRangeUpperBoundMin
	LDA RangeLowerBound
	ADC RangeSizeMin
	CMP RangeUpperBound
	BCC DoneUpperBound
	STA RangeUpperBound
	LDA #1
	STA RangeUpperBoundDir
RangeUpperBoundSpeedRandom
	JSR randomize
	CMP #200
	BCS UpperBoundSpeed5
	CMP #150
	BCS UpperBoundSpeed4
	CMP #100
	BCS UpperBoundSpeed3
	CMP #50
	BCS UpperBoundSpeed2
UpperBoundSpeed1
	LDA #1
	STA RangeUpperBoundSpeed
	JMP DoneUpperBound
UpperBoundSpeed2
	LDA #2
	STA RangeUpperBoundSpeed
	JMP DoneUpperBound
UpperBoundSpeed3
	LDA #3
	STA RangeUpperBoundSpeed
	JMP DoneUpperBound
UpperBoundSpeed4
	LDA #4
	STA RangeUpperBoundSpeed
	JMP DoneUpperBound
UpperBoundSpeed5
	LDA #5
	STA RangeUpperBoundSpeed
DoneUpperBound


	LDA RangeLowerBoundDir
	CMP #1
	BEQ RangeLowerBoundAdd
	CMP #0
	BEQ RangeLowerBoundSub
RangeLowerBoundAdd
	LDA RangeLowerBound
	ADC RangeLowerBoundSpeed
	STA RangeLowerBound
	JMP RangeLowerBoundDeltaEnd
RangeLowerBoundSub
	LDA RangeLowerBound
	SBC RangeLowerBoundSpeed
	STA RangeLowerBound
RangeLowerBoundDeltaEnd
	CMP RangeLowerMin
	BCS CheckRangeLowerBoundMin
	LDA RangeLowerMin
	STA RangeLowerBound
	LDA #1
	STA RangeLowerBoundDir
	JMP RangeLowerBoundSpeedRandom
CheckRangeLowerBoundMin
	LDA RangeUpperBound
	SBC RangeSizeMin
	CMP RangeLowerBound
	BCS DoneLowerBound
	STA RangeLowerBound
	LDA #0
	STA RangeLowerBoundDir
RangeLowerBoundSpeedRandom
	JSR randomize
	CMP #200
	BCS LowerBoundSpeed5
	CMP #150
	BCS LowerBoundSpeed4
	CMP #100
	BCS LowerBoundSpeed3
	CMP #50
	BCS LowerBoundSpeed2
LowerBoundSpeed1
	LDA #2
	STA RangeLowerBoundSpeed
	JMP DoneLowerBound
LowerBoundSpeed2
	LDA #4
	STA RangeLowerBoundSpeed
	JMP DoneLowerBound
LowerBoundSpeed3
	LDA #6
	STA RangeLowerBoundSpeed
	JMP DoneLowerBound
LowerBoundSpeed4
	LDA #8
	STA RangeLowerBoundSpeed
	JMP DoneLowerBound
LowerBoundSpeed5
	LDA #10
	STA RangeLowerBoundSpeed
DoneLowerBound


	; Compute ranges

	LDA #191
	SBC RangeUpperBound
	STA RangeASize
	LDA RangeUpperBound
	SBC RangeLowerBound
	STA RangeBSize
	LDA RangeLowerBound
	STA RangeCSize
	
	
	; Init iterator registers
	
	LDY RangeASize
	LDX #191
	
	; Set colors for first region
	
	LDA FgColOuter
	STA COLUPF
	LDA BgColOuter
	STA COLUBK
	LDA Player0ColOuter
	STA COLUP0
	LDA Player1ColOuter
	STA COLUP1
	
	LDA RangeUpperBound
	STA GRP0
	LDA FrameCounter
	STA GRP1
	
	; Set player speeds
	
	LDA Player0Speed
	STA HMP0
	LDA Player1Speed
	STA HMP1
	
	; Set some randoms we'll use per frame
	
	JSR randomize
	STA RandSpriteA
	JSR randomize
	STA RandSpriteB
	JSR randomize
	STA RandSpriteC
	JSR randomize
	STA RandSpriteD
	JSR randomize
	STA RandSpriteE
	JSR randomize
	STA RandSpriteF


	
; END SAFE ZONE FOR PRE-VISIBLE FRAME STUFF

WaitForVblankEnd
    LDA INTIM     
    BNE WaitForVblankEnd 
    STA WSYNC 
    STA VBLANK ; needs to be 0, we get that from timer end
    STA HMOVE
	STA WSYNC

ScanLoopA
    STA WSYNC
    
    LDA PF0SpriteA-1,X
    STA PF0 
        
    LDA PF1SpriteA-1,X
    STA PF1
	
    
    LDA PF2SpriteA-1,X
    STA PF2 
   
 
    LDA PF0SpriteB-1,X
    STA PF0 
    
	NOP
	
    LDA PF1SpriteB-1,X
    STA PF1
	
	NOP
	NOP
    
    LDA PF2SpriteB-1,X
    STA PF2
	
	LDA INPT5 ; P1 Fire
	BMI EndLineA
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP

    
EndLineA

	DEX
    DEY
    BNE ScanLoopA
	STA WSYNC
	LDY RangeBSize
	LDA FgColInner
	STA COLUPF
	LDA BgColInner
	STA COLUBK
	LDA Player0ColInner
	STA COLUP0
	LDA Player1ColInner
	STA COLUP1
	JMP ScanLoopBWsyncBypass

ScanLoopB
    STA WSYNC
ScanLoopBWsyncBypass

    LDA AltPF0SpriteA-1,X
	ORA RandSpriteA
    STA PF0 
        
    LDA AltPF1SpriteA-1,X
	ORA RandSpriteB
    STA PF1
	
    
    LDA AltPF2SpriteA-1,X
	ORA RandSpriteC
    STA PF2 
   	
 
    LDA AltPF0SpriteB-1,X
	ORA RandSpriteD
    STA PF0 
    
    LDA AltPF1SpriteB-1,X
	ORA RandSpriteE
    STA PF1
	
    
    LDA AltPF2SpriteB-1,X
	ORA RandSpriteF
    STA PF2
    
    
EndLineB 

	DEX
    DEY
    BNE ScanLoopB
	STA WSYNC
	LDY RangeCSize
	LDA FgColOuter
	STA COLUPF
	LDA BgColOuter
	STA COLUBK
	LDA Player0ColOuter
	STA COLUP0
	LDA Player1ColOuter
	STA COLUP1
	JMP ScanLoopCWsyncBypass

ScanLoopC
    STA WSYNC
ScanLoopCWsyncBypass
 
    LDA PF0SpriteA-1,X
    STA PF0 
        
    LDA PF1SpriteA-1,X
    STA PF1
	
    
    LDA PF2SpriteA-1,X
    STA PF2 
   
 
    LDA PF0SpriteB-1,X
    STA PF0 
    
	NOP
	
    LDA PF1SpriteB-1,X
    STA PF1
	
	NOP
	NOP
	
	
    
    LDA PF2SpriteB-1,X
    STA PF2
	
    
    
EndLineC

	DEX
    DEY
    BNE ScanLoopC ; keep going til we run out of scanlines  	
	
    LDA #2      ; a = 2, will use that for VBLANK (make output invisible for overscan)  
    STA WSYNC     	
    STA VBLANK  ; disable output

; OVERSCAN START
	
	LDA #33 ; 2,112 CPU cycles, what will we ever do with the time???
	STA TIM64T	
	
	; Music shit


StartBeatSwitcher
	LDA #%00100000 ; P1 Down
	BIT SWCHA
	BEQ ChangeBeatDown
	JMP StartBeatChannel
ChangeBeatDown
	LDA ActiveBeatData
	ADC #1
	CMP #4
	BCC DoneSelectBeat
	LDA #1
	JMP DoneSelectBeat
DoneSelectBeat
	STA ActiveBeatData
	CMP #1
	BEQ SetActiveBeatA
	CMP #2
	BEQ SetActiveBeatB
	CMP #3
	BEQ SetActiveBeatC
SetActiveBeatA
	LDA BeatDataALen
	STA BeatPosCounter
	JMP DoneSetBeat
SetActiveBeatB
	LDA BeatDataBLen
	STA BeatPosCounter
	JMP DoneSetBeat
SetActiveBeatC
	LDA BeatDataCLen
	STA BeatPosCounter
DoneSetBeat
	LDA #1
	STA BeatDelayCounter
	
StartBeatChannel
	DEC BeatDelayCounter
	BNE BeatPlayNothingRelay
	LDA #%00000100 ; P2 Left
	BIT SWCHA
	BEQ PlayKickRelay
	LDA #%00001000 ; P2 Right
	BIT SWCHA
	BEQ PlaySnareRelay
	LDA #%00000010 ; P2 Down
	BIT SWCHA
	BEQ PlayHatClosedRelay
	LDA #%00000001 ; P2 Up
	BIT SWCHA
	BEQ PlayHatOpenRelay
	DEC BeatPosCounter
	BNE NoResetBeatPosCounter
	LDA ActiveBeatData
	CMP #1
	BEQ UseBeatChannelALen
	CMP #2
	BEQ UseBeatChannelBLen
	CMP #3
	BEQ UseBeatChannelCLen
UseBeatChannelALen
	LDA BeatDataALen
	STA BeatPosCounter
	JMP NoResetBeatPosCounter
UseBeatChannelBLen
	LDA BeatDataBLen
	STA BeatPosCounter
	JMP NoResetBeatPosCounter
UseBeatChannelCLen
	LDA BeatDataCLen
	STA BeatPosCounter
NoResetBeatPosCounter
	LDY BeatPosCounter
	LDA ActiveBeatData
	CMP #1
	BEQ UseBeatChannelA
	CMP #2
	BEQ UseBeatChannelB
	CMP #3
	BEQ UseBeatChannelC
UseBeatChannelA
	LDA BeatControlDataA-1,Y
	JMP ChooseBeatInstrument
UseBeatChannelB
	LDA BeatControlDataB-1,Y
	JMP ChooseBeatInstrument
UseBeatChannelC
	LDA BeatControlDataC-1,Y
	JMP ChooseBeatInstrument
PlayKickRelay
	LDA #1
	JMP ChooseBeatInstrument
PlaySnareRelay
	LDA #2
	JMP ChooseBeatInstrument
PlayHatClosedRelay
	LDA #3
	JMP ChooseBeatInstrument
PlayHatOpenRelay
	LDA #4
	JMP ChooseBeatInstrument
BeatPlayNothingRelay
	JMP BeatPlayNothing
ChooseBeatInstrument
	CMP #0
	BEQ BeatChannelSilence
	CMP #1
	BEQ PlayKickDrum
	CMP #2
	BEQ PlaySnareDrum
	CMP #3
	BEQ PlayHatClosed
	CMP #4
	BEQ PlayHatOpen
	CMP #100
	BCS BeatChannelSilenceMulti
BeatPlayNothing
	JMP DoneBeatChannel
PlayKickDrum
	LDA #15
	STA AUDC0
	LDA #30
	STA AUDF0
	LDA #15
	STA AUDV0
	LDA #3
	STA BeatDelayCounter
	JMP DoneBeatChannel
PlaySnareDrum
	LDA #15
	STA AUDC0
	LDA #6
	STA AUDF0
	LDA #8
	STA AUDV0
	LDA #2
	STA BeatDelayCounter
	JMP DoneBeatChannel
PlayHatClosed
	LDA #8
	STA AUDC0
	LDA #0
	STA AUDF0
	LDA #6
	STA AUDV0
	LDA #1
	STA BeatDelayCounter
	JMP DoneBeatChannel
PlayHatOpen
	LDA #8
	STA AUDC0
	LDA #1
	STA AUDF0
	LDA #6
	STA AUDV0
	LDA #3
	STA BeatDelayCounter
	JMP DoneBeatChannel
BeatChannelSilenceMulti
	SBC #100
	STA BeatDelayCounter
BeatChannelSilence
	LDA #0
	STA AUDV0
DoneBeatChannel

StartNoteSwitcher
	LDA #%00010000 ; P1 Down
	BIT SWCHA
	BEQ ChangeNoteDown
	JMP DoneNoteSwitcher
ChangeNoteDown
	LDA ActiveNoteData
	ADC #1
	CMP #4
	BCC DoneSelectNote
	LDA #1
	JMP DoneSelectNote
DoneSelectNote
	STA ActiveNoteData
	CMP #1
	BEQ SetActiveNoteA
	CMP #2
	BEQ SetActiveNoteB
	CMP #3
	BEQ SetActiveNoteC
SetActiveNoteA
	LDA NoteDataALen
	STA NotePosCounter
	JMP DoneSetNote
SetActiveNoteB
	LDA NoteDataBLen
	STA NotePosCounter
	JMP DoneSetNote
SetActiveNoteC
	LDA NoteDataCLen
	STA NotePosCounter
DoneSetNote
	LDA #1
	STA NoteDelayCounter
DoneNoteSwitcher


	LDA INPT4 ; P1 Fire
	BMI DoneChangeInstrument
ChangeInstrument
	LDA NoteInstrumentPointer
	ADC #1
	CMP #8
	BCS ResetInstrumentPointer
	STA NoteInstrumentPointer
	CMP #1
	BEQ UseSaw
	CMP #2
	BEQ UseEngine
	CMP #3
	BEQ UseSquare
	CMP #4
	BEQ UseBass
	CMP #5
	BEQ UseLogBuzz
	CMP #6
	BEQ UseNoise
	CMP #7
	BEQ UseLead
	CMP #8
	BEQ UseBuzz
ResetInstrumentPointer
	LDA #0
	STA NoteInstrumentPointer
UseSaw
	LDA #1
	STA NoteInstrumentValue
	JMP DoneChangeInstrument
UseEngine
	LDA #3
	STA NoteInstrumentValue
	JMP DoneChangeInstrument
UseSquare
	LDA #4
	STA NoteInstrumentValue
	JMP DoneChangeInstrument
UseBass
	LDA #6
	STA NoteInstrumentValue
	JMP DoneChangeInstrument
UseLogBuzz
	LDA #7
	STA NoteInstrumentValue
	JMP DoneChangeInstrument
UseNoise
	LDA #8
	STA NoteInstrumentValue
	JMP DoneChangeInstrument
UseLead
	LDA #12
	STA NoteInstrumentValue
	JMP DoneChangeInstrument
UseBuzz
	LDA #15
	STA NoteInstrumentValue
DoneChangeInstrument
	
	LDA #%01000000 ; P1 Left
	BIT SWCHA
	BEQ LeftActive
	LDA #0
	STA LeftFreqDiv
	JMP DoneLeftEffect
LeftActive
	LDA NoteInstrumentValue
	STA AUDC1
	LDA #15
	STA AUDV1
	DEC LeftFreqChangeTimer
	BNE SkipNote
	LDA LeftFreqDiv
	ADC #1
	CMP #31
	BCC LeftEffectUnderMax
	LDA #31
LeftEffectUnderMax
	STA LeftFreqDiv
	STA AUDF1
	LDA #1
	STA LeftFreqChangeTimer
	JMP SkipNote
DoneLeftEffect

	LDA #%10000000 ; P1 Right
	BIT SWCHA
	BEQ RightActive
	LDA #32
	STA RightFreqDiv
	JMP DoneRightEffect
RightActive
	LDA NoteInstrumentValue
	STA AUDC1
	LDA #15
	STA AUDV1
	DEC RightFreqChangeTimer
	BNE SkipNote
	LDA RightFreqDiv
	SBC #1
	CMP #10
	BCS RightEffectOverMin
	LDA #10
RightEffectOverMin
	STA RightFreqDiv
	STA AUDF1
	LDA #2
	STA RightFreqChangeTimer
	JMP DoneNoteChannel
DoneRightEffect

StartNoteChannel
	DEC NoteDelayCounter
	BNE DoneNoteChannel
	DEC NotePosCounter
	BNE NoResetNotePosCounter
	LDA ActiveNoteData
	CMP #1
	BEQ UseNoteChannelALen
	CMP #2
	BEQ UseNoteChannelBLen
	CMP #3
	BEQ UseNoteChannelCLen
SkipNote
	JMP DoneNoteChannel
UseNoteChannelALen
	LDA NoteDataALen
	STA NotePosCounter
	JMP NoResetNotePosCounter
UseNoteChannelBLen
	LDA NoteDataBLen
	STA NotePosCounter
	JMP NoResetNotePosCounter
UseNoteChannelCLen
	LDA NoteDataCLen
	STA NotePosCounter
NoResetNotePosCounter
	LDY NotePosCounter
	LDA ActiveNoteData
	CMP #1
	BEQ UseNoteChannelA
	CMP #2
	BEQ UseNoteChannelB
	CMP #3
	BEQ UseNoteChannelC
UseNoteChannelA
	LDA NoteControlDataA-1,Y
	JMP SetNoteChannel
UseNoteChannelB
	LDA NoteControlDataB-1,Y
	JMP SetNoteChannel
UseNoteChannelC
	LDA NoteControlDataC-1,Y
SetNoteChannel
	STA Numerator
	LDA #10
	STA Denominator
	JSR div10
	STA NoteDelayCounter
	LDA Numerator
	CMP #24
	BMI NoSilence
	LDA #0
	STA AUDV1
	JMP DoneNoteChannel
NoSilence
	STA AUDF1
	LDA NoteInstrumentValue
	STA AUDC1
	LDA #10
	STA AUDV1
DoneNoteChannel

	LDA FrameCounter
	SBC #1
	STA FrameCounter

	

; OVERSCAN END
OverScanWait
	LDA INTIM
    BNE OverScanWait
	STA WSYNC
    JMP  MainLoop
	
randomize
	LDA rand1
	ASL
	ROR rand2
	BCC noEor1
	EOR #$DB
noEor1:
	ASL
	ROR rand2
	BCC noEor2
	EOR #$DB
noEor2:
	STA rand1
	EOR rand2
	RTS
	
div10
	LDA #0
	LDX #8
	ASL Numerator
div10L1
	ROL
	CMP Denominator
	BCC div10L2
	SBC Denominator
div10L2
	ROL Numerator
	DEX
	BNE div10L1
	RTS
	
	
NoteControlDataA
	.byte #83
	.byte #113
	.byte #143
	.byte #173
	.byte #243
	.byte #209
	.byte #243
	.byte #209	
	.byte #243
	.byte #209
	.byte #243
	.byte #209
	.byte #243
	.byte #209
	.byte #243
	.byte #209	
	.byte #243
	.byte #209
	
NoteControlDataB
	.byte #2
	.byte #12
	.byte #22
	.byte #32
	.byte #42
	.byte #52
	.byte #62
	.byte #72
	.byte #82
	.byte #92
	.byte #102
	.byte #112
	.byte #122
	.byte #132
	.byte #142
	.byte #152
	.byte #162
	.byte #172
	.byte #182
	.byte #192
	.byte #202
	.byte #212
	.byte #222
	.byte #232
	.byte #242
	.byte #232
	.byte #242
	.byte #232
	.byte #242
	.byte #232
	.byte #222
	.byte #212
	.byte #202
	.byte #192
	.byte #182
	.byte #172
	.byte #162
	.byte #152
	.byte #142
	.byte #132
	.byte #122
	.byte #112
	.byte #102
	.byte #92
	.byte #82
	.byte #72
	.byte #62
	.byte #52
	.byte #42
	.byte #32
	.byte #22
	.byte #12
	.byte #2
	.byte #242
	.byte #2
	.byte #242
	.byte #2
	.byte #242
	
NoteControlDataC
	.byte #246
	.byte #246
	.byte #236
	.byte #236
	.byte #246
	.byte #246
	.byte #236
	.byte #248
	.byte #248
	.byte #248
	.byte #236
	.byte #236
	.byte #221
	.byte #211
	.byte #201
	.byte #191
	.byte #181
	.byte #171
	
BeatControlDataA
	.byte #104
	.byte #4
	.byte #104
	.byte #2
	.byte #109
	.byte #1
	.byte #101
	.byte #4
	.byte #103
	.byte #3
	.byte #102
	.byte #2
	.byte #109
	.byte #1
	.byte #109
	.byte #1
	.byte #102
	.byte #3
	.byte #102
	.byte #3
	.byte #104
	.byte #2
	.byte #109
	.byte #1
	.byte #103
	.byte #3
	.byte #103
	.byte #3
	.byte #102
	.byte #2
	.byte #109
	.byte #1
	.byte #109
	.byte #1

BeatControlDataB
	.byte #105
	.byte #3
	.byte #103
	.byte #1
	.byte #105
	.byte #3
	.byte #103
	.byte #1
	.byte #105
	.byte #3
	.byte #105
	.byte #3
	.byte #109
	.byte #1
	.byte #105
	.byte #3
	.byte #105
	.byte #3
	.byte #109
	.byte #1
	.byte #105
	.byte #3
	.byte #105
	.byte #3
	.byte #109
	.byte #1
	.byte #105
	.byte #3
	.byte #105
	.byte #3
	.byte #109
	.byte #1
	.byte #105
	.byte #3
	.byte #105
	.byte #3
	.byte #109
	.byte #1
	.byte #105
	.byte #3
	.byte #105
	.byte #3
	.byte #109
	.byte #1
	.byte #105
	.byte #3
	.byte #105
	.byte #3
	.byte #109
	.byte #1

	
BeatControlDataC
	.byte #103
	.byte #4
	.byte #103
	.byte #4
	.byte #109
	.byte #1
	.byte #109
	.byte #4
	.byte #1
	.byte #106
	.byte #1
	.byte #109
	.byte #4
	.byte #109
	.byte #1
	.byte #109
	.byte #4
	.byte #103
	.byte #1
	.byte #103
	.byte #1



Player0SpeedRange
	.byte #$00
	.byte #$10
	.byte #$20
	.byte #$30
	.byte #$40
	.byte #$50
	.byte #$60
	.byte #$70
	.byte #$80
	.byte #$90
	.byte #$A0
	.byte #$B0
	.byte #$C0
	.byte #$D0
	.byte #$E0
	.byte #$F0
	.byte #$E0
	.byte #$D0
	.byte #$C0
	.byte #$B0
	.byte #$A0
	.byte #$90
	.byte #$80
	.byte #$70
	.byte #$60
	.byte #$50
	.byte #$40
	.byte #$30
	.byte #$20
	.byte #$10
	
Player1SpeedRange
	.byte #$40
	.byte #$50
	.byte #$60
	.byte #$70
	.byte #$80
	.byte #$90
	.byte #$A0
	.byte #$B0
	.byte #$C0
	.byte #$D0
	.byte #$E0
	.byte #$F0
	.byte #$E0
	.byte #$D0
	.byte #$C0
	.byte #$B0
	.byte #$A0
	.byte #$90
	.byte #$80
	.byte #$70
	.byte #$60
	.byte #$50
	.byte #$40
	.byte #$30
	.byte #$20
	.byte #$10
	.byte #$00
	.byte #$10
	.byte #$20
	.byte #$30

RedColors
	.byte #$20
	.byte #$30
	.byte #$22
	.byte #$32
	.byte #$34
	.byte #$32
	.byte #$22
	.byte #$30
	.byte #$20
	.byte #$30
	.byte #$22
	
GrayCycle
	.byte #$00
	.byte #$04
	.byte #$08
	.byte #$0A
	.byte #$0E
	.byte #$0A
	.byte #$08
	.byte #$04
	.byte #$00
	.byte #$04
	.byte #$08
	
PF0SpriteA
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%00110000
    .byte #%00110000
    .byte #%00110000
    .byte #%00110000
    .byte #%00110000
    .byte #%00110000
    .byte #%00110000
    .byte #%00110000
PF0SpriteB
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10110000
    .byte #%10110000
    .byte #%10110000
    .byte #%10110000
    .byte #%10110000
    .byte #%10110000
    .byte #%10110000
    .byte #%10110000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%10100000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%01100000
    .byte #%01100000
    .byte #%01100000
    .byte #%01100000
    .byte #%01100000
    .byte #%01100000
    .byte #%01100000
    .byte #%01100000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
    .byte #%10010000
PF1SpriteA
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00111001
    .byte #%00111001
    .byte #%00111001
    .byte #%00111001
    .byte #%00111001
    .byte #%00111001
    .byte #%00111001
    .byte #%00111001
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%10100010
    .byte #%00100001
    .byte #%00100001
    .byte #%00100001
    .byte #%00100001
    .byte #%00100001
    .byte #%00100001
    .byte #%00100001
    .byte #%00100001
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%10010111
    .byte #%10010111
    .byte #%10010111
    .byte #%10010111
    .byte #%10010111
    .byte #%10010111
    .byte #%10010111
    .byte #%10010111
    .byte #%10010101
    .byte #%10010101
    .byte #%10010101
    .byte #%10010101
    .byte #%10010101
    .byte #%10010101
    .byte #%10010101
    .byte #%10010101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%11010101
    .byte #%11010101
    .byte #%11010101
    .byte #%11010101
    .byte #%11010101
    .byte #%11010101
    .byte #%11010101
    .byte #%11010101
    .byte #%10010110
    .byte #%10010110
    .byte #%10010110
    .byte #%10010110
    .byte #%10010110
    .byte #%10010110
    .byte #%10010110
    .byte #%10010110
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%01110101
    .byte #%01110101
    .byte #%01110101
    .byte #%01110101
    .byte #%01110101
    .byte #%01110101
    .byte #%01110101
    .byte #%01110101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010010
    .byte #%01010010
    .byte #%01010010
    .byte #%01010010
    .byte #%01010010
    .byte #%01010010
    .byte #%01010010
    .byte #%01010010
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%11001110
    .byte #%11001110
    .byte #%11001110
    .byte #%11001110
    .byte #%11001110
    .byte #%11001110
    .byte #%11001110
    .byte #%11001110
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%10001010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
PF1SpriteB
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00101011
    .byte #%00101011
    .byte #%00101011
    .byte #%00101011
    .byte #%00101011
    .byte #%00101011
    .byte #%00101011
    .byte #%00101011
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%00111011
    .byte #%00111011
    .byte #%00111011
    .byte #%00111011
    .byte #%00111011
    .byte #%00111011
    .byte #%00111011
    .byte #%00111011
    .byte #%00101010
    .byte #%00101010
    .byte #%00101010
    .byte #%00101010
    .byte #%00101010
    .byte #%00101010
    .byte #%00101010
    .byte #%00101010
    .byte #%10101011
    .byte #%10101011
    .byte #%10101011
    .byte #%10101011
    .byte #%10101011
    .byte #%10101011
    .byte #%10101011
    .byte #%10101011
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00011000
    .byte #%00011000
    .byte #%00011000
    .byte #%00011000
    .byte #%00011000
    .byte #%00011000
    .byte #%00011000
    .byte #%00011000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%11011100
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%01110111
    .byte #%01110111
    .byte #%01110111
    .byte #%01110111
    .byte #%01110111
    .byte #%01110111
    .byte #%01110111
    .byte #%01110111
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01110100
    .byte #%01110100
    .byte #%01110100
    .byte #%01110100
    .byte #%01110100
    .byte #%01110100
    .byte #%01110100
    .byte #%01110100
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10100101
    .byte #%10101101
    .byte #%10101101
    .byte #%10101101
    .byte #%10101101
    .byte #%10101101
    .byte #%10101101
    .byte #%10101101
    .byte #%10101101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
    .byte #%00100101
PF2SpriteA
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%11001000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10011000
    .byte #%10011000
    .byte #%10011000
    .byte #%10011000
    .byte #%10011000
    .byte #%10011000
    .byte #%10011000
    .byte #%10011000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%10001000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%10101110
    .byte #%10101110
    .byte #%10101110
    .byte #%10101110
    .byte #%10101110
    .byte #%10101110
    .byte #%10101110
    .byte #%10101110
    .byte #%01101010
    .byte #%01101010
    .byte #%01101010
    .byte #%01101010
    .byte #%01101010
    .byte #%01101010
    .byte #%01101010
    .byte #%01101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%10101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%11101010
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00010111
    .byte #%00010111
    .byte #%00010111
    .byte #%00010111
    .byte #%00010111
    .byte #%00010111
    .byte #%00010111
    .byte #%00010111
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%01010101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%10110101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
    .byte #%00010101
PF2SpriteB
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00011101
    .byte #%00011101
    .byte #%00011101
    .byte #%00011101
    .byte #%00011101
    .byte #%00011101
    .byte #%00011101
    .byte #%00011101
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00010100
    .byte #%00001101
    .byte #%00001101
    .byte #%00001101
    .byte #%00001101
    .byte #%00001101
    .byte #%00001101
    .byte #%00001101
    .byte #%00001101
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%01000100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%10100100
    .byte #%01001110
    .byte #%01001110
    .byte #%01001110
    .byte #%01001110
    .byte #%01001110
    .byte #%01001110
    .byte #%01001110
    .byte #%01001110
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000110
    .byte #%00000110
    .byte #%00000110
    .byte #%00000110
    .byte #%00000110
    .byte #%00000110
    .byte #%00000110
    .byte #%00000110
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00000010
    .byte #%00001110
    .byte #%00001110
    .byte #%00001110
    .byte #%00001110
    .byte #%00001110
    .byte #%00001110
    .byte #%00001110
    .byte #%00001110
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%00100010
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%01100100
    .byte #%00101000
    .byte #%00101000
    .byte #%00101000
    .byte #%00101000
    .byte #%00101000
    .byte #%00101000
    .byte #%00101000
    .byte #%00101000
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110
    .byte #%11101110

    .byte #%00000000
    .byte #%00000000
	
AltPF0SpriteA
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
AltPF0SpriteB
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%11010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%00010000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%11110000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
AltPF1SpriteA
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%00000001
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%10001110
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01110000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
AltPF1SpriteB
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%11000000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00111000
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%00100000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%01000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%10000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
AltPF2SpriteA
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000011
    .byte #%00000011
    .byte #%00000011
    .byte #%00000011
    .byte #%00000011
    .byte #%00000011
    .byte #%00000011
    .byte #%00000011
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%11100000
    .byte #%11100000
    .byte #%11100000
    .byte #%11100000
    .byte #%11100000
    .byte #%11100000
    .byte #%11100000
    .byte #%11100000
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%00011100
    .byte #%11110011
    .byte #%11110011
    .byte #%11110011
    .byte #%11110011
    .byte #%11110011
    .byte #%11110011
    .byte #%11110011
    .byte #%11110011
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01010000
    .byte #%01001000
    .byte #%01001000
    .byte #%01001000
    .byte #%01001000
    .byte #%01001000
    .byte #%01001000
    .byte #%01001000
    .byte #%01001000
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%10000010
    .byte #%10000010
    .byte #%10000010
    .byte #%10000010
    .byte #%10000010
    .byte #%10000010
    .byte #%10000010
    .byte #%10000010
    .byte #%00010010
    .byte #%00010010
    .byte #%00010010
    .byte #%00010010
    .byte #%00010010
    .byte #%00010010
    .byte #%00010010
    .byte #%00010010
    .byte #%00110010
    .byte #%00110010
    .byte #%00110010
    .byte #%00110010
    .byte #%00110010
    .byte #%00110010
    .byte #%00110010
    .byte #%00110010
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%11111000
    .byte #%11111000
    .byte #%11111000
    .byte #%11111000
    .byte #%11111000
    .byte #%11111000
    .byte #%11111000
    .byte #%11111000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
AltPF2SpriteB
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00001000
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000100
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000
    .byte #%00000000

    .byte #%00000000
    .byte #%00000000
    org $FFFC
    .word Start
    .word Start 
