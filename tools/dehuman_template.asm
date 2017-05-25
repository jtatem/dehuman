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
	LDA #10
	STA SpeedChangeCounter

	; init music counters

	LDA #{BeatDataALen}
	STA BeatDataALen
	LDA #{BeatDataBLen}
	STA BeatDataBLen
	LDA #{BeatDataCLen}
	STA BeatDataCLen

	LDA #{NoteDataALen}
	STA NoteDataALen
	LDA #{NoteDataBLen}
	STA NoteDataBLen
	LDA #{NoteDataCLen}
	STA NoteDataCLen
	
	LDA #1
	STA ActiveNoteData
	STA ActiveBeatData
	STA NoteDelayCounter
	STA BeatDelayCounter
	
	LDA BeatDataALen
	STA BeatPosCounter
	LDA NoteDataALen
	STA NotePosCounter

	; LDA #0
	; STA LeftFreqDiv
	; STA RightFreqDiv
	LDA #2
	STA LeftFreqChangeTimer
	STA RightFreqChangeTimer

	LDA #4
	STA NoteInstrumentPointer
	LDA #6
	STA NoteInstrumentValue


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
	; LDA #0
	; STA RangeLowerBoundDir
	LDA #1
	STA RangeUpperBoundDir
	STA RangeUpperBoundSpeed
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
    LDA  #0      ; a = 0, need 0 for disabling VSYNC
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
	LDA Player0Speed
	ADC #2
	STA Player0Speed
	LDA Player1Speed
	SBC #6
	STA Player1Speed
	LDA #10
	STA SpeedChangeCounter
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
	JMP SetUpperBoundSpeed
UpperBoundSpeed2
	LDA #2
	JMP SetUpperBoundSpeed
UpperBoundSpeed3
	LDA #3
	JMP SetUpperBoundSpeed
UpperBoundSpeed4
	LDA #4
	JMP SetUpperBoundSpeed
UpperBoundSpeed5
	LDA #5
SetUpperBoundSpeed
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
	JMP SetLowerBoundSpeed
LowerBoundSpeed2
	LDA #4
	JMP SetLowerBoundSpeed
LowerBoundSpeed3
	LDA #6
	JMP SetLowerBoundSpeed
LowerBoundSpeed4
	LDA #8
	JMP SetLowerBoundSpeed
LowerBoundSpeed5
	LDA #10
SetLowerBoundSpeed
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
	LDA RangeLowerBound
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
	ORA RandSpriteC
    STA PF0

    LDA AltPF1SpriteB-1,X
	ORA RandSpriteA
    STA PF1


    LDA AltPF2SpriteB-1,X
	ORA RandSpriteB
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
	JMP SetActiveBeatLen
SetActiveBeatB
	LDA BeatDataBLen
	JMP SetActiveBeatLen
SetActiveBeatC
	LDA BeatDataCLen
SetActiveBeatLen
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
	JMP SetBeatDataLen
UseBeatChannelBLen
	LDA BeatDataBLen
	JMP SetBeatDataLen
UseBeatChannelCLen
	LDA BeatDataCLen
SetBeatDataLen
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
	JMP SetActiveNoteLen
SetActiveNoteB
	LDA NoteDataBLen
	JMP SetActiveNoteLen
SetActiveNoteC
	LDA NoteDataCLen
SetActiveNoteLen
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
	JMP SetNoteInstrumentValue
UseEngine
	LDA #3
	JMP SetNoteInstrumentValue
UseSquare
	LDA #4
	JMP SetNoteInstrumentValue
UseBass
	LDA #6
	JMP SetNoteInstrumentValue
UseLogBuzz
	LDA #7
	JMP SetNoteInstrumentValue
UseNoise
	LDA #8
	JMP SetNoteInstrumentValue
UseLead
	LDA #12
	JMP SetNoteInstrumentValue
UseBuzz
	LDA #15
SetNoteInstrumentValue
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
	JMP SetNoteChannelLen
UseNoteChannelBLen
	LDA NoteDataBLen
	JMP SetNoteChannelLen
UseNoteChannelCLen
	LDA NoteDataCLen
SetNoteChannelLen
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
	JSR divide
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

divide
	LDA #0
	LDX #8
	ASL Numerator
divL1
	ROL
	CMP Denominator
	BCC divL2
	SBC Denominator
divL2
	ROL Numerator
	DEX
	BNE divL1
	RTS


{NoteData}

{BeatData}

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

{ForegroundImage}

{BackgroundImage}

    org $FFFC
    .word Start
    .word Start
