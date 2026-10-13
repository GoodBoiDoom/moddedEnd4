function rbuild --wraps='CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-pc-linux-gnu-gcc cargo run' --wraps='CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-pc-linux-gnu-gcc cargo build' --description 'alias rbuild=CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-pc-linux-gnu-gcc cargo build'
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-pc-linux-gnu-gcc cargo build $argv
end
