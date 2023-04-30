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

aRow DWORD ?  ; A的行数
aCol DWORD ?  ; A的列数
bRow DWORD ?  ; B的行数
bCol DWORD ?  ; B的列数
tmpRow DWORD ?  ; 暂存的行数 
tmpCol DWORD ?  ; 暂存的列数

;矩阵按行存储
mA DWORD 20 DUP(?)
mB DWORD 20 DUP(?)
mC DWORD 20 DUP(?)  

;矩阵指针
pA PDWORD OFFSET mA  ; DWORD指针
pB PDWORD OFFSET mB
pC PDWORD OFFSET mC
tP PDWORD ?  ; 临时指针
rpA PDWORD ? ; 暂存pA
rpB PDWORD ? ; 暂存pB
tmp DWORD ?  ; 暂存循环次数
offsetB DWORD ?  ; pB向下一列移动的偏移量

File1 BYTE 50 DUP(?)  ; A矩阵文件
File2 BYTE 50 DUP(?)  ; B矩阵文件
File3 BYTE 50 DUP(?)  ; C矩阵文件

infoA BYTE '矩阵A文件:',0
infoB BYTE '矩阵B文件:',0
infoC BYTE '矩阵C文件:',0
errorInfo BYTE '不满足乘法条件',0
resultInfo BYTE '计算结果如下:',0

buffer BYTE 50 DUP(?)  ; 文件缓冲区
fileHandle HANDLE ?  ; 句柄

.code
main PROC

	;输入A文件名
	mov edx,OFFSET infoA
	call WriteString
	mov edx,OFFSET File1
	mov ecx,SIZEOF File1
	call ReadString

	; 输入B文件名
	mov edx,OFFSET infoB
	call WriteString
	mov edx,OFFSET File2
	mov ecx,SIZEOF File2
	call ReadString

	; 输入C文件名
	mov edx,OFFSET infoC
	call WriteString
	mov edx,OFFSET File3
	mov ecx,SIZEOF File3
	call ReadString

	; 读入A矩阵
	mov edx, OFFSET File1
	call readMatrix
	mov tP,OFFSET mA
	call loadMatrix
	mov eax,tmpRow	
	mov aRow,eax
	mov eax,tmpCol
	mov aCol,eax

	
	; 读入B矩阵
	mov edx, OFFSET File2
	call readMatrix
	mov tP,OFFSET mB
	call loadMatrix
	mov eax,tmpRow
	mov bRow,eax
	mov eax,tmpCol
	mov bCol,eax

	; 不满足乘法行列条件
	mov eax,aCol
	mov ebx,bRow
	.IF eax != ebx
		mov edx,OFFSET errorInfo
		call WriteString
		INVOKE ExitProcess,0
	.ENDIF

	; 计算pB下移的偏移量
	mov eax,bCol
	mov ebx,TYPE mB
	mul ebx
	mov offsetB,eax

	; 矩阵乘法
	call calRows

	; 在屏幕输出
	call dumpMatrix

	; 结果输出到屏幕
	mov edx,OFFSET resultInfo
	call WriteString
	mov al,13
	call WriteChar
	mov al,10
	call WriteChar
	mov edx,OFFSET buffer
	call WriteString

	; 写入文件
	mov edx,OFFSET File3
	call writeMatrix

main ENDP


;1.读文件到缓冲区————————————————————————————————————————————————————
readMatrix PROC

	;打开文件读入,edx == OFFSET File1
	call OpenInputFile
	cmp eax, INVALID_HANDLE_VALUE	;检查文件打开失败？
    je end_prog
	mov fileHandle,eax				;保存文件句柄

	; 文件读入缓冲区
	mov edx,OFFSET buffer
	mov ecx,BUFFER_SIZE
	call ReadFromFile
	mov buffer[eax],0				;返回字节数
	cmp eax, 0						;检查文件读取失败？
    je end_prog

	;检查以下输出buffer区的内容
	;mov edx, OFFSET buffer
    ;call WriteString

	;关闭文件
	mov	eax,fileHandle
	call CloseFile

	ret
readMatrix ENDP

;2.loadMatrix，将缓冲区字符串解析为矩阵，存储到指定数组中————————————————————————————
loadMatrix PROC 

	; 从缓冲区读字符串,转为DWORD,应确保栈顶为矩阵数组头的偏移量
	; esi 变址寄存器;edx 暂存和; ecx 暂存被乘数
	mov tmpRow,0
	mov tmpCol,0
	mov esi,0
	mov eax,0
	mov ebx,0	;暂存和
	mov edx,0
	
	;遍历buffer数组
	.WHILE buffer[esi] != 0
		;空格：列数加1，写入数组，指针后移
		.IF buffer[esi] == 20h 
			.IF tmpRow<1  
				inc tmpCol			 ;列数加一
			.ENDIF
			mov edi,tP
			mov [edi],ebx			 ;写入到数组
			mov ebx,0
			add tP,TYPE DWORD        ;指针后移
			inc esi
		
		;换行符0ah：行数加一，写入数组，指针后移
		.ELSEIF buffer[esi] == 0ah
			inc tmpRow				 ;行数加一
			mov edi,tP
			mov [edi],ebx			 ;写入到数组
			mov ebx,0
			add tP,TYPE DWORD        ;指针后移
			add esi,1
		
		.ELSE
			; ASCII码除以30h余数是对应的数字值
			movzx eax,buffer[esi]	;读入的字符存入edi,确保高位被清零,一个字节或字中的数据零扩展成双字节或双字中的数据
			mov ecx,30h				;EAX/ECX --> 商EAX 余数EDX
			div ecx  
			mov edi,edx				;余数存入edi
			mov eax,10				;EBX*10:中暂存的和乘以10 --> EAX
			mul ebx
			mov ebx,eax				;存回EBX
			add ebx,edi				;存到ebx寄存器
			inc esi
		.ENDIF
	.ENDW
	inc tmpCol
	ret
loadMatrix ENDP


;3.计算A矩阵的一行分别乘B矩阵的每一列 (二重循环)——————————————————————————
calOneRow PROC

	mov ecx,bCol ;设置外层循环数
	mov eax,pA	 
	mov rpA,eax  ;暂存矩阵A每一行的指针，为了和B每一列再进行计算

;一行乘全部列，ecx==bcol
L1:				
	mov eax,pB	 
	mov rpB,eax  ;暂存矩阵B当前列的指针，为了指向下一列
	mov ebx,0    ;累加和
	mov tmp,ecx

	;设置内层循环数aCol，b行，计算单个数字
	mov ecx,aCol 
	
	;内层循环，一行*一列，ecx==acol,a横着移动，b竖着移动
	L2:          
		mov esi,pA
		mov eax,[esi]	 ;pA所指的数eax
		mov esi,pB
		mov edx,[esi]	 ;pB所指的数edx
		mul edx			 ;pA所指的数乘pB所指的数
		add ebx,eax		 ;累加部分和ebx

		add pA,TYPE mA   ;pA横向移动
		mov eax,offsetB
		add pB,eax		 ;pB纵向移动
		loop L2			 ;a的列数

	mov edi,pC			 ;一次内层循环之后，写入一次c矩阵
	mov [edi],ebx		 ;写到C矩阵
	add pC,TYPE mC		 ;pC后移
	
	mov eax,rpA		
	mov pA,eax			 ;恢复pA,每一行的地址，为了和B每一列再进行计算
	mov eax,rpB
	add eax,TYPE mB
	mov pB,eax			 ;pB指向下一列
	mov ecx,tmp			
	loop L1				 ;恢复外层循环值bCol

	;外层循环结束——————
	mov eax,OFFSET mB
	mov pB,eax			 ;pB重新指向B矩阵
	ret
calOneRow ENDP

;//4.对矩阵A的每一行调用calOneRow , 得出最终结果————————————————————————————
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

;5.writeMatrix从缓冲区输出到文件, 设edx中已有文件路径
writeMatrix PROC
	
	call CreateOutputFile
	mov edx,OFFSET buffer
	mov ecx,tmp ; 此处是文件长度
	call WriteToFile
	call CloseFile 
	ret
writeMatrix ENDP


;6.DWORD数组转成字符串并写入缓冲区
dumpMatrix PROC USES esi

	mov ebx,bCol
	mov eax,aRow
	mul ebx
	mov ecx,eax  ;C矩阵总元素数

	mov tmpCol,0
	mov pC,OFFSET mC
	mov esi,0

L1:
	mov edx,pC
	mov eax,[edx]
	inc tmpCol

	mov ebx,10    ; ebx为除数
	mov edx,0
	mov edi,0     ; 计数,记录压栈次数
    jmp TESTING

FORLOOP:
    xor edx,edx   ; 异或操作(清零edx),32位做除法时余数存放在edx，使用前要清零
    div ebx       ; eax = eax/10 商在eax中，余数是edx
    add dl, 30h   ; 将数字转换成字符
	push dx
    inc edi

TESTING:

	;字符转为数字
    cmp eax,0		; 被除数存放在eax
    jne FORLOOP		; 非零则跳转

	;
	.WHILE edi > 0  
		pop dx
		mov buffer[esi],dl
		inc esi
		dec edi
	.ENDW

	mov buffer[esi],20h ; 写空格
	inc esi

	mov edx,bCol

	.IF tmpCol == edx
		; 写入回车换行符
		mov buffer[esi],0dh
		inc esi
		mov buffer[esi],0ah
		inc esi
		mov tmpCol,0
	.ENDIF

	add pC,TYPE mC     ; 指针后移,指向下一个 DWORD数
	loop L1

	mov buffer[esi],0  ; 写入结束符
	mov tmp,esi

	ret
dumpMatrix ENDP

end_prog:
    call Crlf
    exit

END main

