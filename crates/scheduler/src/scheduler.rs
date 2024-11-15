use mlua_task_library::TaskScheduler;
use smol::Executor;

#[derive(Debug)]
pub struct Scheduler {
    pub executor: Executor<'static>,
    pub task: TaskScheduler,
}

impl Scheduler {
    pub fn new(lua: &mlua::Lua) -> mlua::Result<Self> {
        Ok(Self {
            executor: Executor::new(),
            task: TaskScheduler::new(lua)?,
        })
    }

    pub async fn run(&self) -> mlua::Result<()> {
        loop {
            'tick: for _ in 0..10 {
                if !self.executor.try_tick() {
                    break 'tick;
                }
            }

            if self.executor.is_empty() && !self.task.run()? {
                break;
            };
        }

        Ok(())
    }
}
