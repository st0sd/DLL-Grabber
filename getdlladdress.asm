.386                      
.model flat, stdcall       
option casemap :none       
get_dll_address proto
.data
ntdll BYTE 06Eh, 00h, 074h, 00h, 064h, 00h, 06Ch, 00h, 06Ch, 00h, 02Eh, 00h, 064h, 00h, 06Ch, 00h, 06Ch, 00h, 00h, 00h
kernel32 BYTE 04BH, 00h, 045h, 00h, 052h, 00h, 04Eh, 00h, 045h, 00h, 04Ch, 00h, 033h, 00h, 032h, 00h, 02Eh, 00h, 044h, 00h, 04Ch, 00h, 04Ch, 00h, 00h, 00h

.code
; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
;			Simple masm function to find loaded dll base address 
;			without calling GetModuleHandle(). Will return 0 
;			on failure.
;«««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««	

main proc				
    	push ebp
    	mov ebp, esp

    	push offset kernel32
	call get_dll_address
	
	pop ebp
	ret
main endp

get_dll_address proc
	ASSUME FS:NOTHING
	push ebp
	mov ebp, esp
	
    	mov eax, FS:[030h]   ;Get PEB address
    	
          
    	mov esi, [eax+12]    ;Get PEB_LDR_DATA pointer
    	mov ecx, [esi+0Ch]   ;Get LDR_DATA_TABLE_ENTRY pointer

    	find_dll_loop:
	
	
    	mov edi, [esp+8]	;load edi with our search string
    	mov ecx, [ecx]      ;next entry of linked list
	
	test ecx, ecx		;if linked list entry is null, search failed
	je fail
	
    	mov edx, [ecx+030h]	;pointer to unicode string of dll name
	
	test edx, edx		;if string is null, search failed
	je fail

	comp_string:
   	cmp WORD PTR [edx], 0
	je find_dll_loop	;If we have reached the end of the peb string, go to the next entry in list
	mov bx, WORD PTR [edi]
	cmp bx, 00
	je find_dll_loop	;if we have reached the end of the search string, go to the next entry in list
	cmp bx, WORD PTR [edx]
	jne find_dll_loop	;if characters are different, go to the next linked entry
	
	
	add edi, 2			;increment string pointer for search string (unicode so 2 bytes)
	add edx, 2			;increment string pointer for dll name
	
	mov bx, WORD PTR [edi]	

	or bx, WORD PTR [edx];OR search and dllstring together 
	test bx, bx			;if they are both zero, we have reached both strings and they match
	jz end_
	
	jmp comp_string		;loop again
	
	end_:
	mov eax, [ecx+018h]	;Get the dll base address 
	pop ebp
	ret 4
	
	
	fail:
	xor eax, eax
	pop ebp
	ret 4
get_dll_address endp
end main

