use scheduler::Scheduler;
use smol::Task;
use std::{future::Future, sync::Arc};

pub mod scheduler;
pub mod traits;

fn spawn_future<T>(lua: &mlua::Lua, future: impl Future<Output = T> + Send + 'static) -> Task<T>
where
    T: Send + 'static,
{
    let scheduler = Arc::clone(&lua.app_data_ref::<Arc<Scheduler>>().unwrap());

    scheduler.executor.spawn(future)
}
