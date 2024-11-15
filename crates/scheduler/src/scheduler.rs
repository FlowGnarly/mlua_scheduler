use smol::Executor;
use std::sync::Arc;

#[derive(Debug)]
pub struct Scheduler {
    pub executor: Executor<'static>,
}

impl Default for Scheduler {
    fn default() -> Self {
        Self {
            executor: Executor::new(),
        }
    }
}

impl Scheduler {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn setup(self, lua: &mlua::Lua) -> Arc<Self> {
        let arc = Arc::new(self);
        lua.set_app_data(Arc::clone(&arc));
        arc
    }

    pub async fn run(&self) -> mlua::Result<()> {
        loop {
            'tick: for _ in 0..10 {
                if !self.executor.try_tick() {
                    break 'tick;
                }
            }

            if self.executor.is_empty() {
                break;
            };
        }

        Ok(())
    }
}
