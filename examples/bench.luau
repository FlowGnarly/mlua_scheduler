-- for testing
local task = task or require("@lune/task")

local started = os.clock()

local amount = 100000
local batches = 10
local per_batch = amount / batches

local threads = {}
for current = 1, batches do
	local thread = coroutine.running()

	print(`Batch {current} / {batches}`)

	for i = 1, per_batch do
		table.insert(
			threads,
			task.spawn(function()
				task.wait(0.1)

				if i == per_batch then
					assert(coroutine.status(thread) == "suspended")
					task.spawn(thread)
				end
			end)
		)
	end

	coroutine.yield()
end
local took = os.clock() - started
print(`Spawned {amount} sleeping threads in {took}s`)
