--!strict
local co_resume = coroutine.resume
local scheduler = {
	threads = {} :: { thread },
	args = {} :: { [thread]: { unknown } },
	results = {} :: { [thread]: ThreadResult },
}

type ThreadResult = {
	success: true,
	value: unknown,
} | {
	success: false,
	msg: string,
}

function scheduler.removeThread(thread: thread): boolean
	local index = table.find(scheduler.threads, thread)

	if index then
		table.remove(scheduler.threads, index)
	end

	return if index then true else false
end

function scheduler.runThread(thread: thread, ...: unknown): ()
	if coroutine.status(thread) == "dead" then
		scheduler.removeThread(thread)

		return error("cannot resume dead coroutine", 0)
	end

	local success, result = co_resume(thread, ...)

	if result == pending then
		-- thread is still polling
		return
	else
		scheduler.removeThread(thread)
	end

	if success == true then
		scheduler.results[thread] = {
			success = true,
			value = result,
		}
	elseif success == false then
		scheduler.results[thread] = {
			success = false,
			msg = result,
		}
	end
end

local task = {}

function task.spawn(f: thread | (...unknown) -> ...unknown, ...: unknown): thread
	local thread = if typeof(f) == "thread" then f else coroutine.create(f)

	table.insert(scheduler.threads, thread)

	-- run immediately
	scheduler.runThread(thread, ...)

	return thread
end

function task.defer(f: thread | (...unknown) -> ...unknown, ...: unknown): thread
	local thread = if typeof(f) == "thread" then f else coroutine.create(f)

	table.insert(scheduler.threads, thread)
	scheduler.args[thread] = { ... }

	return thread
end

function task.wait(secs: number?)
	wait(secs)
end

function task.delay(secs: number, f: thread | (...unknown) -> ...unknown, ...: unknown): thread
	local thread = if typeof(f) == "thread" then f else coroutine.create(f)

	scheduler.args[thread] = { ... }

	return task.defer(function()
		task.wait(secs)
		table.insert(scheduler.threads, thread)
	end)
end

function task.cancel(thread: thread): ()
	scheduler.removeThread(thread)
end

return {
	task = task,
	coroutine = {
		close = task.cancel,
		resume = task.spawn,
	},

	run = function(): boolean
		for _, thread in scheduler.threads do
			if coroutine.status(thread) == "dead" then
				scheduler.removeThread(thread)
				continue
			end

			local args: { unknown }?

			if scheduler.args[thread] then
				scheduler.args[thread] = nil
				args = scheduler.args[thread]
			end

			scheduler.runThread(thread, args)
		end

		for thread, result in scheduler.results do
			if result.success == false then
				print(result.msg)
			end
		end

		return #scheduler.threads > 0
	end,
}
