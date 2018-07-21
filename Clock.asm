;--------------------------------------
;2018年春汇编综合实验
;题目:DOS下常驻内存时钟程序
;学生:吴嘉权  完成时间：2018/6/6
;-------------------------------------
ASSUME CS:CODE
CODE SEGMENT
;常驻内存的时钟程序	 
CLOCK:
		;调用函数,GET_TIME获取时间
		;REFRESH将获取的时间显示到显示屏的缓存区上.
		CALL GET_TIME
		CALL REFRESH
		;中断程序结束,返回
		IRET

;从cmos中获取新的时间
;并写到data区里面.仅获取时/分/秒
GET_TIME PROC 
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		PUSH SI
		PUSH DI
		
		MOV AX,CS
		MOV DS,AX
		
		LEA BX,DATA
		MOV SI,0
		MOV DI,8
		MOV CX,3
	;
	L1:
		PUSH CX
		
		MOV AL,[BX+DI]
		OUT 70H,AL
		IN AL,71H
		
		;并分别写入AX,高位为十位,低位为个位
	    ;将获取的时间BCD码转化为ASCII码
		MOV AH,AL
		MOV CL,4
		SHR AH,CL
		AND AL,0FH
		ADD AX,3030H 
		            
		MOV [BX+SI],AX
		
		ADD SI,3
		INC DI
		POP CX
		LOOP L1
		
		POP DI
		POP SI
		POP DX
		POP CX
		POP BX
		POP AX
		RET
GET_TIME ENDP

;从data区中读取新的时间,并重新写入显示屏的缓存区
;并给每次读取的数字赋予新的显示效果
REFRESH PROC
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DI
		PUSH SI
		PUSH DS
		PUSH ES
		
		MOV AX,CS
		MOV DS,AX
		MOV AX,0B800H
		MOV ES,AX
		MOV SI,0
		MOV DI,144;在第一行倒数第8个像素开始显示
		
		;显示两个冒号
		;设置为闪烁且为白底黑字
		MOV AL,':'
		MOV AH,11111000B 
		MOV ES:[DI+4],AX
		MOV ES:[DI+10],AX
		
		;显示数字
		;效果根据数字来变化,不闪烁
		LEA BX,DATA
		MOV CX,3
L2:
		PUSH CX
		
		MOV CX,[BX+SI]
		MOV ES:[DI],CH
		MOV ES:[DI+2],CL
		OR CL,01111000B;设置白底
		AND CL,01111111B;设置不闪烁
		
		MOV BYTE PTR ES:[DI+1],CL  
		MOV BYTE PTR ES:[DI+3],CL 
		
		ADD DI,6
		ADD SI,3
		
		POP CX
		LOOP L2
		
		POP ES
		POP DS
		POP SI
		POP DI
		POP CX
		POP BX
		POP AX
		RET
REFRESH ENDP

;DATA区
;存放时间和读取cmos端口需要的数字
;OLD存放旧的1CH入口,用于卸载时钟程序时还原1CH
DATA:  
         DB "??:??:??"
		 DB 4,2,0
OLD      DW ?,?


;程序运行的主函数
MAIN:
        ;检查安装情况,即时钟程序是否常驻内存
		;是,则卸载,并还原旧的1CH
		;否,则安装时钟程序
		MOV AX,351CH
		INT 21H
		CMP BX,OFFSET CLOCK
		JNE SET
		
;卸载,恢复旧的1CH程序
RECOVER:
		MOV AX,ES:OLD+2
		MOV DS,AX
		MOV DX,ES:OLD
		MOV AX,251CH
		INT 21H

		;清除显示屏上写的数字
		;写入黑底黑字覆盖
		MOV AX,0B800H
		MOV ES,AX
		MOV SI,144
		MOV AX,0
		MOV CX,8
	L3:
		MOV ES:[SI],AX
		ADD SI,2
		LOOP L3
		
		JMP MAIN_END

;保存旧的1CH入口并设置新的入口
;让时钟常驻内存
SET:		
		;保存旧入口
		MOV AX,351CH
		INT 21H
		MOV CS:OLD,BX
		MOV CS:OLD+2,ES
		;设置新的入口
		MOV AX,CS
		MOV DS,AX
		MOV DX,OFFSET CLOCK
		MOV AX,251CH
		INT 21H
		;设置驻留集大小,(x+15)/16+16(psp)
		MOV DX,OFFSET MAIN
		ADD DX,15
		MOV CL,4
		SHR DX,CL
		ADD DX,16
MAIN_END:		
		MOV AX,3100H
		INT 21H

CODE ENDS
END MAIN