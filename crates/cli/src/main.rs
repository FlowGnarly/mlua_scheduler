use clap::Parser;
use mlua_scheduler::scheduler::Scheduler;
use std::{env::consts::OS, path::PathBuf};

#[derive(Debug, Parser)]
struct Cli {
    path: PathBuf,
}

fn main() {
    let cli = Cli::parse();
    let lua = mlua::Lua::new();
    let scheduler = Scheduler::new();

    lua.globals()
        .set("_OS", OS.to_lowercase())
        .expect("Failed to set _OS global");

    let scheduler_task = smol::spawn(async move {
        scheduler.run().await.expect("Scheduler failed");
    })
    .fallible();

    smol::block_on(scheduler_task);
}
