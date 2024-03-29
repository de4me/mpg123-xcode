#include "mangle.h"

#if defined(OPT_3DNOWEXT)

#define MPL_DCT64 FUNC(INT123_dct64_3dnowext)
#define SYNTH_NAME ASM_NAME(INT123_synth_1to1_3dnowext_asm)
#include "synth_sse3d.h"

#if defined(PIC) && defined(__APPLE__)
	.section __IMPORT,__jump_table,symbol_stubs,self_modifying_code+pure_instructions,5
FUNC(INT123_dct64_3dnowext):
	.indirect_symbol ASM_NAME(INT123_dct64_3dnowext)
	hlt ; hlt ; hlt ; hlt ; hlt
#endif

NONEXEC_STACK

#endif
