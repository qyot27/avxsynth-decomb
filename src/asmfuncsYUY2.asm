%include "amd64inc.asm"

SECTION .rodata
ALIGN 8
Mask0 dq 0xFFFF0000FFFF0000
Mask1 dq 0x00FF00FF00FF00FF
Mask2 dq 0x00000000000000FF
Mask3 dq 0x0000000000FF0000
Mask4 dq 0x0000000000FF00FF
MaskFE dq 0xFEFEFEFEFEFEFEFE
MaskFC dq 0xFCFCFCFCFCFCFCFC

SECTION .text
cglobal asm_deinterlaceYUY2
cglobal asm_deinterlace_chromaYUY2
cglobal isse_blend_plane
cglobal isse_interpolate_plane
cglobal mmx_createmask_plane
cglobal mmx_createmask_plane_single
cglobal isse_blend_decimate_plane
cglobal isse_scenechange_32
cglobal isse_scenechange_16
cglobal isse_scenechange_8
cglobal blendYUY2
cglobal interpolateYUY2

;void __declspec(naked) asm_deinterlaceYUY2(const unsigned char *dstp, const unsigned char *p, \
								  const unsigned char *n, unsigned char *fmask, \
								  unsigned char *dmask, int thresh, int dthresh, int row_size)

asm_deinterlaceYUY2:
		mov r10, [rsp+40]
		movd		mm0,[rsp+48] ;// threshold
		movq		mm3,mm0
		psllq		mm3,32
		por			mm3,mm0
		movd		mm4,[rsp+56] ;// dthreshold
		movq		mm5,mm4
		psllq		mm5,32
		por			mm5,mm4
		mov			r11d,[rsp+64]	;// row_size
.xloop:
		pxor		mm4,mm4
		movd		mm0,[rdx]		;// load p
		punpcklbw	mm0,mm4			;// unpack
		movd		mm2,[rcx]		;// load dstp
		punpcklbw	mm2,mm4			;// unpack
		movd		mm1,[r8]		;// load n
		punpcklbw	mm1,mm4			;// unpack
		psubw		mm0,mm2			;// pprev - curr = P
		psubw		mm1,mm2			;// pnext - curr = N
		movq		mm6,[Mask0 wrt rip]
		pandn		mm6,mm0			;// mm6 = 0 | P2 | 0 | P0
		pmaddwd		mm6,mm1			;// mm6 = P2*N2  | P0*N0
		movq		mm0,mm6

		pcmpgtd		mm6,mm3			;// mm6 = P2*N2<T | P0*N0<T
		movq		mm4,mm6			;// save result
		pand		mm6,[Mask2 wrt rip]		;// make 0x000000ff if P0*N0<T
		movq		mm7,mm6			;// move it into result
		psrlq		mm4,32			;// get P2*N2<T
		pand		mm4,[Mask3 wrt rip]		;// make 0x00ff0000 if P2*N2<T
		por			mm7,mm4			;// move it into the result
		movd		[r9],mm7		;// save final result for fmask

		pcmpgtd		mm0,mm5			;// mm0 = P2*N2<DT | P0*N0<DT
		movq		mm4,mm0			;// save result
		pand		mm0,[Mask2 wrt rip]		;// make 0x000000ff if P0*N0<DT
		movq		mm7,mm0			;// move it into result
		psrlq		mm4,32			;// get P2*N2<DT
		pand		mm4,[Mask3 wrt rip]		;// make 0x00ff0000 if P2*N2<DT
		por			mm7,mm4			;// move it into the result
		movq		[r10],mm7			;// save intermediate result

		pxor		mm4,mm4			;// do chroma bytes now
		movd		mm0,[rdx]		;// load p
		punpcklbw	mm0,mm4			;// unpack
		movd		mm1,[r8]		;// load n
		punpcklbw	mm1,mm4			;// unpack
		psubw		mm0,mm2			;// pprev - curr = P
		psubw		mm1,mm2			;// pnext - curr = N
		movq		mm6,[Mask0 wrt rip]
		pand		mm6,mm0			;// mm6 = P3 | 0 | P1| 0
		pmaddwd		mm6,mm1			;// mm6 = P3*N3  | P1*N1
		movq		mm0,mm6

		pcmpgtd		mm0,mm5			;// mm0 = P3*N3<DT | P1*N1<DT
		movq		mm4,mm0			;// save result
		pand		mm0,[Mask4 wrt rip]		;// make 0x00ff00ff if P1*N1<DT
		movq		mm7,mm0			;// move it into result
		psrlq		mm4,32			;// get P3*N3<DT
		pand		mm4,[Mask4 wrt rip]		;// make 0x00ff00ff if P3*N3<DT
		por			mm7,mm4			;// move it into the result
		movd		mm4,[r10]		;// Pick up saved intermediate result
		por			mm4,mm7
		movd		[r10],mm4		;// Save final result for dmask

		add			rcx,4
		add			rdx,4
		add			r8,4
		add			r9,4
		add			r10,4
		dec			r11d
		jnz			.xloop

		emms
		ret

;void __declspec(naked) asm_deinterlace_chromaYUY2(const unsigned char *dstp, const unsigned char *p, \
								  const unsigned char *n, unsigned char *fmask, \
								  unsigned char *dmask, int thresh, int dthresh, int row_size)
asm_deinterlace_chromaYUY2:
		mov			r10d,[rsp+40] ;// dmaskp
		movd		mm0,[rsp+48] ;// threshold
		movq		mm3,mm0
		psllq		mm3,32
		por			mm3,mm0
		movd		mm4,[rsp+56] ;// dthreshold
		movq		mm5,mm4
		psllq		mm5,32
		por			mm5,mm4
		mov			r11d,[rsp+64]	;// row_size
.xloop:
		pxor		mm4,mm4
		movd		mm0,[rdx]		;// load p
		punpcklbw	mm0,mm4			;// unpack
		movd		mm2,[rcx]		;// load dstp
		punpcklbw	mm2,mm4			;// unpack
		movd		mm1,[r8]		;// load n
		punpcklbw	mm1,mm4			;// unpack
		psubw		mm0,mm2			;// pprev - curr = P
		psubw		mm1,mm2			;// pnext - curr = N
		movq		mm6,[Mask0 wrt rip]
		pandn		mm6,mm0			;// mm6 = 0 | P2 | 0 | P0
		pmaddwd		mm6,mm1			;// mm6 = P2*N2  | P0*N0
		movq		mm0,mm6

		pcmpgtd		mm6,mm3			;// mm6 = P2*N2<T | P0*N0<T
		movq		mm4,mm6			;// save result
		pand		mm6,[Mask2 wrt rip]		;// make 0x000000ff if P0*N0<T
		movq		mm7,mm6			;// move it into result
		psrlq		mm4,32			;// get P2*N2<T
		pand		mm4,[Mask3 wrt rip]		;// make 0x00ff0000 if P2*N2<T
		por			mm7,mm4			;// move it into the result
		movd		[r9],mm7		;// save intermediate result

		pcmpgtd		mm0,mm5			;// mm0 = P2*N2<DT | P0*N0<DT
		movq		mm4,mm0			;// save result
		pand		mm0,[Mask2 wrt rip]		;// make 0x000000ff if P0*N0<DT
		movq		mm7,mm0			;// move it into result
		psrlq		mm4,32			;// get P2*N2<DT
		pand		mm4,[Mask3 wrt rip]		;// make 0x00ff0000 if P2*N2<DT
		por			mm7,mm4			;// move it into the result
		movd		[r10d],mm7		;// save intermediate result

		pxor		mm4,mm4			;// do chroma bytes now
		movd		mm0,[rdx]		;// load p
		punpcklbw	mm0,mm4			;// unpack
		movd		mm1,[r8]		;// load n
		punpcklbw	mm1,mm4			;// unpack
		psubw		mm0,mm2			;// pprev - curr = P
		psubw		mm1,mm2			;// pnext - curr = N
		movq		mm6,[Mask0 wrt rip]
		pand		mm6,mm0			;// mm6 = P3 | 0 | P1| 0
		pmaddwd		mm6,mm1			;// mm6 = P3*N3  | P1*N1
		movq		mm0,mm6

		pcmpgtd		mm6,mm3			;// mm6 = P3*N3<T | P1*N1<T
		movq		mm4,mm6			;// save result
		pand		mm6,[Mask4 wrt rip]		;// make 0x00ff00ff if P1*N1<T
		movq		mm7,mm6			;// move it into result
		psrlq		mm4,32			;// get P3*N3<T
		pand		mm4,[Mask4 wrt rip]		;// make 0x00ff00ff if P3*N3<T
		por			mm7,mm4			;// move it into the result
		movd		mm4,[r9]		;// Pick up saved intermediate result
		por			mm4,mm7
		movd		[r9],mm4		;// Save final result for fmask

		pcmpgtd		mm0,mm5			;// mm0 = P3*N3<DT | P1*N1<DT
		movq		mm4,mm0			;// save result
		pand		mm0,[Mask4 wrt rip]		;// make 0x00ff00ff if P1*N1<DT
		movq		mm7,mm0			;// move it into result
		psrlq		mm4,32			;// get P3*N3<DT
		pand		mm4,[Mask4 wrt rip]		;// make 0x00ff00ff if P3*N3<DT
		por			mm7,mm4			;// move it into the result
		movd		mm4,[r10d]		;// Pick up saved intermediate result
		por			mm4,mm7
		movd		[r10d],mm4		;// Save final result for dmask

		add			rcx, byte 4
		add			rdx, byte 4
		add			r8, byte 4
		add			r9, byte 4
		add			r10d, byte 4
		dec			r11d
		jnz			.xloop

		emms
		ret

;void isse_blend_plane(BYTE* org, BYTE* src_prev, BYTE* src_next, BYTE* dmaskp, int w);
isse_blend_plane:
    xor eax, eax
    mov r10d, [rsp+40]
    pcmpeqb mm7,mm7  ;// All 1's
    jmp .loop_test
align 16
.loopback
    movq mm0,[rcx+rax]  ;// src
    movq mm1,[rdx+rax]  ;// next
    movq mm2,[r8+rax]  ;// prev
    movq mm4,[r9+rax]  ;// mask
    ;// Blend pixels
    pavgb mm1,mm2  ;// Blend prev & next 50/50
     movq mm5,mm4  ;// copy mask
    pavgb mm1,mm0  ;// Now correctly blended.
     pxor mm5,mm7  ;// Inv mask
    pand mm1, mm4
     pand mm0, mm5
;//		movq mm1,mm0  // Enable debug viewing of mask!
    por mm1,mm0
    movq [rcx+rax],mm1
    add eax, byte 8
.loop_test
    cmp eax,r10d
    jl .loopback
    emms
	ret

;void isse_interpolate_plane(BYTE* org, BYTE* src_prev, BYTE* src_next, BYTE* dmaskp, int w)
isse_interpolate_plane:
    xor eax, eax
    mov r10d, [rsp+40]
    pcmpeqb mm7,mm7  ;// All 1's
    jmp .loop_test
align 16
.loopback
    movq mm4,[r9+rax]  ;// mask
    movq mm0,[rcx+rax]  ;// src
    movq mm1,[rdx+rax]  ;// next
    movq mm2,[r8+rax]  ;// prev
    movq mm5,mm4  ;// copy mask
    ;// Blend pixels
    pavgb mm1,mm2  ;// Blend prev & next 50/50
     pxor mm5,mm7  ;// Inv mask
    pand mm1, mm4
     pand mm0, mm5
;//		movq mm1,mm0  // Enable debug viewing of mask!
    por mm1,mm0
    movq [rcx+rax],mm1
    add eax, byte 8
.loop_test
    cmp eax, r10d
    jl .loopback
    emms
	ret
	
;void mmx_createmask_plane(const BYTE* srcp, const BYTE* prev_p, const BYTE* next_p, BYTE* fmaskp, \
							BYTE* dmaskp, int threshold, int dthreshold, int row_size)
mmx_createmask_plane:
    xor eax, eax
    pxor mm7, mm7
	movq mm6, [rsp+48]
	pavgw mm6, mm7
	movq2dq xmm0, mm6
	punpcklwd mm6, mm6
	pshuflw xmm0, xmm0, 0xAA
    mov r11d, [rsp+64]
    punpckldq mm6,mm6   
    jmp .loop_test
align 16
.loopback:
    movq mm0, [rcx+rax]  ;// src
     movq mm1, [rdx+rax]  ;// prev
    movq mm3,mm0
     movq mm4,mm1
    movq mm2, [r8+rax]  ;// next
     punpcklbw mm0,mm7  ;// src low
    punpckhbw mm3,mm7  ;// src high
      movq mm5,mm2
    punpcklbw mm1,mm7  ;// prev low
     punpckhbw mm4,mm7  ;// prev high
    punpcklbw mm2,mm7  ;// next low
     punpckhbw mm5,mm7  ;// next high
    movdq2q mm7, xmm0
    psubsw mm1, mm0  ;// p-src low
     psubsw mm2, mm0  ;// n-src low
		psraw mm1,1       ;// Avoid multiply signed overflow
     psubsw mm4, mm3   ;// p-src high
    pmullw mm1,mm2  ;// multiply low
     psubsw mm5, mm3  ;// n-src high
		 psraw mm4,1       ;// Avoid multiply signed overflow
     movq mm0,mm1         ;// copy low result
    pmullw mm4,mm5    ;// multiply high
;     punpckldq mm7,mm7   // 
     movq mm3,[Mask1 wrt rip]
    movq mm2,mm4          ;// copy high result
     pcmpgtw mm0,mm6      ;// Threshold low  0 if mult result is less than t
    pcmpgtw mm2,mm6     ;// Threshold high
     pcmpgtw mm1,mm7      ;// D-Threshold low
    pcmpgtw mm4,mm7     ;// D-Threshold high
     pand mm0,mm3
    pand mm1,mm3
     pand mm2,mm3
    pand mm4,mm3
     packuswb mm0,mm2   ;// fmask
    packuswb mm1,mm4    ;// dmask
     movq [r9+rax],mm0
   movq [r10+rax],mm1
    pxor mm7, mm7
    add eax, byte 8
.loop_test:
    cmp eax, r11d
    jl .loopback
		emms
		ret
		
;void mmx_createmask_plane_single(const BYTE* srcp, const BYTE* prev_p, const BYTE* next_p, BYTE* dmaskp, \
									int dthreshold, int row_size)
mmx_createmask_plane_single:
    xor eax, eax
    mov r11d, [rsp+48]
    pxor mm7, mm7
    movd mm6, [rsp+40]
    pavgw mm6, mm7
    punpcklwd mm6, mm6
    punpckldq mm6,mm6   
    jmp .loop_test
align 16
.loopback
    movq mm0, [rcx+rax]  ;// src
     movq mm1, [rdx+rax]  ;// prev
    movq mm3,mm0
     movq mm4,mm1
    movq mm2, [r8+rax]  ;// next
     punpcklbw mm0,mm7  ;// src low
    punpckhbw mm3,mm7  ;// src high
      movq mm5,mm2
    punpcklbw mm1,mm7  ;// prev low
     punpckhbw mm4,mm7  ;// prev high
    punpcklbw mm2,mm7  ;// next low
     punpckhbw mm5,mm7  ;// next high
    psubsw mm1, mm0  ;// p-src low
     psubsw mm2, mm0  ;// n-src low
		psraw mm1,1				;// Avoid multiply signed overflow
     psubsw mm4, mm3   ;// p-src high
    pmullw mm1,mm2  ;// multiply low
     psubsw mm5, mm3  ;// n-src high
		psraw mm4,1				;// Avoid multiply signed overflow
     movq mm0,mm1         ;// copy low result
    pmullw mm4,mm5    ;// multiply high
     movq mm3, [Mask1 wrt rip]
    movq mm2,mm4          ;// copy high result
     pcmpgtw mm1,mm6      ;// D-Threshold low
    pcmpgtw mm4,mm6     ;// D-Threshold high
     pand mm0,mm3
    pand mm1,mm3
     pand mm2,mm3
    pand mm4,mm3
    packuswb mm1,mm4    ;// dmask
    movq [r9+rax],mm1
    add eax, byte 8
.loop_test
    cmp eax, r11d
    jl .loopback		
    emms
	ret
	
; void isse_blend_decimate_plane(BYTE* dst, BYTE* src,  BYTE* src_next, int w, \
								int h, int dst_pitch, int src_pitch, int src_next_pitch)
isse_blend_decimate_plane:
	push r12
	pushreg r12
	push r13
	pushreg r13
	endprolog
;  if (!h) return;  // Height == 0 - avoid silly crash.
	cmp dword [rsp+40+16], byte 0
	jz .end

; r10d    mov ebx, h
	mov r10d, [rsp+40+16]
	mov r11d, [rsp+48+16]
	mov r12d, [rsp+56+16]
	mov r13d, [rsp+64+16]
; r9d    mov ecx, w
; rdx    mov esi, src
; rcx    mov edi, dst
; r8    mov edx, src_next
align 16
.yloop
    xor eax, eax  ;// Width counter
    jmp .loop_test
align 16
.loopback
    movq mm0,[rdx+rax]  ;// src
    movq mm1,[r8+rax]  ;// next
    ;// Blend pixels
    pavgb mm1,mm0  ;// Blend prev & src 50 / 50
    movq [rcx+rax],mm1
    add eax, byte 8
.loop_test
    cmp eax, r9d
    jl .loopback
    add rcx, r11
    add rdx, r12
    add r8, r13
    dec r10d
    jnz .yloop
    emms
.end
	pop r13
	pop r12
	ret								
	endfunc
	
;int isse_scenechange_32(const BYTE* c_plane, const BYTE* tplane, int height, int width, \
							int c_pitch, int t_pitch)
isse_scenechange_32:
	push rbx
	pushreg rbx
	endprolog
	and r9b, byte 0xE0

    xor ebx,ebx     ;// Height
    pxor mm5,mm5  ;// Maximum difference
	movsxd r10, dword [rsp+8+40]
	movsxd r11, dword [rsp+8+48]
    pxor mm6,mm6   ;// We maintain two sums, for better pairablility
    pxor mm7,mm7
    jmp .yloopover
align 16
.yloop
    inc ebx
    add rdx, r11     ;// add pitch to both planes
    add rcx, r10
.yloopover
    cmp ebx, r8d
    jge .endframe
    xor eax,eax     ;// Width
align 16
.xloop
    cmp eax, r9d
    jge .yloop

    movq mm0,[rcx+rax]
     movq mm2,[rcx+rax+8]
    movq mm1,[rdx+rax]
     movq mm3,[rdx+rax+8]
    psadbw mm0,mm1    ;// Sum of absolute difference
     psadbw mm2,mm3
    paddd mm6,mm0     ;// Add...
     paddd mm7,mm2
    movq mm0,[rcx+rax+16]
     movq mm2,[rcx+rax+24]
    movq mm1,[rdx+rax+16]
     movq mm3,[rdx+rax+24]
    psadbw mm0,mm1
     psadbw mm2,mm3
    paddd mm6,mm0
     paddd mm7,mm2

    add eax, byte 32
    jmp .xloop
.endframe
    paddd mm7,mm6
    movd eax,mm7
    emms
    pop rbx
	ret
	endfunc
	
;int isse_scenechange_16(const BYTE* c_plane, const BYTE* tplane, int height, int width, \
							int c_pitch, int t_pitch)
isse_scenechange_16:
	push rbx
	pushreg rbx
	endprolog
	and r9b, byte 0xF0

    xor ebx,ebx     ;// Height
    pxor mm5,mm5  ;// Maximum difference
	movsxd r10, dword [rsp+8+40]
	movsxd r11, dword [rsp+8+48]
    pxor mm6,mm6   ;// We maintain two sums, for better pairablility
    pxor mm7,mm7
    jmp .yloopover
align 16
.yloop
    inc ebx
    add rdx,r11     ;// add pitch to both planes
    add rcx,r10
.yloopover
    cmp ebx, r8d
    jge .endframe
    xor eax,eax     ;// Width
align 16
.xloop
    cmp eax, r9d    
    jge .yloop

    movq mm0,[rcx+rax]
     movq mm2,[rcx+rax+8]
    movq mm1,[rdx+rax]
     movq mm3,[rdx+rax+8]
    psadbw mm0,mm1    ;// Sum of absolute difference
     psadbw mm2,mm3
    paddd mm6,mm0     ;// Add...
     paddd mm7,mm2

    add eax, byte 16
    jmp .xloop
.endframe
    paddd mm7,mm6
    movd eax,mm7
    emms
    pop rbx
	ret
	endfunc
	
;int isse_scenechange_8(const BYTE* c_plane, const BYTE* tplane, int height, int width, \
							int c_pitch, int t_pitch)
isse_scenechange_8:
	push rbx
	pushreg rbx
	endprolog
	and r9b, 0xF8

    xor ebx,ebx     ;// Height
    pxor mm5,mm5  ;// Maximum difference
	movsxd r10, dword [rsp+8+40]
	movsxd r11, dword [rsp+8+48]
    pxor mm6,mm6   ;// We maintain two sums, for better pairablility
    pxor mm7,mm7
    jmp .yloopover
align 16
.yloop
    inc ebx
    add rdx,r11     ;// add pitch to both planes
    add rcx,r10
.yloopover
    cmp ebx, r8d
    jge .endframe
    xor eax,eax     ;// Width
align 16
.xloop
    cmp eax,r9d    
    jge .yloop

    movq mm0,[rcx+rax]
    movq mm1,[rdx+rax]
    psadbw mm0,mm1    ;// Sum of absolute difference
    paddd mm6,mm0     ;// Add...

    add eax, byte 8
    jmp .xloop
.endframe
    movd eax, mm6
    emms
    pop rbx
    ret
    endfunc
    
;int __declspec(naked) blendYUY2(const unsigned char *dstp, const unsigned char *cprev, \
								const unsigned char *cnext, unsigned char *finalp, \
								unsigned char *dmaskp, int count)
blendYUY2:
		mov r10, [rsp+40]
		mov r11d, [rsp+48]

		movq		mm7,[MaskFE wrt rip]
		movq		mm6,[MaskFC wrt rip]
.xloop
		cmp qword [r10], byte 0
		jnz			.blend
		movq		mm0,[rcx]
		movq		[r9],mm0
		jmp			.skip
.blend
		movq		mm0,[rcx]		;// load dstp
		pand		mm0,mm7

		movq		mm1,[rdx]		;// load cprev
		pand		mm1,mm6

		movq		mm2,[r8]		;// load cnext
		pand		mm2,mm6

		psrlq		mm0,1
		psrlq		mm1,2
		psrlq       mm2,2
		paddusb		mm0,mm1
		paddusb		mm0,mm2
		movq		[r9],mm0
.skip
		add			rcx, byte 8
		add			rdx, byte 8
		add			r8, byte 8
		add			r9, byte 8
		add			r10, byte 8
		dec			r11d
		jnz			.xloop

		emms
		ret
		
;int __declspec(naked) interpolateYUY2(const unsigned char *dstp, const unsigned char *cprev, \
								const unsigned char *cnext, unsigned char *finalp, \
								unsigned char *dmaskp, int count)
interpolateYUY2:
		mov r10, [rsp+40]
		mov r11d, dword [rsp+48]
		movq		mm7, [MaskFE wrt rip]
.xloop
		cmp qword [r10], 0
		jnz			.blend
		movq		mm0,[rcx]
		movq		[r9],mm0
		jmp			.skip
.blend
		movq		mm0,[rdx]		;// load cprev
		pand		mm0,mm7

		movq		mm1,[r8]		;// load cnext
		pand		mm1,mm7

		psrlq		mm0,1
		psrlq       mm1,1
		paddusb		mm0,mm1
		movq		[r9],mm0
.skip
		add			rcx, byte 8
		add			rdx, byte 8
		add			r8, byte 8
		add			r9, byte 8
		add			r10, byte 8
		dec			r11d
		jnz			.xloop

		emms
		ret