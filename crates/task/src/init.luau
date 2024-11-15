--!strict
local scheduler = {
	spawnedThreads = {},
	deferredThreads = {},
	results = {} :: { [thread]: ThreadResult },
}

type ThreadResult = {
	success: true,
	value: unknown,
} | {
	success: false,
	msg: string,
}

function scheduler.runThread(thread: thread, ...: unknown): ThreadResult?
	local success, result = coroutine.resume(thread, ...)

	if success == true and coroutine.status(thread) == "dead" then
		return {
			success = true,
			value = result,
		}
	elseif success == false then
		return {
			success = false,
			msg = result,
		}
	else
		return nil
	end
end

local task = {}

function task.spawn(f: thread | (...unknown) -> ...unknown): thread
	local thread = if typeof(f) == "thread" then f else coroutine.create(f)

	table.insert(scheduler.spawnedThreads, thread)

	-- run immediately
	local result = scheduler.runThread(thread)

	if result then
		scheduler.results[thread] = result
	end

	return thread
end

return {
	task = task,
	coroutine = {},

	run = function(): boolean
		return false
	end,
}
