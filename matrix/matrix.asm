INCLUDE Irvine32.inc
.386
.model flat,stdcall
.stack 4096

ExitProcess PROTO,dwExitCode:DWORD
CreateOutputFile PROTO
CloseFile PROTO
ReadFromFile PROTO	
OpenInputFile PROTO
ReadString PROTO
WriteString PROTO
WriteDec PROTO
WriteChar PROTO
PDWORD TYPEDEF PTR DWORD 
BUFFER_SIZE=50

.data

aRow DWORD ?  ; A������
aCol DWORD ?  ; A������
bRow DWORD ?  ; B������
bCol DWORD ?  ; B������
tmpRow DWORD ?  ; �ݴ������ 
tmpCol DWORD ?  ; �ݴ������

;�����д洢
mA DWORD 20 DUP(?)
mB DWORD 20 DUP(?)
mC DWORD 20 DUP(?)  

;����ָ��
pA PDWORD OFFSET mA  ; DWORDָ��
pB PDWORD OFFSET mB
pC PDWORD OFFSET mC
tP PDWORD ?  ; ��ʱָ��
rpA PDWORD ? ; �ݴ�pA
rpB PDWORD ? ; �ݴ�pB
tmp DWORD ?  ; �ݴ�ѭ������
offsetB DWORD ?  ; pB����һ���ƶ���ƫ����

File1 BYTE 50 DUP(?)  ; A�����ļ�
File2 BYTE 50 DUP(?)  ; B�����ļ�
File3 BYTE 50 DUP(?)  ; C�����ļ�

infoA BYTE '����A�ļ�:',0
infoB BYTE '����B�ļ�:',0
infoC BYTE '����C�ļ�:',0
errorInfo BYTE '������˷�����',0
resultInfo BYTE '����������:',0

buffer BYTE 50 DUP(?)  ; �ļ�������
fileHandle HANDLE ?  ; ���

.code
main PROC

	;����A�ļ���
	mov edx,OFFSET infoA
	call WriteString
	mov edx,OFFSET File1
	mov ecx,SIZEOF File1
	call ReadString

	; ����B�ļ���
	mov edx,OFFSET infoB
	call WriteString
	mov edx,OFFSET File2
	mov ecx,SIZEOF File2
	call ReadString

	; ����C�ļ���
	mov edx,OFFSET infoC
	call WriteString
	mov edx,OFFSET File3
	mov ecx,SIZEOF File3
	call ReadString

	; ����A����
	mov edx, OFFSET File1
	call readMatrix
	mov tP,OFFSET mA
	call loadMatrix
	mov eax,tmpRow	
	mov aRow,eax
	mov eax,tmpCol
	mov aCol,eax

	
	; ����B����
	mov edx, OFFSET File2
	call readMatrix
	mov tP,OFFSET mB
	call loadMatrix
	mov eax,tmpRow
	mov bRow,eax
	mov eax,tmpCol
	mov bCol,eax

	; ������˷���������
	mov eax,aCol
	mov ebx,bRow
	.IF eax != ebx
		mov edx,OFFSET errorInfo
		call WriteString
		INVOKE ExitProcess,0
	.ENDIF

	; ����pB���Ƶ�ƫ����
	mov eax,bCol
	mov ebx,TYPE mB
	mul ebx
	mov offsetB,eax

	; ����˷�
	call calRows

	; ����Ļ���
	call dumpMatrix

	; ����������Ļ
	mov edx,OFFSET resultInfo
	call WriteString
	mov al,13
	call WriteChar
	mov al,10
	call WriteChar
	mov edx,OFFSET buffer
	call WriteString

	; д���ļ�
	mov edx,OFFSET File3
	call writeMatrix

main ENDP


;1.���ļ�����������������������������������������������������������������������������������������������������������������
readMatrix PROC

	;���ļ�����,edx == OFFSET File1
	call OpenInputFile
	cmp eax, INVALID_HANDLE_VALUE	;����ļ���ʧ�ܣ�
    je end_prog
	mov fileHandle,eax				;�����ļ����

	; �ļ����뻺����
	mov edx,OFFSET buffer
	mov ecx,BUFFER_SIZE
	call ReadFromFile
	mov buffer[eax],0				;�����ֽ���
	cmp eax, 0						;����ļ���ȡʧ�ܣ�
    je end_prog

	;����������buffer��������
	;mov edx, OFFSET buffer
    ;call WriteString

	;�ر��ļ�
	mov	eax,fileHandle
	call CloseFile

	ret
readMatrix ENDP

;2.loadMatrix�����������ַ�������Ϊ���󣬴洢��ָ�������С�������������������������������������������������������
loadMatrix PROC 

	; �ӻ��������ַ���,תΪDWORD,Ӧȷ��ջ��Ϊ��������ͷ��ƫ����
	; esi ��ַ�Ĵ���;edx �ݴ��; ecx �ݴ汻����
	mov tmpRow,0
	mov tmpCol,0
	mov esi,0
	mov eax,0
	mov ebx,0	;�ݴ��
	mov edx,0
	
	;����buffer����
	.WHILE buffer[esi] != 0
		;�ո�������1��д�����飬ָ�����
		.IF buffer[esi] == 20h 
			.IF tmpRow<1  
				inc tmpCol			 ;������һ
			.ENDIF
			mov edi,tP
			mov [edi],ebx			 ;д�뵽����
			mov ebx,0
			add tP,TYPE DWORD        ;ָ�����
			inc esi
		
		;���з�0ah��������һ��д�����飬ָ�����
		.ELSEIF buffer[esi] == 0ah
			inc tmpRow				 ;������һ
			mov edi,tP
			mov [edi],ebx			 ;д�뵽����
			mov ebx,0
			add tP,TYPE DWORD        ;ָ�����
			add esi,1
		
		.ELSE
			; ASCII�����30h�����Ƕ�Ӧ������ֵ
			movzx eax,buffer[esi]	;������ַ�����edi,ȷ����λ������,һ���ֽڻ����е���������չ��˫�ֽڻ�˫���е�����
			mov ecx,30h				;EAX/ECX --> ��EAX ����EDX
			div ecx  
			mov edi,edx				;��������edi
			mov eax,10				;EBX*10:���ݴ�ĺͳ���10 --> EAX
			mul ebx
			mov ebx,eax				;���EBX
			add ebx,edi				;�浽ebx�Ĵ���
			inc esi
		.ENDIF
	.ENDW
	inc tmpCol
	ret
loadMatrix ENDP


;3.����A�����һ�зֱ��B�����ÿһ�� (����ѭ��)����������������������������������������������������
calOneRow PROC

	mov ecx,bCol ;�������ѭ����
	mov eax,pA	 
	mov rpA,eax  ;�ݴ����Aÿһ�е�ָ�룬Ϊ�˺�Bÿһ���ٽ��м���

;һ�г�ȫ���У�ecx==bcol
L1:				
	mov eax,pB	 
	mov rpB,eax  ;�ݴ����B��ǰ�е�ָ�룬Ϊ��ָ����һ��
	mov ebx,0    ;�ۼӺ�
	mov tmp,ecx

	;�����ڲ�ѭ����aCol��b�У����㵥������
	mov ecx,aCol 
	
	;�ڲ�ѭ����һ��*һ�У�ecx==acol,a�����ƶ���b�����ƶ�
	L2:          
		mov esi,pA
		mov eax,[esi]	 ;pA��ָ����eax
		mov esi,pB
		mov edx,[esi]	 ;pB��ָ����edx
		mul edx			 ;pA��ָ������pB��ָ����
		add ebx,eax		 ;�ۼӲ��ֺ�ebx

		add pA,TYPE mA   ;pA�����ƶ�
		mov eax,offsetB
		add pB,eax		 ;pB�����ƶ�
		loop L2			 ;a������

	mov edi,pC			 ;һ���ڲ�ѭ��֮��д��һ��c����
	mov [edi],ebx		 ;д��C����
	add pC,TYPE mC		 ;pC����
	
	mov eax,rpA		
	mov pA,eax			 ;�ָ�pA,ÿһ�еĵ�ַ��Ϊ�˺�Bÿһ���ٽ��м���
	mov eax,rpB
	add eax,TYPE mB
	mov pB,eax			 ;pBָ����һ��
	mov ecx,tmp			
	loop L1				 ;�ָ����ѭ��ֵbCol

	;���ѭ������������������
	mov eax,OFFSET mB
	mov pB,eax			 ;pB����ָ��B����
	ret
calOneRow ENDP

;//4.�Ծ���A��ÿһ�е���calOneRow , �ó����ս����������������������������������������������������������
calRows PROC
	mov ecx,aRow
L:
	push ecx       
	call calOneRow

	mov eax,aCol
	mov edx,TYPE mA
	mul edx
	add pA,eax

	pop ecx    
	loop L
	ret
calRows ENDP

;5.writeMatrix�ӻ�����������ļ�, ��edx�������ļ�·��
writeMatrix PROC
	
	call CreateOutputFile
	mov edx,OFFSET buffer
	mov ecx,tmp ; �˴����ļ�����
	call WriteToFile
	call CloseFile 
	ret
writeMatrix ENDP


;6.DWORD����ת���ַ�����д�뻺����
dumpMatrix PROC USES esi

	mov ebx,bCol
	mov eax,aRow
	mul ebx
	mov ecx,eax  ;C������Ԫ����

	mov tmpCol,0
	mov pC,OFFSET mC
	mov esi,0

L1:
	mov edx,pC
	mov eax,[edx]
	inc tmpCol

	mov ebx,10    ; ebxΪ����
	mov edx,0
	mov edi,0     ; ����,��¼ѹջ����
    jmp TESTING

FORLOOP:
    xor edx,edx   ; ������(����edx),32λ������ʱ���������edx��ʹ��ǰҪ����
    div ebx       ; eax = eax/10 ����eax�У�������edx
    add dl, 30h   ; ������ת�����ַ�
	push dx
    inc edi

TESTING:

	;�ַ�תΪ����
    cmp eax,0		; �����������eax
    jne FORLOOP		; ��������ת

	;
	.WHILE edi > 0  
		pop dx
		mov buffer[esi],dl
		inc esi
		dec edi
	.ENDW

	mov buffer[esi],20h ; д�ո�
	inc esi

	mov edx,bCol

	.IF tmpCol == edx
		; д��س����з�
		mov buffer[esi],0dh
		inc esi
		mov buffer[esi],0ah
		inc esi
		mov tmpCol,0
	.ENDIF

	add pC,TYPE mC     ; ָ�����,ָ����һ�� DWORD��
	loop L1

	mov buffer[esi],0  ; д�������
	mov tmp,esi

	ret
dumpMatrix ENDP

end_prog:
    call Crlf
    exit

END main

