use mlua::prelude::*;

#[derive(Debug)]
pub struct TaskScheduler {
    pub task_lib: LuaTable,
    pub(crate) coroutine_lib: LuaTable,

    pub(crate) run_fn: LuaFunction,
}

impl TaskScheduler {
    pub fn new(lua: &Lua) -> LuaResult<Self> {
        let chunk = lua
            .load(include_str!("init.luau"))
            .set_name("task_scheduler");

        let returned: LuaTable = chunk.call(())?;

        Ok(Self {
            task_lib: returned.get("task")?,
            coroutine_lib: returned.get("coroutine")?,

            run_fn: returned.get("run")?,
        })
    }

    pub fn modify_coroutine_lib(&self, lua: &Lua) -> LuaResult<()> {
        let co: LuaTable = lua.globals().get("coroutine")?;

        for pair in self.coroutine_lib.pairs::<LuaValue, LuaValue>() {
            let (k, v) = pair?;

            co.set(k, v)?;
        }

        Ok(())
    }

    /**
    runs the scheduler once, returning false means all lua threads are finished
     */
    pub fn run(&self) -> LuaResult<bool> {
        self.run_fn.call(())
    }
}
