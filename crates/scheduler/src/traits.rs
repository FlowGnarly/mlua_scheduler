use smol::Task;
use std::future::Future;

pub trait LuaSchedulerMethods {
    fn spawn_future<T>(&self, future: impl Future<Output = T> + Send + 'static) -> Task<T>
    where
        T: Send + 'static;
}

impl LuaSchedulerMethods for mlua::Lua {
    fn spawn_future<T>(&self, future: impl Future<Output = T> + Send + 'static) -> Task<T>
    where
        T: Send + 'static,
    {
        crate::spawn_future(self, future)
    }
}
