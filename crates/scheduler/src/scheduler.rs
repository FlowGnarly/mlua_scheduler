use smol::Executor;

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
