use clap::Parser;
use mlua_scheduler::scheduler::Scheduler;
use std::{env::consts::OS, path::PathBuf, sync::Arc};

#[derive(Debug, Parser)]
struct Cli {
    path: PathBuf,
}

fn main() -> mlua::Result<()> {
    let cli = Cli::parse();
    let lua = mlua::Lua::new();

    let scheduler = Arc::new(Scheduler::new(&lua)?);
    let scheduler_inner = Arc::clone(&scheduler);

    lua.globals().set("_OS", OS.to_lowercase())?;
    lua.globals().set("task", &scheduler.task.task_lib)?;
    scheduler.task.modify_coroutine_lib(&lua)?;

    let script_contents = std::fs::read_to_string(&cli.path)?;
    let chunk = lua
        .load(script_contents)
        .set_name(cli.path.to_string_lossy());
    let thread = lua.create_thread(chunk.into_function()?)?;

    scheduler
        .task
        .task_lib
        .get::<mlua::Function>("spawn")?
        .call::<()>(thread.clone())?;

    let scheduler_task = smol::spawn(async move {
        scheduler_inner.run().await?;

        Ok::<_, mlua::Error>(())
    })
    .fallible();

    smol::block_on(scheduler_task);

    Ok(())
}
