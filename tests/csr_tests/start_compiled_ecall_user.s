        .text
        
        .globl  _start

        .org    0x00000000
trap_vector_reset:      
        
_start:
        j       reset_vector

        .org    0x00000100
trap_vector_exception:
        j       exception_handler

        .org    0x0000010c
trap_vector_machine_software_int:
        j       trap_vector_reset

        .org    0x00000110
trap_vector_user_timer_int:
        j       trap_vector_reset

        .org    0x0000011c
trap_vector_machine_timer_int:
        j       trap_vector_reset

        .org    0x00000120
trap_vector_user_external_int:
        j       trap_vector_reset

        .org    0x0000012c
trap_vector_machine_external_int:
        j       trap_vector_reset

        .org    0x00000200
        
reset_vector:   
        la      t0, trap_vector_exception
        ori     t0, t0, 1               # Vectored trap mode
        csrw    mtvec, t0
        .option push
        .option norelax
        la      gp, __global_pointer$   # Initialize gp
        .option pop
        li      sp, 0x00020000          # Initialize sp
        li      s0, 0                   # Initialize fp
        call    main
        j       trap_vector_reset

exception_handler:
        addi    sp, sp, -16
        sd      t0, 0(sp)       # save registers to be used in handler
        sd      t1, 8(sp)
        csrr    t0, mcause
        bltz    t0, trap_vector_reset   # User software interrupt, same vector as exceptions
        slli    t0, t0, 2
        jr      %lo(exception_table)(t0)
        
exception_table:
        j       exception_handler_instr_addr_misaligned
        j       exception_handler_not_implemented        # instr_access_fault
        j       exception_handler_illegal_instr
        j       exception_handler_breakpoint
        j       exception_handler_load_addr_misaligned
        j       exception_handler_not_implemented       # load_access_fault
        j       exception_handler_store_addr_misaligned
        j       exception_handler_not_implemented       # store_access_fault
        j       exception_handler_user_env_call
        j       exception_handler_not_implemented       # supervisor_env_call
        j       exception_handler_not_implemented       # reserved
        j       exception_handler_machine_env_call

exception_handler_not_implemented:
        j       trap_vector_reset
        
exception_handler_instr_addr_misaligned:
        j       trap_vector_reset
        
exception_handler_illegal_instr:
        j       trap_vector_reset
        
exception_handler_breakpoint:
        j       trap_vector_reset
        
exception_handler_load_addr_misaligned:
        j       trap_vector_reset
        
exception_handler_store_addr_misaligned:
        j       trap_vector_reset
        
exception_handler_user_env_call:        # fall through to machine env call, same operations required

exception_handler_machine_env_call:     
        li      t0, ~0x1800             # mask to clear MPP bits
        csrr    t1, mstatus
        and     t1, t1, t0
        andi    a0, a0, 0x3             # clear any extraneous bits
        slli    a0, a0, 11              # shift to position for MPP
        or      t1, t1, a0
        csrrw   a0, mstatus, t1         # rewrite MPP and get old mstatus
        srli    a0, a0, 11              # extract old MPP bits
        andi    a0, a0, 0x3
        csrr    t0, mepc                # increment mepc to point to next instruction
        addi    t0, t0, 4
        csrw    mepc, t0
        ld      t0, 0(sp)               # restore saved registers
        ld      t1, 8(sp)
        addi    sp, sp, 16
        mret
        

        .globl  set_prv
set_prv:
        ecall           # pass a0 to ecall handler (user or machine mode)
        ret
        
