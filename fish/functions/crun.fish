function crun --wraps='CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-pc-linux-gnu-gcc cargo run' --wraps='cargo run' --description 'alias crun=cargo run'
    cargo run $argv
end
