--!strict
local task = {}

function task.spawn(f: thread | (...unknown) -> ...unknown): thread
	local thread = if typeof(f) == "thread" then f else coroutine.create(f)

	return thread
end

return {
	task = task,
	coroutine = {},

	run = function(): boolean
		return true
	end,
}
