--!strict
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

function task.spawn(f: thread | (...unknown) -> ...unknown, ...: unknown): thread
	local thread = if typeof(f) == "thread" then f else coroutine.create(f)

	table.insert(scheduler.threads, thread)

	-- run immediately
	local result = scheduler.runThread(thread, ...)

	if result then
		scheduler.results[thread] = result
	end

	return thread
end

function task.defer(f: thread | (...unknown) -> ...unknown, ...: unknown): thread
	local thread = if typeof(f) == "thread" then f else coroutine.create(f)

	table.insert(scheduler.threads, thread)
	scheduler.args[thread] = { ... }

	return thread
end

return {
	task = task,
	coroutine = {},

	run = function(): boolean
		for thread, result in scheduler.results do
			local index = table.find(scheduler.threads, thread)

			if index then
				table.remove(scheduler.threads, index)

				if result.success == false then
					print(result.msg)
				end
			end
		end

		for _, thread in scheduler.threads do
			local args: { unknown }?

			if scheduler.args[thread] then
				scheduler.args[thread] = nil
				args = scheduler.args[thread]
			end

			local result = scheduler.runThread(thread, args)

			if result then
				scheduler.results[thread] = result
			end
		end

		return #scheduler.threads > 0
	end,
}
