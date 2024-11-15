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

function scheduler.runThread(thread: thread, ...: unknown): ()
	if coroutine.status(thread) == "dead" then
		local index = table.find(scheduler.threads, thread)

		if index then
			table.remove(scheduler.threads, index)
		end

		return
	end

	local success, result = coroutine.resume(thread, ...)

	if coroutine.status(thread) ~= "dead" then
		return
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

			scheduler.runThread(thread, args)
		end

		return #scheduler.threads > 0
	end,
}
